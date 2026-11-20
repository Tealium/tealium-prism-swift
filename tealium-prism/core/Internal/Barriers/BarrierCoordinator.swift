//
//  BarrierCoordinator.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 20/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A class that from an observable of scoped barriers can compute a single observable state per each `Dispatcher`.
 *
 * The `onScopedBarriers` observable is assumed to emit one value on subscription, even if it's just with an empty array.
 */
class BarrierCoordinator {
    private let onScopedBarriers: Observable<[ScopedBarrier]>
    private let onApplicationStatus: Observable<ApplicationStatus>
    private let queueMetrics: QueueMetrics
    private let queue: TealiumQueue
    private let backgroundTaskStarter: BackgroundTaskStarter
    private let disposer = AutomaticDisposer()
    private var queueFlushStates = [String: StateSubject<Bool>]()

    /// The milliseconds to wait for extra events before definitively flushing
    private let flushDebounceMilliseconds: Int
    /// The amount of milliseconds a flush operation can last, both in foreground and background
    private let flushTimeoutMilliseconds: Int

    @Subject<Void> var flushTrigger

    init(onScopedBarriers: Observable<[ScopedBarrier]>,
         onApplicationStatus: Observable<ApplicationStatus>,
         queueMetrics: QueueMetrics,
         flushDebounceMilliseconds: Int = 200,
         flushTimeoutMilliseconds: Int = 5000,
         backgroundTaskStarter: BackgroundTaskStarter? = nil,
         queue: TealiumQueue
    ) {
        self.onScopedBarriers = onScopedBarriers
        self.onApplicationStatus = onApplicationStatus
        self.queueMetrics = queueMetrics
        self.flushDebounceMilliseconds = flushDebounceMilliseconds
        self.flushTimeoutMilliseconds = flushTimeoutMilliseconds
        self.queue = queue
        self.backgroundTaskStarter = backgroundTaskStarter ?? BackgroundTaskStarter(queue: queue,
                                                                                    backgroundTaskTimeout: .seconds(3))
    }

    /**
     * Places the `BarrierCoordinator` into a "flushing" state for each dispatcher until the dispatches
     * pending for it have been dequeued (the pending count stays at zero for the debounce time), or for at most the flush timeout.
     *
     * The status of any barrier whose `Barrier.isFlushable` property returns `true` will be ignored
     * until the flush is completed.
     */
    func flush() {
        _flushTrigger.onNext(())
    }

    /// Stops the flush detection of every dispatcher. Called by `TealiumImpl.shutdown()` once the dispatch loop has stopped.
    func shutdown() {
        disposer.dispose()
    }

    /**
     * Returns an observable that will emit `open` when all the barriers (that apply to this dispatcher) open, and `closed` when at least one of them closes.
     *
     * When the barrier settings or their scope changes the barriers get evaluated again and emit a new value.
     * A new value is emitted only if it's different from the last one.
     *
     * The flush state of each dispatcher is shared by all the subscriptions to its barriers state, so subscribing again doesn't start a flush.
     * Must be called on the tealium queue.
     */
    func onBarriersState(for dispatcherId: String) -> Observable<BarrierState> {
        onBarriers(for: dispatcherId)
            .flatMapLatest({ barriers in
                self.filterFlushableBarriers(barriers, for: dispatcherId)
            })
            .flatMapLatest { barriers in
                self.areBarriersOpen(barriers, dispatcherId: dispatcherId)
            }.distinct()
    }

    func onBarriers(for dispatcherId: String) -> Observable<[Barrier]> {
        onScopedBarriers.map { barrierList in
            barrierList.filter { $0.scope.matches(dispatcherId: dispatcherId) }
                .map { $0.barrier }
        }
    }

    func filterFlushableBarriers(_ barriers: [Barrier], for dispatcherId: String) -> Observable<[Barrier]> {
        onQueueIsBeingFlushed(for: dispatcherId).flatMapLatest { isFlushing in
            guard isFlushing else {
                return Observables.just(barriers)
            }
            let nonFlushableBarriers = barriers.map { barrier in
                barrier.isFlushable.distinct().map { $0 ? nil : barrier }
            }
            return Observables.combineLatest(nonFlushableBarriers).map {
                $0.compactMap { $0 }
            }
        }
    }

    /**
     * Returns an observable that emits whether the queue of the dispatcher is being flushed.
     *
     * The flush state is shared per dispatcher: new subscribers receive the current state and don't start a flush.
     * A flush starts only when a new application status is emitted, or when `flush()` is called.
     * The status replayed to the first subscription is the one that causes the flush on launch.
     * The states live as long as the coordinator: the dispatcher ids are few, and a removed dispatcher's queue is emptied, so it doesn't flush again.
     * Must be called on the tealium queue.
     */
    private func onQueueIsBeingFlushed(for dispatcherId: String) -> Observable<Bool> {
        if let state = queueFlushStates[dispatcherId] {
            return state.asObservable()
        }
        let state = StateSubject(false)
        queueFlushStates[dispatcherId] = state
        detectQueueFlush(for: dispatcherId)
            .subscribe(state)
            .addTo(disposer)
        return state.asObservable()
    }

    private func detectQueueFlush(for dispatcherId: String) -> Observable<Bool> {
        onApplicationStatus
            .map { $0.type == .backgrounded }
            .merge(flushTrigger.map { true }) // Assume we might need a background task in case of user manual flush.
            .flatMapLatest { [queueMetrics, queue, flushDebounceMilliseconds, flushTimeoutMilliseconds, backgroundTaskStarter] requiresBackgroundTask in
                queueMetrics.onQueueSizePendingDispatch(for: dispatcherId)
                    .map { $0 > 0 }  // should flush is true until queue pending dispatches is empty
                    .distinct()
                // Debounce to make sure queue size is not changing again very soon,
                // for example when a transformer (e.g. `DeviceData`) takes some time
                // to transform a `sleep` event coming from lifecycle.
                // Only changes between empty and non-empty restart the debounce, so steady arrivals can't postpone the flush.
                    .debounce(flushDebounceMilliseconds, on: queue)
                    .merge(Observables.just(false).delay(flushTimeoutMilliseconds, on: queue)) // stop flush after a while anyway
                    .takeWhile({ $0 }, inclusive: true) // stop listening when flush ended, include final false to stop the flush
                    .distinct()
                    .flatMapLatest { beingFlushed in
                        guard beingFlushed, requiresBackgroundTask else {
                            return Observables.just(beingFlushed)
                        }
                        return backgroundTaskStarter.startBackgroundTask(withName: "com.tealium.flush.\(dispatcherId)")
                    }
            }.startWith(false)
            .distinct()
    }

    private func areBarriersOpen(_ barriers: [any Barrier], dispatcherId: String) -> Observable<BarrierState> {
        Observables.combineLatest(barriers.map { $0.onState(for: dispatcherId) })
            .map { barrierStates in
                barrierStates.first { $0 == BarrierState.closed } ?? BarrierState.open
            }
    }
}
