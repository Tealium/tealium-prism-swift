//
//  ConsentIntegrationManager.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 20/10/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * This is the internal `ConsentManager` used by various internal components to determine the current
 * consent status of the current visitor.
 */
protocol ConsentManager {
    /**
     * The Tealium SDK can be explicitly consented to, or not.
     *
     * This method will return whether or not the Tealium purpose has been explicitly denied.
     */
    var tealiumPurposeExplicitlyBlocked: Bool { get }

    /**
     * An `Observable` of the selected `ConsentConfiguration`.
     */
    var onConfigurationSelected: Observable<ConsentConfiguration?> { get }

    /**
     * Adds consent context information to the given `Dispatch` and enqueues it.
     *
     * If the consent decision explicitly denies the tealium purpose or if no purpose is provided,
     * then the dispatch is dropped instead.
     *
     * If consent is not ready at this time, then the `Dispatch` will be queued in a consent specific queue.
     * It will later be dequeued, once consent has a `ConsentDecision` and a `ConsentConfiguration`,
     * and enqueued again for the `Dispatchers` with the additional consent context information.
     *
     * Additionally, the `Dispatch` can also be queued in the consent specific queue to be later re-fired.
     * Re-fired events are events that have previously been sent with some implicit purposes, but later,
     * when the user gives an explicit consent, can be sent again with the additional consented purposes.
     *
     * To enable re-firing, provide a non-empty list of `refireDispatchers` in the `ConsentConfiguration`.
     *
     * - parameter dispatch: The `Dispatch` to add consent data to.
     * - returns: A `TrackResult` that can be `accepted`, if the dispatch is enqueued in the consent
     * or dispatchers queue, or `dropped` if the dispatch is dropped.
     */
    func applyConsent(to dispatch: Dispatch) -> TrackResult
}

class ConsentIntegrationManager: ConsentManager {
    let version: String = TealiumConstants.libraryVersion
    static let id: String = "consent"
    private let queueManager: QueueManagerProtocol
    let cmpSelector: CMPConfigurationSelector
    let logger: TealiumLogger?
    private let dispatchers: ObservableState<[String]>
    private let automaticDisposer = AutomaticDisposer()
    var tealiumPurposeExplicitlyBlocked: Bool {
        cmpSelector.consentInspector.value?.tealiumExplicitlyBlocked() ?? false
    }

    let onConfigurationSelected: Observable<ConsentConfiguration?>

    convenience init?(queueManager: QueueManagerProtocol,
                      modules: ObservableState<[Module]>,
                      consentSettings: ObservableState<ConsentSettings?>,
                      cmpAdapter: CMPAdapter?,
                      logger: TealiumLogger?) {
        guard let cmpAdapter else { return nil }
        let cmpSelector = CMPConfigurationSelector(consentSettings: consentSettings,
                                                   cmpAdapter: cmpAdapter)
        self.init(queueManager: queueManager,
                  modules: modules,
                  consentSettings: consentSettings,
                  cmpSelector: cmpSelector,
                  logger: logger)
    }

    init(queueManager: QueueManagerProtocol,
         modules: ObservableState<[Module]>,
         consentSettings: ObservableState<ConsentSettings?>,
         cmpSelector: CMPConfigurationSelector,
         logger: TealiumLogger?) {
        self.queueManager = queueManager
        self.cmpSelector = cmpSelector
        self.logger = logger
        self.dispatchers = modules.mapState(transform: { modules in
            modules.filter { $0 is Dispatcher }
                .map { $0.id }
        })
        onConfigurationSelected = cmpSelector.configuration.asObservable()
        logConfigurationErrors()
        cmpSelector.consentInspector
            .compactMap { $0 }
            .subscribe { [weak self] consentInspector in
                self?.handleConsentInspectorChange(consentInspector)
            }.addTo(automaticDisposer)
    }

    private func logConfigurationErrors() {
        if let logger {
            onConfigurationSelected
                .compactMap { [cmpSelector] configuration in
                    if configuration == nil {
                        logger.warn(category: LogCategory.consent,
                                    """
                                    No ConsentConfiguration selected for CMP: \(cmpSelector.cmpAdapter.id).
                                    Make sure you provide a configuration for this specific CMP in the ConsentSettings.
                                    """)
                    }
                    return configuration
                }
                .combineLatest(dispatchers.asObservable())
                .map { configuration, dispatcherIds in
                    dispatcherIds.filter { dispatcherId in
                        !configuration.hasAtLeastOneRequiredPurposeForDispatcher(dispatcherId)
                    }
                }
                .filter { !$0.isEmpty }
                .distinct()
                .subscribe { misconfiguredDispatchers in
                    logger.error(category: LogCategory.consent,
                                 "No purpose defined in ConsentConfiguration for dispatchers: \(misconfiguredDispatchers).\nThese dispatchers will not fire!")
                }.addTo(automaticDisposer)
        }
    }

    func handleConsentInspectorChange(_ consentInspector: ConsentInspector) {
        defer { queueManager.deleteAllDispatches(for: Self.id) }
        guard !consentInspector.tealiumExplicitlyBlocked() else {
            return
        }
        let events = queueManager.dequeueDispatches(for: Self.id, limit: nil)
            .compactMap { $0.applyConsentDecision(consentInspector.decision) }

        guard !events.isEmpty else { return }
        logger?.debug(category: LogCategory.consent, "Dispatches enqueued for \(consentInspector.decision.decisionType) decision: \(events.shortDescription())")
        let refireDispatchers = consentInspector.configuration.refireDispatchersIds
        enqueueDispatches(events, refireDispatchers: refireDispatchers)
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
                         timestamp: Date().unixTimeMilliseconds)
            }
            self.logger?.trace(category: LogCategory.consent,
                               "Dispatches enqueued for refire dispatchers \(updatedDispatches.shortDescription())")
            queueManager.storeDispatches(updatedDispatches, enqueueingFor: refireDispatchers)
        }
        if !normalDispatches.isEmpty {
            self.logger?.trace(category: LogCategory.consent,
                               "Dispatches enqueued for all dispatchers \(normalDispatches.shortDescription())")
            self.queueManager.storeDispatches(normalDispatches, enqueueingFor: dispatchers.value)
        }
    }

    func applyConsent(to dispatch: Dispatch) -> TrackResult {
        guard let consentInspector = cmpSelector.consentInspector.value else {
            queueManager.storeDispatches([dispatch], enqueueingFor: [Self.id])
            let info = "Missing ConsentConfiguration or ConsentDecision, enqueued for Consent."
            return .accepted(dispatch, info: info)
        }
        guard !consentInspector.tealiumExplicitlyBlocked() else {
            return .dropped(dispatch, reason: "Tealium explicitly blocked.")
        }
        let decision = consentInspector.decision
        guard consentInspector.tealiumConsented() else {
            queueManager.storeDispatches([dispatch], enqueueingFor: [Self.id])
            let info = "Tealium implicitly not consented, enqueued for Consent."
            return .accepted(dispatch, info: info)
        }
        guard let consentedDispatch = dispatch.applyConsentDecision(decision) else {
            return .dropped(dispatch, reason: "No unprocessed purposes present.")
        }
        var processors = dispatchers.value
        if consentInspector.allowsRefire() {
            processors += [Self.id]
        }
        queueManager.storeDispatches([consentedDispatch], enqueueingFor: processors)
        return .accepted(consentedDispatch, info: "Enqueued for processors: \(processors)")
    }
}
