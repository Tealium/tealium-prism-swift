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

    init(onScopedBarriers: Observable<[ScopedBarrier]>) {
        self.onScopedBarriers = onScopedBarriers
    }

    /**
     * Returns an observable that will emit `open` when all the barriers (that apply to this dispatcher) open, and `closed` when at least one of them closes.
     *
     * When the barrier settings or their scope changes the barriers get evaluated again and emit a new value.
     * A new value is emitted only if it's different from the last one.
     */
    func onBarrierState(for dispatcherId: String) -> Observable<BarrierState> {
        onBarriers(for: dispatcherId).flatMapLatest { barriers in
            Observable.CombineLatest(barriers.map { $0.onState })
                .map { barrierStates in
                    barrierStates.first { $0 == BarrierState.closed } ?? BarrierState.open
                }
        }.distinct()
    }

    func onBarriers(for dispatcherId: String) -> Observable<[Barrier]> {
        onScopedBarriers.map { barrierList in
            barrierList.filter { $0.scopes.contains(.dispatcher(dispatcherId)) || $0.scopes.contains(.all) }
                .map { $0.barrier }
        }
    }
}
