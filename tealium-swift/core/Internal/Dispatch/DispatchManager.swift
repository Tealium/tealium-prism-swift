//
//  DispatchManager.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/10/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

protocol DispatchManagerProtocol {
    func track(_ dispatch: Dispatch, onTrackResult: TrackResultCompletion?)
}

extension DispatchManagerProtocol {
    func track(_ dispatch: Dispatch) {
        track(dispatch, onTrackResult: nil)
    }
}

/**
 * A split from an array of `Dispatch`es between `successful` and `unsuccessful` ones after evaluating
 * a condition on them or trying to apply some operation.
 */
typealias DispatchSplit = (successful: [Dispatch], unsuccessful: [Dispatch])

/**
 * The class containing the core logic of the library, taking `Dispatch`es from the queue, transforming and dispatching them to each individual `Dispatcher` when they are ready.
 */
class DispatchManager: DispatchManagerProtocol {
    static let MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER = 50
    private let barrierCoordinator: BarrierCoordinator
    private let transformerCoordinator: TransformerCoordinator

    private var dispatchers: [Dispatcher] {
        modulesManager?.modules.value.compactMap { $0 as? Dispatcher } ?? []
    }
    private var onDispatchers: Observable<[Dispatcher]> {
        modulesManager?.modules.map { moduleList in moduleList.compactMap { $0 as? Dispatcher } } ?? .Just([])
    }
    private weak var modulesManager: ModulesManager?
    private let queueManager: QueueManagerProtocol
    private let consentManager: ConsentManager?
    private let logger: LoggerProtocol?
    @ToAnyObservable<BasePublisher<Void>>(BasePublisher<Void>())
    private var onQueuedEvents: Observable<Void>
    private let loadRuleEngine: LoadRuleEngine
    private let mappingsEngine: MappingsEngine
    init(loadRuleEngine: LoadRuleEngine,
         modulesManager: ModulesManager,
         consentManager: ConsentManager?,
         queueManager: QueueManagerProtocol,
         barrierCoordinator: BarrierCoordinator,
         transformerCoordinator: TransformerCoordinator,
         mappingsEngine: MappingsEngine,
         logger: LoggerProtocol?) {
        self.loadRuleEngine = loadRuleEngine
        self.modulesManager = modulesManager
        self.consentManager = consentManager
        self.queueManager = queueManager
        self.barrierCoordinator = barrierCoordinator
        self.transformerCoordinator = transformerCoordinator
        self.mappingsEngine = mappingsEngine
        self.logger = logger
        startDispatchLoop()
    }

    func tealiumPurposeExplicitlyBlocked() -> Bool {
        guard let consentManager = consentManager else {
            return false
        }
        return consentManager.tealiumPurposeExplicitlyBlocked
    }

    func track(_ dispatch: Dispatch, onTrackResult: TrackResultCompletion?) {
        guard !tealiumPurposeExplicitlyBlocked() else {
            logger?.debug(category: LogCategory.dispatchManager,
                          "Tealium consent purpose is explicitly blocked. Event \(dispatch.logDescription()) will be dropped.")
            onTrackResult?(.dropped(dispatch))
            return
        }
        transformerCoordinator.transform(dispatch: dispatch, for: .afterCollectors) { [weak self] transformed in
            guard let self, let transformed else {
                self?.logger?.debug(category: LogCategory.dispatchManager,
                                    "Event \(dispatch.logDescription()) dropped due to transformer")
                onTrackResult?(.dropped(dispatch))
                return
            }
            if let consentManager = self.consentManager {
                self.logger?.debug(category: LogCategory.dispatchManager,
                                   "Event \(transformed.logDescription()) consent applied")
                let result = consentManager.applyConsent(to: transformed)
                onTrackResult?(result)
            } else {
                self.logger?.debug(category: LogCategory.dispatchManager,
                                   "Event \(transformed.logDescription()) accepted for processing")
                self.queueManager.storeDispatches([transformed], enqueueingFor: dispatchers.map { $0.id })
                onTrackResult?(.accepted(transformed))
            }
        }
    }

    private var managerContainer = AutomaticDisposer()

    func stopDispatchLoop() {
        managerContainer = AutomaticDisposer()
    }

