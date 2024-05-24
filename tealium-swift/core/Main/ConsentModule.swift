//
//  ConsentModule.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 20/10/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public struct ConsentDecision {
    public enum DecisionType: String {
        case implicit
        case explicit
    }
    public let decisionType: DecisionType
    public let purposes: [String]

    init(decisionType: DecisionType, purposes: [String]) {
        self.decisionType = decisionType
        self.purposes = purposes
    }

    func matchAll(_ requiredPurposes: [String]) -> Bool {
        requiredPurposes.allSatisfy(purposes.contains)
    }
}

struct ConsentSettings {
    let enabled: Bool
    let dispatcherToPurposes: [String: [String]]
    let shouldRefireDispatchers: [String]

    init(consentDictionary: [String: Any]) {
        self.init(enabled: consentDictionary["enabled"] as? Bool ?? false,
                  dispatcherToPurposes: consentDictionary["dispatcher_to_purposes"] as? [String: [String]] ?? [:],
                  shouldRefireDispatchers: consentDictionary["should_refire_dispatchers"] as? [String] ?? [])
    }

    init(enabled: Bool, dispatcherToPurposes: [String: [String]], shouldRefireDispatchers: [String]) {
        self.enabled = enabled
        self.dispatcherToPurposes = dispatcherToPurposes
        self.shouldRefireDispatchers = shouldRefireDispatchers
    }
}

class ConsentTransformer: Transformer {
    let id: String = "ConsentTransformer"
    var enabled: Bool {
        settings.value.enabled
    }
    var settings: TealiumStatefulObservable<ConsentSettings>
    private let automaticDisposer = TealiumAutomaticDisposer()
    init(consentSettings: TealiumStatefulObservable<ConsentSettings>) {
        self.settings = consentSettings
    }

    func applyTransformation(_ id: String, to dispatch: TealiumDispatch, scope: DispatchScope, completion: @escaping (TealiumDispatch?) -> Void) {
        guard enabled else {
            completion(dispatch)
            return
        }
        guard case let DispatchScope.dispatcher(dispatcherId) = scope,
              let requiredPurposes = settings.value.dispatcherToPurposes[dispatcherId],
              !requiredPurposes.isEmpty,
              self.dispatch(dispatch, matchesPurposes: requiredPurposes) else {
            completion(nil)
            return
        }
        completion(dispatch)
    }

    func dispatch(_ dispatch: TealiumDispatch, matchesPurposes requiredPurposes: [String]) -> Bool {
        guard let consentedPurposes = dispatch.eventData["purposes_with_consent_all"] as? [String] else {
            return false
        }
        return requiredPurposes.allSatisfy(consentedPurposes.contains)
    }
}

public protocol CMPIntegration {
    var consentDecision: TealiumStatefulObservable<ConsentDecision?> { get }
    func allPurposes() -> [String]
}

protocol ConsentManager: TealiumModule {
    func applyConsent(to dispatch: TealiumDispatch)
    func tealiumConsented(forPurposes purposes: [String]) -> Bool
    func getConsentDecision() -> ConsentDecision?
}

class ConsentModule: ConsentManager {

    static let id: String = "consent"
    let processedPurposesKey = "purposes_with_consent_processed"
    let unprocessedPurposesKey = "purposes_with_consent_unprocessed"
    let allPurposesKey = "purposes_with_consent_all"
    let queueManager: QueueManagerProtocol
    let settings: TealiumVariableSubject<ConsentSettings>
    var cmpIntegration: CMPIntegration? // From config
    let modules: TealiumStatefulObservable<[TealiumModule]>
    var dispatchers: [String] {
        modules.value
            .filter { $0 is Dispatcher }
            .map { $0.id }
    }
    var refireDispatchers: [String] { // From settings
        dispatchers.filter {
            settings.value.shouldRefireDispatchers.contains($0)
        }
    }
    let consentTransformer: ConsentTransformer
    let consentTransformation: ScopedTransformation
    private let automaticDisposer = TealiumAutomaticDisposer()
    private let transformerRegistry: TransformerRegistry

    required convenience init?(context: TealiumContext, moduleSettings: [String: Any]) {
        self.init(queueManager: context.queueManager,
                  modules: context.modulesManager.modules,
                  transformerRegistry: context.transformerRegistry,
                  cmpIntegration: nil,
                  consentSettings: TealiumVariableSubject(ConsentSettings(consentDictionary: moduleSettings)))
    }

    init(queueManager: QueueManagerProtocol,
         modules: TealiumStatefulObservable<[TealiumModule]>,
         transformerRegistry: TransformerRegistry,
         cmpIntegration: CMPIntegration?,
         consentSettings: TealiumVariableSubject<ConsentSettings>) {
        self.queueManager = queueManager
        self.cmpIntegration = cmpIntegration
        self.modules = modules
        consentTransformer = ConsentTransformer(consentSettings: consentSettings.toStatefulObservable())
        consentTransformation = ScopedTransformation(id: "verify_consent",
                                                     transformerId: consentTransformer.id,
                                                     scopes: [TransformationScope.allDispatchers])
        settings = consentSettings
        self.transformerRegistry = transformerRegistry
        transformerRegistry.registerTransfomer(consentTransformer)
        transformerRegistry.registerTransformation(consentTransformation)
        cmpIntegration?.consentDecision.asObservable().compactMap { $0 }.subscribe { [weak self] (consentDecision: ConsentDecision) in
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
        self.settings.value = ConsentSettings(consentDictionary: settings)
        if !self.settings.value.enabled {
            transformerRegistry.unregisterTransformer(consentTransformer)
            transformerRegistry.unregisterTransformation(consentTransformation)
            return nil
        }
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
        cmpIntegration?.consentDecision.value
    }

    func applyConsent(to dispatch: TealiumDispatch) {
        guard let integration = cmpIntegration else {
            // Nothing we can do, maybe Log an error
            // Maybe this condition can be avoided as we can force the integration to be provided in configuration when consent is enabled (?)
            return
        }

        guard let decision = integration.consentDecision.value,
              tealiumConsented(forPurposes: decision.purposes) else {
            if integration.consentDecision.value?.decisionType != .explicit {
                queueManager.storeDispatches([dispatch], enqueueingFor: [Self.id])
            }
            return
        }
        guard let consentedDispatch = applyDecision(decision, toDispatch: dispatch) else {
            // No dispatch due to no purposes provided, ignore dispatch
            return
        }
        var processors = dispatchers
        if consentDecisionAllowsForRefire(decision, allPurposes: integration.allPurposes()) {
            processors += [Self.id]
        }
        queueManager.storeDispatches([consentedDispatch], enqueueingFor: processors)
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
}
