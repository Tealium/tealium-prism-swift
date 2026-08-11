//
//  DispatchManager.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 24/10/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

protocol DispatchManagerProtocol {
    var tealiumPurposeExplicitlyBlocked: Bool { get }
    func track(_ dispatch: Dispatch, onTrackResult: TrackResultCompletion?)
    func stopDispatchLoop()
}

extension DispatchManagerProtocol {
    func track(_ dispatch: Dispatch) {
        track(dispatch, onTrackResult: nil)
    }
}

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
        modulesManager?.modules.map { moduleList in moduleList.compactMap { $0 as? Dispatcher } } ?? Observables.just([])
    }
    private weak var modulesManager: ModulesManager?
    private let queueManager: QueueManagerProtocol
    private let consentManager: ConsentManager?
    private let logger: LoggerProtocol?
    @Subject<Void> private var onQueuedEvents
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

    var tealiumPurposeExplicitlyBlocked: Bool {
        guard let consentManager = consentManager else {
            return false
        }
        return consentManager.tealiumPurposeExplicitlyBlocked
    }

    func track(_ dispatch: Dispatch, onTrackResult: TrackResultCompletion?) {
        let onTrackResult: TrackResultCompletion = { [logger] result in
            logger?.debug(category: LogCategory.dispatchManager, result.description)
            onTrackResult?(result)
        }
        guard !tealiumPurposeExplicitlyBlocked else {
            onTrackResult(.dropped(dispatch, reason: "Tealium consent purpose is explicitly blocked."))
            return
        }
        transformerCoordinator.transform(dispatch: dispatch, for: .afterCollectors) { [weak self] transformed in
            guard let self, let transformed else {
                onTrackResult(.dropped(dispatch, reason: "Transformers decision."))
                return
            }
            if let consentManager = self.consentManager {
                let result = consentManager.applyConsent(to: transformed)
                onTrackResult(result)
            } else {
                let dispatchersIds = dispatchers.map { $0.id }
                self.queueManager.storeDispatches([transformed], enqueueingFor: dispatchersIds)
                onTrackResult(.accepted(transformed, info: "Enqueued for processors: \(dispatchersIds)"))
            }
        }
    }

    private var managerContainer = AutomaticDisposer()

    func stopDispatchLoop() {
        managerContainer = AutomaticDisposer()
    }

    func startDispatchLoop() {
        onDispatchers.flatMapLatest { dispatchers in
            Observables.from(dispatchers)
        }.flatMap { [weak self, coordinator = barrierCoordinator] dispatcher in
            coordinator.onBarriersState(for: dispatcher.id)
                .flatMapLatest { [weak self] barriersState -> Observable<DispatchSplit> in
                    guard let self else { return Observables.empty() }
                    self.debugLog("BarrierState changed for \(dispatcher.id): \(barriersState)")
                    if barriersState == .open {
                        return self.startConsentedDequeueLoop(for: dispatcher)
                    } else {
                        return Observables.empty()
                    }
                }
                .flatMap { [weak self] dispatchSplit -> Observable<(Dispatcher, [Dispatch])> in
                    guard let self else {
                        return Observables.empty()
                    }
                    if !dispatchSplit.unsuccessful.isEmpty {
                        self.debugLog("Dispatches discarded due to consent \(dispatchSplit.unsuccessful.shortDescription())")
                    }
                    return self.transformAndDispatch(dispatches: dispatchSplit.successful, for: dispatcher)
                        .startWith(dispatchSplit.unsuccessful)
                        .filter { !$0.isEmpty }
                        .map { (dispatcher, $0) }
                }
        }
        .subscribe { [weak self] dispatcher, processedDispatches in
            self?.queueManager.deleteDispatches(processedDispatches.map { $0.id }, for: dispatcher.id)
            self?.debugLog("Dispatcher: \(dispatcher.id) processed events: \(processedDispatches.shortDescription())")
        }.addTo(self.managerContainer)
    }

    private func startConsentedDequeueLoop(for dispatcher: Dispatcher) -> Observable<DispatchSplit> {
        if let consentManager {
            consentManager.onConfigurationSelected
                .flatMapLatest { [weak self] configuration in
                    guard let self, let configuration else { return Observables.empty() }
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
                    .map { _ in queueManager.dequeueDispatches(for: dispatcher.id,
                                                               limit: min(dispatcher.dispatchLimit, Self.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER))
                    }
                    .resubscribingWhile { $0.count >= dispatcher.dispatchLimit } // Loops the `dequeueDispatches` as long as we pull `dispatchLimit` items from the queue
            }
    }

    /// Applies dispatcher-scoped transformations and load rules to `dispatches`, then sends the result to `dispatcher`.
    ///
    /// Emits one `[Dispatch]` batch per completion callback from the dispatcher, plus a batch for any dispatches removed
    /// by transformers or load rules (so the caller can delete them from the queue even though they were never sent).
    /// Completes when all dispatches have been accounted for, or immediately if `dispatches` is empty.
    private func transformAndDispatch(dispatches: [Dispatch],
                                      for dispatcher: Dispatcher) -> Observable<[Dispatch]> {
        guard !dispatches.isEmpty else {
            return Observables.empty()
        }
        return Observables.create { [transformerCoordinator, weak self] observer in
            let container = DisposableContainer()
            let totalInterval = beginInterval("Transform and Dispatch", with: dispatcher.id)
            let transformInterval = beginInterval("Transform", with: dispatcher.id)
            container.onDispose {
                transformInterval.end("Cancelled")
                totalInterval.end("Cancelled")
            }
            func complete(_ reason: @autoclosure @escaping () -> String) {
                totalInterval.end(reason())
                observer.onComplete()
            }
            transformerCoordinator.transform(dispatches: dispatches,
                                             for: .dispatcher(id: dispatcher.id)) { [weak self] transformedDispatches in
                guard !container.isDisposed else { return }
                transformInterval.end()
                guard let self else {
                    return complete("Deallocated Self")
                }
                let (passed, _) = self.loadRuleEngine.evaluateLoadRules(on: transformedDispatches,
                                                                        forModule: dispatcher)
                let removedDispatches = dispatches.diff(passed, by: \.id)
                if !removedDispatches.isEmpty {
                    debugLog("Dispatching disallowed for Dispatcher \(dispatcher.id) and Dispatches \(removedDispatches.shortDescription())")
                    observer.onNext(removedDispatches)
                }
                guard !passed.isEmpty else {
                    return complete("No Dispatch left to send after transformations and load rules.")
                }
                let mapped = passed.map { self.mappingsEngine.map(dispatcherId: dispatcher.id, dispatch: $0) }
                self.dispatch(mapped, to: dispatcher, onProcessed: observer.onNext(_:), completion: complete(_:))
                    .addTo(container)
            }.addTo(container)
            return container
        }
    }

    /// Sends `dispatches` to `dispatcher` and tracks completion across potentially multiple callbacks.
    ///
    /// `onProcessed` is called once per batch of dispatches acknowledged by the dispatcher.
    /// `completion` is called (with a reason string) once every dispatch has been acknowledged, i.e. when the
    /// dispatcher's remaining IDs reach zero. Disposing the returned `Disposable` silently cancels any pending callbacks.
    private func dispatch(
        _ dispatches: [Dispatch],
        to dispatcher: Dispatcher,
        onProcessed: @escaping ([Dispatch]) -> Void,
        completion: @escaping (@autoclosure @escaping () -> String) -> Void
    ) -> Disposable {
        let container = DisposableContainer()
        let dispatchInterval = beginInterval("Dispatch", with: dispatcher.id)
        container.onDispose {
            dispatchInterval.end("Cancelled")
        }
        var remainingDispatches = dispatches.map(\.id)
        debugLog("Sending events to dispatcher \(dispatcher.id): \(dispatches.shortDescription())")
        dispatcher.dispatch(dispatches) { processedDispatches in
            guard !container.isDisposed else { return }
            TealiumSignposter.dispatching.event("Event Batch", "Dispatcher: \(dispatcher.id) dispatched: \(processedDispatches.shortDescription())")
            onProcessed(processedDispatches)
            remainingDispatches = remainingDispatches.diff(processedDispatches.map(\.id), by: \.self)
            if remainingDispatches.isEmpty {
                dispatchInterval.end()
                completion(dispatches.shortDescription())
            }
        }.addTo(container)
        return container
    }

    private func debugLog(_ message: @autoclosure @escaping () -> String) {
        logger?.debug(category: LogCategory.dispatchManager, message())
    }
}

private func beginInterval(_ name: StaticString, with messageProvider: String) -> TealiumSignpostInterval {
    TealiumSignpostInterval(signposter: .dispatching, name: name).begin(messageProvider)
}

extension Array where Element == Dispatch {
    func shortDescription() -> String {
        "\(map { $0.logDescription() })"
    }
}
