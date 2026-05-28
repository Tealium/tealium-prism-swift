//
//  BarrierRegistrar.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/**
 * The `BarrierRegistrar` is responsible for registering and unregistering additional `Barrier`s.
 *
 * - Attention: Barriers registered using the `BarrierRegistrar` will not receive updated settings.
 */
public protocol BarrierRegistrar {
    /**
     * Registers or updates an additional `Barrier` with the applied `scope`.
     *
     * - Parameters:
     *  - barrier: The `Barrier` to add to the list of barriers.
     *  - scope: The `BarrierScope` that this `Barrier` applies to.
     */
    func registerScopedBarrier(_ barrier: Barrier, scope: BarrierScope)

    /**
     * Unregisters the given `barrier` if it's currently registered.
     *
     * - parameter barrier: The `Barrier` to remove from the list of barriers.
     */
    func unregisterScopedBarrier(_ barrier: Barrier)
}
