//
//  BarrierCoordinator.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 20/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public enum BarrierState {
    case closed
    case open
}

/// An object that will change its state to stop or allow dispatching of events to some dispatchers.
public protocol Barrier {
    var id: String { get }
    var onState: TealiumObservable<BarrierState> { get }
}

/**
 * A class that takes a constant list of registered barriers and an observable of scopedBarriers and can be used to get the state of all the barriers that apply to a specific dispatcher
 *
 * The `onScopedBarriers` observable is assumed to emit one value on subscription, even if it's just with an empty array.
 */
class BarrierCoordinator {
    let registeredBarriers: [Barrier]
    let onScopedBarriers: TealiumObservable<[ScopedBarrier]>
    init(registeredBarriers: [Barrier], onScopedBarriers: TealiumObservable<[ScopedBarrier]>) {
        self.registeredBarriers = registeredBarriers
        self.onScopedBarriers = onScopedBarriers
    }

    /**
     * Returns an observable that will emit `open` when all the barriers (that apply to this dispatcher) open, and `closed` when at least one of them closes.
     *
     * When the scopedBarriers change the barriers get evaluated again and emit a new value.
     * A new value is emitted only if it's different from the last one.
     */
    func onBarrierState(for dispatcherId: String) -> TealiumObservable<BarrierState> {
        onScopedBarriers.flatMapLatest { newScopedBarriers in
            TealiumObservable.CombineLatest(self.getAllBarriers(scopedBarriers: newScopedBarriers, for: dispatcherId)
                .map { $0.onState })
            .map { barrierStates in
                barrierStates.first { $0 == .closed } ?? .open
            }
        }.distinct()
    }

    func getAllBarriers(scopedBarriers: [ScopedBarrier], for dispatcherId: String) -> [Barrier] {
        getBarriers(scopedBarriers: scopedBarriers, for: .all) +
        getBarriers(scopedBarriers: scopedBarriers, for: .dispatcher(dispatcherId))
    }

    func getBarriers(scopedBarriers: [ScopedBarrier], for scope: BarrierScope) -> [Barrier] {
        scopedBarriers.filter { $0.matchesScope(scope) }
            .compactMap { barrierScope in
                registeredBarriers.first { $0.id == barrierScope.barrierId }
            }
    }
}
