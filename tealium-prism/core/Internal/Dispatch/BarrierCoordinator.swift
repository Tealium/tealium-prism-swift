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
    private let debouncer: DebouncerProtocol
    private let queue: TealiumQueue
    private let backgroundTaskStarter: BackgroundTaskStarter
    private let disposer = AutomaticDisposer()

    /// The time to wait for extra events before definitively flushing
    private let flushDebounceDelay: TimeInterval = 0.2
    /// The amount of time a flush operation can last, both in foreground and background
    private let flushTimeout = DispatchTimeInterval.seconds(5)

    @StateSubject(false)
    var ongoingBackgroundTask

    @Subject<Void> var flushTrigger

    init(onScopedBarriers: Observable<[ScopedBarrier]>,
         onApplicationStatus: Observable<ApplicationStatus>,
         queueMetrics: QueueMetrics,
         debouncer: DebouncerProtocol,
         queue: TealiumQueue
    ) {
        self.onScopedBarriers = onScopedBarriers
        self.onApplicationStatus = onApplicationStatus
        self.queueMetrics = queueMetrics
        self.debouncer = debouncer
        self.queue = queue
        self.backgroundTaskStarter = BackgroundTaskStarter(queue: queue,
                                                           backgroundTaskTimeout: .seconds(3))
        onApplicationStatus.filter { $0.type == .backgrounded }
            .flatMapLatest { [weak self] _ in
                guard let self else { return Observables.empty() }
                return self.backgroundTaskStarter.startBackgroundTask()
            }.subscribe { [_ongoingBackgroundTask] ongoing in
                _ongoingBackgroundTask.publishIfChanged(ongoing)
            }.addTo(disposer)
    }

    /**
     * Places the `BarrierCoordinator` into a "flushing" state for each dispatcher until any queued
     * `Dispatch`es have been processed and the queue size is reduced to zero.
     *
     * The status of any barrier whose `Barrier.isFlushable` property returns `true` will be ignored
     * until the flush is completed.
     */
    func flush() {
        _flushTrigger.publish(())
    }

    /**
     * Returns an observable that will emit `open` when all the barriers (that apply to this dispatcher) open, and `closed` when at least one of them closes.
     *
     * When the barrier settings or their scope changes the barriers get evaluated again and emit a new value.
     * A new value is emitted only if it's different from the last one.
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
            barrierList.filter { $0.scopes.contains(.dispatcher(dispatcherId)) || $0.scopes.contains(.all) }
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

    func onQueueIsBeingFlushed(for dispatcherId: String) -> Observable<Bool> {
        onApplicationStatus
            .flatMapLatest { [weak self] status in
                guard let self else { return Observables.just(true) }
                switch status.type {
                case .backgrounded:
                    return self.ongoingBackgroundTask.takeWhile({ $0 }, inclusive: true)
                default:
                    return Observables.just(true)
                }
            }.filter { $0 }
            .map { _ in }
            .merge(flushTrigger)
            .flatMapLatest { [debouncer, queueMetrics, queue, flushDebounceDelay, flushTimeout] _ in
                queueMetrics.onQueueSizePendingDispatch(for: dispatcherId)
                // Debounce to make sure queue size is not changing again very soon,
                // for example when a transformer (e.g. `DeviceData`) takes some time
                // to transform a `sleep` event coming from lifecycle.
                    .debounce(delay: flushDebounceDelay, debouncer: debouncer)
                    .map { $0 > 0 }  // should flush is true until queue pending dispatches is empty
                    .merge(Observables.just(false).delay(flushTimeout, on: queue)) // stop flush after a while anyway
                    .takeWhile({ $0 }, inclusive: true) // stop listening when flush ended, include final false to stop the flush
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
