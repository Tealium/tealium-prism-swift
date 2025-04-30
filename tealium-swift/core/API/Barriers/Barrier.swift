//
//  Barrier.swift
//  tealium-swift
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
     * The observable of this barrier's current state.
     *
     * `BarrierState.closed` should be emitted to disallow further processing, and `BarrierState.open`
     * to allow processing again.
     */
    var onState: Observable<BarrierState> { get }
}
