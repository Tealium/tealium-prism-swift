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
    /// New batches are dequeued for a `Dispatcher` only while it has fewer inflight events than this.
    ///
    /// This is a threshold, not a hard limit: a batch of up to `dispatchLimit` is still dequeued as a whole,
    /// so the inflight count can exceed it by up to one batch.
    static let MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER = 50
    private let barrierCoordinator: BarrierCoordinator
    private let transformerCoordinator: TransformerCoordinator
    /// The SDK queue the dispatch loop runs on, used to request the follow-up dequeues asynchronously.
    private let queue: TealiumQueue

    /**
     * The active `Dispatcher`s, re-emitted whenever the module list changes only when they are ready.
     *
     * The dequeue loop is rebuilt on every emission, so it relies on the source de-duplicating by identity.
     */
    private let onDispatchers: Observable<[Dispatcher]>
    private let queueManager: QueueManagerProtocol
    private let consentManager: ConsentManager?
    private let logger: LoggerProtocol?
    @Subject<Void> private var onQueuedEvents
    private let loadRuleEngine: LoadRuleEngine
    private let mappingsEngine: MappingsEngine
    init(loadRuleEngine: LoadRuleEngine,
         onDispatchers: Observable<[Dispatcher]>,
         consentManager: ConsentManager?,
         queueManager: QueueManagerProtocol,
         barrierCoordinator: BarrierCoordinator,
         transformerCoordinator: TransformerCoordinator,
         mappingsEngine: MappingsEngine,
         queue: TealiumQueue,
         logger: LoggerProtocol?) {
        self.loadRuleEngine = loadRuleEngine
        self.onDispatchers = onDispatchers
        self.consentManager = consentManager
        self.queueManager = queueManager
        self.barrierCoordinator = barrierCoordinator
        self.transformerCoordinator = transformerCoordinator
        self.mappingsEngine = mappingsEngine
        self.queue = queue
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
                // Enqueue the transformed `Dispatch` for the enabled and ready `Dispatcher`s.
                self.onDispatchers.subscribeOnce { [queueManager] dispatchers in
                    let dispatchersIds = dispatchers.map { $0.id }
                    guard !dispatchersIds.isEmpty else {
                        // Storing for no processor at all would drop the dispatch silently.
                        onTrackResult(.dropped(transformed, reason: "No dispatcher is enabled."))
                        return
                    }
                    queueManager.storeDispatches([transformed], enqueueingFor: dispatchersIds)
                    onTrackResult(.accepted(transformed, info: "Enqueued for processors: \(dispatchersIds)"))
                }
            }
        }
    }

    private var dispatchLoop: AutomaticDisposer?

    func stopDispatchLoop() {
        dispatchLoop?.dispose()
        dispatchLoop = nil
    }

    /// Starts the loop that, for every active `Dispatcher`, requests dequeues of its queued `Dispatch`es, dequeues them,
    /// transforms them and hands them over to be sent.
    ///
    /// Calling this while a loop is already running is a no-op: `stopDispatchLoop()` must be called first for a fresh
    /// subscription to be made. A `stopDispatchLoop()` issued while the subscription is still being set up, such as from
    /// code reacting synchronously to the first dequeue, is honored and leaves the loop stopped.
    ///
    /// Where each stage sits relative to the outer `flatMapLatest` decides what a change to the dispatcher list cancels,
    /// so the placement is load bearing.
    ///
    /// Everything that decides *when* a `Dispatcher` acquires work, meaning its barrier subscription, its consent
    /// configuration and its loop of `DequeueRequest`s, is built inside the `flatMapLatest` and is therefore disposable.
    /// A new emission from `onDispatchers` replaces that whole set of loops at once, which gives two guarantees:
    /// - a dispatcher that is no longer in the list has no loop, so it neither drains what is still queued for it nor
    ///   stays alive through a subscription that outlives it;
    /// - a dispatcher that remains in the list has exactly one loop, so new batches are dequeued for it only while it
    ///   has fewer than `MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER` in flight, regardless of how often the list changes.
    ///
    /// The dequeue itself, and the work it acquires, are deliberately kept out of that scope. A dequeue can
    /// synchronously close a barrier, remove the consent configuration or change the list, which disposes the loop that
    /// requested it; downstream of the `flatMapLatest` such a change only stops the requests that follow, and the
    /// dequeued batch is still sent. `transformAndDispatch` is downstream too, so dispatches already handed to a
    /// `Dispatcher` still get to report completion.
    ///
    /// The cost is that surviving dispatchers are rebuilt too, since the list is replaced wholesale rather than diffed.
    /// Repeating a dequeue is harmless, because `dequeueDispatches` never returns a dispatch that is already in flight
    /// and so cannot send one twice. The source (`ModuleManager.observeModules`) also drops emissions that leave the
    /// list untouched, keeping rebuilds to the changes that genuinely alter the set of dispatchers.
    func startDispatchLoop() {
        guard dispatchLoop == nil else { return }
        // Assigned before subscribing so that a stopDispatchLoop() re-entered from within the
        // synchronous subscribe (e.g. from code reacting synchronously to the first dequeue) is honored:
        // by the time the subscription is added below the container is already disposed, and add() disposes it.
        let loop = AutomaticDisposer()
        dispatchLoop = loop
        onDispatchers.flatMapLatest { [weak self, coordinator = barrierCoordinator] dispatchers in
            Observables.from(dispatchers)
                .flatMap { [weak self] dispatcher in
                    coordinator.onBarriersState(for: dispatcher.id)
                        .flatMapLatest { [weak self] barriersState -> Observable<DequeueRequest> in
                            guard let self else { return Observables.empty() }
                            self.debugLog("BarrierState changed for \(dispatcher.id): \(barriersState)")
                            if barriersState == .open {
                                return self.startConsentedDequeueRequests(for: dispatcher)
                            } else {
                                return Observables.empty()
                            }
                        }
                }
        }
        // Dequeue outside of the `flatMapLatest`s above, so a change the dequeue triggers can't drop the dequeued batch.
        .map { [weak self] request -> (Dispatcher, DispatchSplit) in
            guard let self else { return (request.dispatcher, ([], [])) }
            return (request.dispatcher, self.dequeue(request))
        }
        .flatMap { [weak self] dispatcher, dispatchSplit -> Observable<(Dispatcher, [Dispatch])> in
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
        .subscribe { [weak self] dispatcher, processedDispatches in
            self?.queueManager.deleteDispatches(processedDispatches.map { $0.id }, for: dispatcher.id)
            self?.debugLog("Dispatcher: \(dispatcher.id) processed events: \(processedDispatches.shortDescription())")
        }.addTo(loop)
    }

    /// A request to dequeue one batch for `dispatcher`, emitted by the dequeue loop while the barriers are open.
    private struct DequeueRequest {
        let dispatcher: Dispatcher
        /// The consent configuration to split the batch with, `nil` when there is no consent integration.
        let consentConfiguration: ConsentConfiguration?
        /// Requests the next dequeue, asynchronously: called when the batch filled the dequeue limit.
        let onFullBatch: () -> Void
    }

    private func dequeue(_ request: DequeueRequest) -> DispatchSplit {
        let dispatcher = request.dispatcher
        let limit = max(min(dispatcher.dispatchLimit, Self.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER), 1)
        let dispatches = queueManager.dequeueDispatches(for: dispatcher.id, limit: limit)
        if dispatches.count >= limit {
            request.onFullBatch()
        }
        guard let consentConfiguration = request.consentConfiguration else {
            return (dispatches, [])
        }
        return dispatches.partitioned {
            $0.matchesConfiguration(consentConfiguration, forDispatcher: dispatcher.id)
        }
    }

    private func startConsentedDequeueRequests(for dispatcher: Dispatcher) -> Observable<DequeueRequest> {
        if let consentManager {
            consentManager.onConfigurationSelected
                .flatMapLatest { [weak self] consentConfiguration in
                    guard let self, let consentConfiguration else { return Observables.empty() }
                    // Only dequeue events after we have a valid configuration from `ConsentManager`
                    return self.startDequeueRequests(for: dispatcher, consentConfiguration: consentConfiguration)
                }
        } else {
            startDequeueRequests(for: dispatcher, consentConfiguration: nil)
        }
    }

    /// Emits a `DequeueRequest` on the loop start, on every enqueue for `dispatcher`, and after every full batch,
    /// each time only once the inflight count is below the maximum.
    ///
    /// The request after a full batch is emitted in its own block on the SDK queue, so that draining a backlog
    /// does not recurse, and any state change the previous dequeue triggered is handled before it.
    private func startDequeueRequests(for dispatcher: Dispatcher, consentConfiguration: ConsentConfiguration?) -> Observable<DequeueRequest> {
        let onInflightLower = queueManager.onInflightDispatchesCount(for: dispatcher.id)
            .map { $0 < Self.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER }
            .distinct()
        let onFullBatch = Subject<Void>()
        // Always asynchronous, even on `queue`. Once this loop is disposed, `onFullBatch` has no observer left
        // and the late request is dropped; a new loop creates its own `onFullBatch`.
        let request = DequeueRequest(dispatcher: dispatcher, consentConfiguration: consentConfiguration) { [queue] in
            queue.async { onFullBatch.onNext(()) }
        }
        return onFullBatch.asObservable()
            .merge(queueManager.onEnqueuedDispatchesForProcessors
                .filter { processors in processors.contains { $0 == dispatcher.id } }
                .map { _ in () }
                .startWith(()))
            .flatMapLatest { _ in
                onInflightLower
                    .first { $0 }
                    .map { _ in request }
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
    ) -> any Disposable {
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