    func startDispatchLoop() {
        onDispatchers.flatMapLatest { dispatchers in
            Observable.From(dispatchers)
        }.flatMap { [weak self, coordinator = barrierCoordinator] dispatcher in
            coordinator.onBarrierState(for: dispatcher.id)
                .flatMapLatest { [weak self] barriersState -> Observable<DispatchSplit> in
                    guard let self else { return .Empty() }
                    self.logger?.debug(category: LogCategory.dispatchManager,
                                       "BarrierState changed for \(dispatcher.id): \(barriersState)")
                    if barriersState == .open {
                        return self.startConsentedDequeueLoop(for: dispatcher)
                    } else {
                        return .Empty()
                    }
                }.flatMap { [weak self] dispatchSplit -> Observable<(Dispatcher, [Dispatch])> in
                    Observable.Callback { [weak self] observer in
                        let subscription = Subscription { }
                        guard let self = self else {
                            return subscription
                        }
                        self.logger?.debug(category: LogCategory.dispatchManager,
                                           "Sending events to dispatcher \(dispatcher.id): \(dispatchSplit.successful.shortDescription())")
                        return self.transformAndDispatch(dispatchSplit: dispatchSplit, for: dispatcher) { processedDispatches in
                            guard !subscription.isDisposed else { return }
                            observer((dispatcher, processedDispatches))
                        }
                    }
                }
        }
        .subscribe { [weak self] dispatcher, processedDispatches in
            self?.queueManager.deleteDispatches(processedDispatches.map { $0.id }, for: dispatcher.id)
            self?.logger?.debug(category: LogCategory.dispatchManager,
                                "Dispatcher: \(dispatcher.id) processed events: \(processedDispatches.shortDescription())")
        }.addTo(self.managerContainer)
    }

    private func startConsentedDequeueLoop(for dispatcher: Dispatcher) -> Observable<DispatchSplit> {
        if let consentManager {
            consentManager.onConfigurationSelected
                .flatMapLatest { [weak self] configuration in
                    guard let self, let configuration else { return .Empty() }
                    // Only dequeue events after we have a valid configuration from `ConsentManager`
                    return self.startDequeueLoop(for: dispatcher)
                        .map { dispatches in
                            dispatches.partitioned {
                                $0.matchesConfiguration(configuration, forDispatcher: dispatcher.id)
                            }
                        }
                }
        } else {
            startDequeueLoop(for: dispatcher)
                .map { DispatchSplit(successful: $0, unsuccessful: []) }
        }
    }

    private func startDequeueLoop(for dispatcher: Dispatcher) -> Observable<[Dispatch]> {
        let onInflightLower = queueManager.onInflightDispatchesCount(for: dispatcher.id)
            .map { $0 < Self.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER }
            .distinct()
        let queueManager = self.queueManager
        return queueManager.onEnqueuedDispatchesForProcessors
            .filter { processors in processors.contains { $0 == dispatcher.id } }
            .startWith([])
            .flatMapLatest { _ in
                onInflightLower
                    .filter { $0 }
                    .map { _ in queueManager.getQueuedDispatches(for: dispatcher.id,
                                                                 limit: min(dispatcher.dispatchLimit, Self.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER))
                    }
                    .filter { !$0.isEmpty }
                    .resubscribingWhile { $0.count >= dispatcher.dispatchLimit } // Loops the `getQueuedDispatches` as long as we pull `dispatchLimit` items from the queue
            }
    }

    private func transformAndDispatch(dispatchSplit: DispatchSplit, for dispatcher: Dispatcher, onProcessedDispatches: @escaping ([Dispatch]) -> Void) -> Disposable {
        if !dispatchSplit.unsuccessful.isEmpty {
            // Discarded dispatches don't need to be transformed and can be deleted immediately.
            onProcessedDispatches(dispatchSplit.unsuccessful)
        }
        let dispatches = dispatchSplit.successful
        let container = DisposeContainer()
        guard !dispatches.isEmpty else {
            return container
        }
        self.transformerCoordinator.transform(dispatches: dispatches,
                                              for: .dispatcher(dispatcher.id)) { [weak self] transformedDispatches in
            guard !container.isDisposed, let self else { return }
            let (passed, _) = self.loadRuleEngine.evaluateLoadRules(on: transformedDispatches,
                                                                    forModule: dispatcher)
            let removedDispatches = dispatches.diff(passed, by: \.id)
            if !removedDispatches.isEmpty {
                self.logger?.debug(category: LogCategory.dispatchManager,
                                   "Dispatching disallowed for Dispatcher \(dispatcher.id) and Dispatches \(removedDispatches.shortDescription())")
                onProcessedDispatches(removedDispatches)
            }

            let mapped = passed.map {
                self.mappingsEngine.map(dispatcherId: dispatcher.id, dispatch: $0)
            }
            dispatcher.dispatch(mapped) { processedDispatches in
                guard !container.isDisposed else { return }
                onProcessedDispatches(processedDispatches)
            }.addTo(container)
        }
        return container
    }
}

private extension Array where Element == Dispatch {
    func shortDescription() -> String {
        "\(map { $0.logDescription() })"
    }
}
