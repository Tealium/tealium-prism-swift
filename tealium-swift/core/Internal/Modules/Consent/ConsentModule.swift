//
//  ConsentModule.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 20/10/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol CMPIntegration {
    var consentDecision: ObservableState<ConsentDecision?> { get }
    func allPurposes() -> [String] // TODO: why it's not a computable getter?
}

protocol ConsentManager: TealiumModule {
    func applyConsent(to dispatch: TealiumDispatch, completion onTrackResult: TrackResultCompletion?)
    func tealiumConsented(forPurposes purposes: [String]) -> Bool
    func getConsentDecision() -> ConsentDecision?
}

class ConsentModule: ConsentManager {
    static let id: String = "Consent"
    private let processedPurposesKey = "purposes_with_consent_processed"
    private let unprocessedPurposesKey = "purposes_with_consent_unprocessed"
    private let allPurposesKey = "purposes_with_consent_all"
    private let queueManager: QueueManagerProtocol
    private let settings: StateSubject<ConsentSettings>
    private let cmpIntegration: CMPIntegration
    private weak var modules: ObservableState<[TealiumModule]>?
    private var dispatchers: [String] {
        modules?.value
            .filter { $0 is Dispatcher }
            .map { $0.id } ?? []
    }
    private var refireDispatchers: [String] { // From settings
        return dispatchers.filter {
            settings.value.shouldRefireDispatchers.contains($0)
        }
    }
    let consentTransformer: ConsentTransformer
    let consentTransformation: ScopedTransformation
    private let automaticDisposer = AutomaticDisposer()
    private let transformerRegistry: TransformerRegistry

    required convenience init?(context: TealiumContext, cmpIntegration: CMPIntegration, queueManager: QueueManagerProtocol, moduleSettings: [String: Any]) {
        let settings = ConsentSettings(moduleSettings: moduleSettings)
        guard let modules = context.modulesManager?.modules else {
            return nil
        }
        self.init(queueManager: queueManager,
                  modules: modules,
                  transformerRegistry: context.transformerRegistry,
                  cmpIntegration: cmpIntegration,
                  consentSettings: StateSubject(settings))
    }

    init(queueManager: QueueManagerProtocol,
         modules: ObservableState<[TealiumModule]>,
         transformerRegistry: TransformerRegistry,
         cmpIntegration: CMPIntegration,
         consentSettings: StateSubject<ConsentSettings>) {
        self.queueManager = queueManager
        self.cmpIntegration = cmpIntegration
        self.modules = modules
        consentTransformer = ConsentTransformer(consentSettings: consentSettings.toStatefulObservable())
        consentTransformation = ScopedTransformation(id: "verify_consent",
                                                     transformerId: consentTransformer.id,
                                                     scopes: [TransformationScope.allDispatchers])
        settings = consentSettings
        self.transformerRegistry = transformerRegistry
        transformerRegistry.registerTransformer(consentTransformer)
        transformerRegistry.registerTransformation(consentTransformation)
        cmpIntegration.consentDecision.asObservable().compactMap { $0 }.subscribe { [weak self] (consentDecision: ConsentDecision) in
            guard let self = self else {
                return
            }
            guard self.tealiumConsented(forPurposes: consentDecision.purposes) else {
                if consentDecision.decisionType == .explicit {
                    queueManager.deleteAllDispatches(for: Self.id)
                }
                return
            }
            let events = queueManager.getQueuedDispatches(for: Self.id, limit: nil)
            self.enqueueDispatches(events.compactMap { self.applyDecision(consentDecision, toDispatch: $0) })
            queueManager.deleteAllDispatches(for: Self.id)
        }.addTo(automaticDisposer)
    }

    func updateSettings(_ settings: [String: Any]) -> Self? {
        self.settings.value = ConsentSettings(moduleSettings: settings)
        return self
    }

    func enqueueDispatches(_ dispatches: [TealiumDispatch]) {
        let refireKey = "refire"
        let normalDispatchKey = "normal"
        let dispatchesGroups = Dictionary(grouping: dispatches) { dispatch in
            if let processedPurposes = dispatch.eventData[processedPurposesKey] as? [String],
               !processedPurposes.isEmpty {
                return refireKey
            } else {
                return normalDispatchKey
            }
        }
        if !refireDispatchers.isEmpty,
           let refireDispatches = dispatchesGroups[refireKey]?.map({ TealiumDispatch(eventData: $0.eventData,
                                                                                     id: $0.id + "-refire",
                                                                                     timestamp: Date().unixTimeMillisecondsInt) }),
           !refireDispatches.isEmpty {
                queueManager.storeDispatches(refireDispatches, enqueueingFor: refireDispatchers)
        }
        if let normalDispatches = dispatchesGroups[normalDispatchKey], !normalDispatches.isEmpty {
            self.queueManager.storeDispatches(normalDispatches, enqueueingFor: dispatchers)
        }
    }

    func consentDecisionAllowsForRefire(_ consentDecision: ConsentDecision, allPurposes: [String]) -> Bool {
        consentDecision.decisionType == .implicit && consentDecision.matchAll(allPurposes) && !refireDispatchers.isEmpty
    }

    func tealiumConsented(forPurposes purposes: [String]) -> Bool {
        purposes.contains("tealium") // "tealium" will be configured
    }

    func getConsentDecision() -> ConsentDecision? {
        cmpIntegration.consentDecision.value
    }

    func applyConsent(to dispatch: TealiumDispatch, completion onTrackResult: TrackResultCompletion?) {
        guard let decision = cmpIntegration.consentDecision.value,
              tealiumConsented(forPurposes: decision.purposes) else {
            if cmpIntegration.consentDecision.value?.decisionType != .explicit {
                queueManager.storeDispatches([dispatch], enqueueingFor: [Self.id])
                onTrackResult?(dispatch, .accepted)
            } else {
                onTrackResult?(dispatch, .dropped)
            }
            return
        }
        guard let consentedDispatch = applyDecision(decision, toDispatch: dispatch) else {
            // No dispatch due to no unprocessed purposes present, ignore dispatch
            onTrackResult?(dispatch, .dropped)
            return
        }
        var processors = dispatchers
        if consentDecisionAllowsForRefire(decision, allPurposes: cmpIntegration.allPurposes()) {
            processors += [Self.id]
        }
        queueManager.storeDispatches([consentedDispatch], enqueueingFor: processors)
        onTrackResult?(consentedDispatch, .accepted)
    }

    func applyDecision(_ decision: ConsentDecision, toDispatch dispatch: TealiumDispatch) -> TealiumDispatch? {
        let preProcessedPurposes = dispatch.eventData[allPurposesKey] as? [String] ?? []

        var dispatch = dispatch
        let purposes = decision.purposes
        let unprocessedPurposes = purposes.filter { !preProcessedPurposes.contains($0) }
        guard !unprocessedPurposes.isEmpty else { return nil }
        dispatch.enrich(data: [
            unprocessedPurposesKey: unprocessedPurposes.toDataInput(),
            processedPurposesKey: preProcessedPurposes.toDataInput(),
            allPurposesKey: purposes.toDataInput(),
            "consent_type": decision.decisionType.rawValue,
        ])
        return dispatch
    }

    func unregisterTransformer() {
        transformerRegistry.unregisterTransformer(consentTransformer)
        transformerRegistry.unregisterTransformation(consentTransformation)
    }

    func shutdown() {
        unregisterTransformer()
    }

    deinit {
        shutdown()
    }
}
