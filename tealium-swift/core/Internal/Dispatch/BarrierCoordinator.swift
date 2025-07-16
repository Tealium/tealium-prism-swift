//
//  BarrierCoordinator.swift
//  tealium-swift
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

    init(onScopedBarriers: Observable<[ScopedBarrier]>, onApplicationStatus: Observable<ApplicationStatus>, queueMetrics: QueueMetrics) {
        self.onScopedBarriers = onScopedBarriers
        self.onApplicationStatus = onApplicationStatus
        self.queueMetrics = queueMetrics
    }

    @ToAnyObservable<BasePublisher<Void>>(BasePublisher())
    var flushTrigger

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
                return Observable.Just(barriers)
            }
            let nonFlushableBarriers = barriers.map { barrier in
                barrier.isFlushable.distinct().map { $0 ? nil : barrier }
            }
            return Observable.CombineLatest(nonFlushableBarriers).map {
                $0.compactMap { $0 }
            }
        }
    }

    func onQueueIsBeingFlushed(for dispatcherId: String) -> Observable<Bool> {
        onApplicationStatus.map { _ in () }
            .merge(flushTrigger)
            .flatMapLatest {_ in
                self.queueMetrics.onQueueSizePendingDispatch(for: dispatcherId)
                    .map { $0 > 0 }
                    .takeWhile({ $0 }, inclusive: true)
            }.startWith(false)
            .distinct()
    }

    private func areBarriersOpen(_ barriers: [any Barrier], dispatcherId: String) -> Observable<BarrierState> {
        Observable.CombineLatest(barriers.map { $0.onState(for: dispatcherId) })
            .map { barrierStates in
                barrierStates.first { $0 == BarrierState.closed } ?? BarrierState.open
            }
    }
}
