//
//  BarrierRegistry.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/**
 * The `BarrierRegistry` is responsible for registering and unregistering additional `Barrier`s.
 *
 * - Attention: Barriers registered using the `BarrierRegistry` will not receive updated settings.
 */
public protocol BarrierRegistry {
    /**
     * Registers or updates an additional `Barrier` with the applied `scopes`.
     *
     * - Parameters:
     *  - barrier: The `Barrier` to add to the list of barriers.
     *  - scopes: The array of `BarrierScope`s that this `Barrier` applies to.
     */
    func registerScopedBarrier(_ barrier: Barrier, scopes: [BarrierScope])

    /**
     * Unregisters the given `barrier` if it's currently registered.
     *
     * - parameter barrier: The `Barrier` to remove from the list of barriers.
     */
    func unregisterScopedBarrier(_ barrier: Barrier)
}
