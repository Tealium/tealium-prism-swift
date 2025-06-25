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
        cmpSelector.consentInspector.value?.tealiumExplicitlyBlocked() ?? false
    }

    let onConfigurationSelected: Observable<ConsentConfiguration?>

    convenience init?(queueManager: QueueManagerProtocol,
                      modules: ObservableState<[TealiumModule]>,
                      consentSettings: ObservableState<ConsentSettings?>,
                      cmpAdapter: CMPAdapter?) {
        guard let cmpAdapter else { return nil }
        let cmpSelector = CMPConfigurationSelector(consentSettings: consentSettings,
                                                   cmpAdapter: cmpAdapter)
        self.init(queueManager: queueManager,
                  modules: modules,
                  consentSettings: consentSettings,
                  cmpSelector: cmpSelector)
    }

    init(queueManager: QueueManagerProtocol,
         modules: ObservableState<[TealiumModule]>,
         consentSettings: ObservableState<ConsentSettings?>,
         cmpSelector: CMPConfigurationSelector) {
        self.queueManager = queueManager
        self.modules = modules
        self.cmpSelector = cmpSelector
        onConfigurationSelected = cmpSelector.configuration.asObservable()
        handleConsentChanges()
    }

    func handleConsentChanges() {
        cmpSelector.consentInspector
            .compactMap { $0 }
            .subscribe { [weak self] (consentInspector: ConsentInspector) in
                guard let self else { return }

                defer { queueManager.deleteAllDispatches(for: Self.id) }
                guard !consentInspector.tealiumExplicitlyBlocked() else {
                    return
                }
                let events = queueManager.getQueuedDispatches(for: Self.id, limit: nil)
                    .compactMap { $0.applyConsentDecision(consentInspector.decision) }

                guard !events.isEmpty else { return }

                self.enqueueDispatches(events, refireDispatchers: consentInspector.configuration.refireDispatchersIds)
            }.addTo(automaticDisposer)
    }

    func enqueueDispatches(_ dispatches: [Dispatch], refireDispatchers: [String]) {
        let (refireDispatches, normalDispatches) = dispatches.partitioned {
            $0.hasAlreadyProcessedPurposes()
        }
        if !refireDispatchers.isEmpty,
           !refireDispatches.isEmpty {
            let updatedDispatches = refireDispatches.map {
                Dispatch(payload: $0.payload,
                         id: $0.id + ConsentConstants.refireIdPostfix,
                         timestamp: Date().unixTimeMillisecondsInt)
            }
            queueManager.storeDispatches(updatedDispatches, enqueueingFor: refireDispatchers)
        }
        if !normalDispatches.isEmpty {
            self.queueManager.storeDispatches(normalDispatches, enqueueingFor: dispatchers)
        }
    }

    func applyConsent(to dispatch: Dispatch) -> TrackResult {
        guard let consentInspector = cmpSelector.consentInspector.value else {
            queueManager.storeDispatches([dispatch], enqueueingFor: [Self.id])
            return .accepted(dispatch)
        }
        guard !consentInspector.tealiumExplicitlyBlocked() else {
            return .dropped(dispatch)
        }
        let decision = consentInspector.decision
        guard consentInspector.tealiumConsented() else {
            queueManager.storeDispatches([dispatch], enqueueingFor: [Self.id])
            return .accepted(dispatch)
        }
        guard let consentedDispatch = dispatch.applyConsentDecision(decision) else {
            // No dispatch due to no unprocessed purposes present, ignore dispatch
            return .dropped(dispatch)
        }
        var processors = dispatchers
        if consentInspector.allowsRefire() {
            processors += [Self.id]
        }
        queueManager.storeDispatches([consentedDispatch], enqueueingFor: processors)
        return .accepted(consentedDispatch)
    }
}
