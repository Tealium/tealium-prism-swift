//
//  ConsentManager.swift
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
    var settings: TealiumObservableState<ConsentSettings>
    private let automaticDisposer = TealiumAutomaticDisposer()
    init(consentSettings: TealiumObservableState<ConsentSettings>) {
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
    var consentDecision: TealiumObservableState<ConsentDecision?> { get }
    func allPurposes() -> [String]?
}

class ConsentQueue {
    private var queue: [TealiumDispatch] = []

    func enqueue(_ dispatch: TealiumDispatch) {
        queue.append(dispatch)
    }

    func dequeueAll() -> [TealiumDispatch] {
        defer { deleteAll() }
        return queue
    }

    func deleteAll() {
        queue.removeAll()
    }
}

protocol ConsentManagerProtocol {
    var enabled: Bool { get }
    func applyConsent(to dispatch: TealiumDispatch)
    func tealiumConsented(forPurposes purposes: [String]) -> Bool
    func allPurposesMatch(consentDecision: ConsentDecision) -> Bool
    func getConsentDecision() -> ConsentDecision?
}

class ConsentManager: ConsentManagerProtocol {
    var enabled: Bool = false // From settings
    let processedPurposesKey = "purposes_with_consent_processed"
    let unprocessedPurposesKey = "purposes_with_consent_unprocessed"
    let queueManager: QueueManager
    let consentQueue: ConsentQueue
    let settings: TealiumObservableState<ConsentSettings>
    var cmpIntegration: CMPIntegration? // From config
    var refireDispatchers: [String] { // From settings
        settings.value.shouldRefireDispatchers
    }
    let consentTransformer: ConsentTransformer
    private let automaticDisposer = TealiumAutomaticDisposer()
    init(queueManager: QueueManager, consentQueue: ConsentQueue, cmpIntegration: CMPIntegration?, consentSettings: TealiumObservableState<ConsentSettings>) {
        self.queueManager = queueManager
        self.consentQueue = consentQueue
        self.cmpIntegration = cmpIntegration
        consentTransformer = ConsentTransformer(consentSettings: consentSettings)
        settings = consentSettings
        cmpIntegration?.consentDecision.asObservable().compactMap { $0 }.subscribe { [weak self] consentDecision in
            guard let self = self,
                  self.tealiumConsented(forPurposes: consentDecision.purposes) else {
                if consentDecision.decisionType == .explicit {
                    consentQueue.deleteAll()
                }
                return
            }
            let events = consentQueue.dequeueAll()
            self.enqueueDispatches(events.compactMap { self.applyDecision(consentDecision, toDispatch: $0) })
        }.addTo(automaticDisposer)
    }

    func enqueueDispatches(_ dispatches: [TealiumDispatch]) {
        for dispatch in dispatches {
            if dispatch.eventData.contains(where: { $0.key == "purposes_with_consent_processed" }) {
                guard !refireDispatchers.isEmpty else {
                    continue
                }
                self.queueManager.storeDispatch(dispatch, for: refireDispatchers)
            } else {
                self.queueManager.storeDispatch(dispatch, for: nil)
            }
        }
    }

    func consentDecisionAllowsForRefire(_ consentDecision: ConsentDecision) -> Bool {
        consentDecision.decisionType == .implicit && !allPurposesMatch(consentDecision: consentDecision) && !refireDispatchers.isEmpty
    }
    func allPurposesMatch(consentDecision: ConsentDecision) -> Bool {
        guard let allPurposes = cmpIntegration?.allPurposes() else {
            return false
        }
        return consentDecision.matchAll(allPurposes)
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
              tealiumConsented(forPurposes: decision.purposes),
              var consentedDispatch = applyDecision(decision, toDispatch: dispatch) else {
            consentQueue.enqueue(dispatch)
            return
        }
        queueManager.storeDispatch(consentedDispatch, for: nil)
        if consentDecisionAllowsForRefire(decision) {
            consentedDispatch.enrich(data: TealiumDictionaryInput(removingOptionals: [
                processedPurposesKey: consentedDispatch.eventData[unprocessedPurposesKey],
                unprocessedPurposesKey: [String]().toDataInput()
            ]))
            consentQueue.enqueue(consentedDispatch)
        }
    }

    func applyDecision(_ decision: ConsentDecision, toDispatch dispatch: TealiumDispatch) -> TealiumDispatch? {
        let preProcessedPurposes = dispatch.eventData[processedPurposesKey] as? [String] ?? []

        var dispatch = dispatch
        let purposes = decision.purposes
        let unprocessedPurposes = purposes.filter { !preProcessedPurposes.contains($0) }
        guard !unprocessedPurposes.isEmpty else { return nil }
        dispatch.enrich(data: [
            unprocessedPurposesKey: unprocessedPurposes.toDataInput(),
            processedPurposesKey: preProcessedPurposes.toDataInput(),
            "purposes_with_consent_all": purposes.toDataInput(),
            "consent_type": decision.decisionType.rawValue,
        ])
        return dispatch
    }
}
