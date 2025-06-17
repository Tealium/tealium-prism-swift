//
//  ConsentIntegrationManager.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 20/10/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

protocol ConsentManager {
    var tealiumPurposeExplicitlyBlocked: Bool { get }
    var onConfigurationSelected: Observable<ConsentConfiguration?> { get }
    func applyConsent(to dispatch: Dispatch) -> TrackResult
}

enum ConsentConstants {
    static let processedPurposesKey = "purposes_with_consent_processed"
    static let unprocessedPurposesKey = "purposes_with_consent_unprocessed"
    static let allPurposesKey = "purposes_with_consent_all"
    static let consentTypeKey = "consent_type"
    static let refireIdPostfix = "-refire"
}

class ConsentIntegrationManager: ConsentManager {
    let version: String = TealiumConstants.libraryVersion
    static let id: String = "consent"
    private let queueManager: QueueManagerProtocol
    let cmpSelector: CMPConfigurationSelector
    private weak var modules: ObservableState<[TealiumModule]>?
    private var dispatchers: [String] {
        modules?.value
            .filter { $0 is Dispatcher }
            .map { $0.id } ?? []
    }
    private let automaticDisposer = AutomaticDisposer()
    var tealiumPurposeExplicitlyBlocked: Bool {
        if let applier = cmpSelector.consentInspector.value {
            return applier.tealiumExplicitlyBlocked()
        }
        return false
    }

    let onConfigurationSelected: Observable<ConsentConfiguration?>

    convenience init?(queueManager: QueueManagerProtocol,
                      modules: ObservableState<[TealiumModule]>,
                      consentSettings: ObservableState<ConsentSettings?>,
                      cmpAdapter: CMPAdapter?) {
        guard let cmpAdapter else { return nil }
        self.init(queueManager: queueManager,
                  modules: modules,
                  consentSettings: consentSettings,
                  cmpAdapter: cmpAdapter)
    }

    init(queueManager: QueueManagerProtocol,
         modules: ObservableState<[TealiumModule]>,
         consentSettings: ObservableState<ConsentSettings?>,
         cmpAdapter: CMPAdapter) {
        self.queueManager = queueManager
        self.modules = modules
        self.cmpSelector = CMPConfigurationSelector(consentSettings: consentSettings,
                                                    cmpAdapter: cmpAdapter)
        onConfigurationSelected = cmpSelector.configuration.asObservable()
        handleConsentChanges()
    }

    func handleConsentChanges() {
        cmpSelector.consentInspector
            .compactMap { $0 }
            .subscribe { [weak self] (consentApplier: ConsentInspector) in
                guard let self else { return }

                defer { queueManager.deleteAllDispatches(for: Self.id) }
                guard !consentApplier.tealiumExplicitlyBlocked() else {
                    return
                }
                let events = queueManager.getQueuedDispatches(for: Self.id, limit: nil)
                    .compactMap { $0.applyConsentDecision(consentApplier.decision) }

                guard !events.isEmpty else { return }

                self.enqueueDispatches(events, refireDispatchers: consentApplier.configuration.refireDispatchersIds)
            }.addTo(automaticDisposer)
    }

    func enqueueDispatches(_ dispatches: [Dispatch], refireDispatchers: [String]) {
        let refireKey = "refire"
        let normalDispatchKey = "normal"
        let dispatchesGroups = Dictionary(grouping: dispatches) { dispatch in
            if let processedPurposes = dispatch.payload.getArray(key: ConsentConstants.processedPurposesKey, of: String.self)?.compactMap({ $0 }),
               !processedPurposes.isEmpty {
                return refireKey
            } else {
                return normalDispatchKey
            }
        }
        if !refireDispatchers.isEmpty,
           let refireDispatches = dispatchesGroups[refireKey]?.map({ Dispatch(payload: $0.payload,
                                                                              id: $0.id + ConsentConstants.refireIdPostfix,
                                                                              timestamp: Date().unixTimeMillisecondsInt) }),
           !refireDispatches.isEmpty {
                queueManager.storeDispatches(refireDispatches, enqueueingFor: refireDispatchers)
        }
        if let normalDispatches = dispatchesGroups[normalDispatchKey], !normalDispatches.isEmpty {
            self.queueManager.storeDispatches(normalDispatches, enqueueingFor: dispatchers)
        }
    }

    func applyConsent(to dispatch: Dispatch) -> TrackResult {
        guard let consentApplier = cmpSelector.consentInspector.value else {
            queueManager.storeDispatches([dispatch], enqueueingFor: [Self.id])
            return .accepted(dispatch)
        }
        guard !consentApplier.tealiumExplicitlyBlocked() else {
            return .dropped(dispatch)
        }
        let decision = consentApplier.decision
        guard consentApplier.tealiumConsented() else {
            queueManager.storeDispatches([dispatch], enqueueingFor: [Self.id])
            return .accepted(dispatch)
        }
        guard let consentedDispatch = dispatch.applyConsentDecision(decision) else {
            // No dispatch due to no unprocessed purposes present, ignore dispatch
            return .dropped(dispatch)
        }
        var processors = dispatchers
        if consentApplier.allowsRefire() {
            processors += [Self.id]
        }
        queueManager.storeDispatches([consentedDispatch], enqueueingFor: processors)
        return .accepted(consentedDispatch)
    }
}
