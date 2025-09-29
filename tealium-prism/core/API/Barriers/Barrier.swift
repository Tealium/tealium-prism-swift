//
//  Barrier.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

public enum BarrierState {
    case closed
    case open
}

/// An object that will change its state to stop or allow dispatching of events to some dispatchers.
public protocol Barrier: AnyObject {
    /**
     * The observable of this barrier's current state for specific dispatcher.
     *
     * `BarrierState.closed` should be emitted to disallow further processing, and `BarrierState.open`
     * to allow processing again.
     *
     * - parameter dispatcherId: id of the `Dispatcher` whose barrier state is observed
     */
    func onState(for dispatcherId: String) -> Observable<BarrierState>

    /**
     * States whether or not this `Barrier` can be bypassed for "flush" events.
     *
     * - Returns: An `Observable` that emits `true` if this `Barrier` can be bypassed; else `false`.
     */
    var isFlushable: Observable<Bool> { get }
}

extension Barrier {
    var isFlushable: Observable<Bool> {
        return .Just(true)
    }
}
