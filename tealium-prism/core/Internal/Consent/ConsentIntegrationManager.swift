//
//  ConsentIntegrationManager.swift
//  tealium-prism
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
                      queue: TealiumQueue,
                      cmpAdapter: CMPAdapter?,
                      logger: TealiumLogger?) {
        guard let cmpAdapter else { return nil }
        let cmpSelector = CMPConfigurationSelector(consentSettings: consentSettings,
                                                   cmpAdapter: cmpAdapter,
                                                   queue: queue)
        self.init(queueManager: queueManager,
                  modules: modules,
                  consentSettings: consentSettings,
                  cmpSelector: cmpSelector,
                  logger: logger)
    }

    /**
     * Consent integration is not part of the public API in the GA release, so no `CMPAdapter`
     * can be configured. If local or remote settings still carry a `consent` section, log once and ignore it.
     */
    static func logIgnoredConsentSettings(_ consentSettings: ObservableState<ConsentSettings?>,
                                          logger: TealiumLogger?) -> any Disposable {
        consentSettings
            .compactMap { $0 }
            .first()
            .subscribe { _ in
                logger?.info(category: LogCategory.consent,
                             "Consent settings found, but consent integration is not available in this release. The consent section is ignored.")
            }
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
        guard let logger else { return }
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
            tryStore(updatedDispatches, enqueueingFor: refireDispatchers)
        }
        if !normalDispatches.isEmpty {
            self.logger?.trace(category: LogCategory.consent,
                               "Dispatches enqueued for all dispatchers \(normalDispatches.shortDescription())")
            tryStore(normalDispatches, enqueueingFor: dispatchers.value)
        }
    }

    func applyConsent(to dispatch: Dispatch) -> TrackResult {
        guard let consentInspector = cmpSelector.consentInspector.value else {
            return store(dispatch, enqueueingFor: [Self.id],
                         info: "Missing ConsentConfiguration or ConsentDecision, enqueued for Consent.")
        }
        guard !consentInspector.tealiumExplicitlyBlocked() else {
            return .dropped(dispatch, reason: "Tealium explicitly blocked.")
        }
        let decision = consentInspector.decision
        guard consentInspector.tealiumConsented() else {
            return store(dispatch, enqueueingFor: [Self.id],
                         info: "Tealium implicitly not consented, enqueued for Consent.")
        }
        guard let consentedDispatch = dispatch.applyConsentDecision(decision) else {
            return .dropped(dispatch, reason: "No unprocessed purposes present.")
        }
        var processors = dispatchers.value
        if consentInspector.allowsRefire() {
            processors += [Self.id]
        }
        return store(consentedDispatch, enqueueingFor: processors,
                     info: "Enqueued for processors: \(processors)")
    }

    /// Stores the `dispatch` for the `processors` and reports the outcome to the track caller.
    ///
    /// - Returns: `.dropped` when the queue manager throws, `.accepted` with `info` otherwise.
    private func store(_ dispatch: Dispatch, enqueueingFor processors: [String], info: String) -> TrackResult {
        guard tryStore([dispatch], enqueueingFor: processors) else {
            return .dropped(dispatch, reason: "Failed to persist dispatch to the queue.")
        }
        return .accepted(dispatch, info: info)
    }

    /// Stores the `dispatches` for the `processors` and returns `false` when the queue manager threw.
    ///
    /// The failure is logged here, once, because the replay sites have no track listener to inform and
    /// `handleConsentInspectorChange` deletes the consent queue regardless, so a failed re-store can only be logged.
    @discardableResult
    private func tryStore(_ dispatches: [Dispatch], enqueueingFor processors: [String]) -> Bool {
        do {
            try queueManager.storeDispatches(dispatches, enqueueingFor: processors)
            return true
        } catch {
            logger?.error(category: LogCategory.consent,
                          "Failed to persist consent dispatches for processors \(processors): \(dispatches.map { $0.logDescription() })\nError: \(error)")
            return false
        }
    }
}
