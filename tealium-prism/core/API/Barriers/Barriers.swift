//
//  Barriers.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 24/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * Utility object for getting built-in `BarrierFactory` objects when configuring the Tealium instance.
 *
 * Some barriers are added to the system by default, but remain accessible here to allow users to
 * override the "scope" that they apply to.
 */
public enum Barriers {}

public extension Barriers {
    /**
     * A block with a utility builder that can be used to enforce some of the `BarrierSettings` instead of relying on Local or Remote settings.
     * Only the settings built with this builder will be enforced and remain constant during the lifecycle of the `Barrier`,
     * other settings will still be affected by Local and Remote settings and updates.
     */
    typealias EnforcingSettings<Builder> = (_ enforcedSettings: Builder) -> Builder

    /**
     * Returns the `BarrierFactory` for creating the "ConnectivityBarrier". Use this barrier to only
     * dispatch events when connectivity is required.
     *
     * - parameter block: A block used to provide programmatic settings. See `EnforcingSettings`.
     *
     * By default, this barrier is active and scoped to Collect module.
     * You can call the following method to programmatically change the scope (or other barrier settings),
     * or you can use local/remote settings configuration instead.
     * ```swift
     *  config.addBarrier(Barriers.connectivity(forcingSettings: { enforcedSettings in
     *      enforcedSettings.setScope(.dispatchers([])) // setting empty dispatcherIds deactivates the barrier
     *  }))
     * ```
     */
    static func connectivity(forcingSettings block: EnforcingSettings<ConnectivityBarrierSettingsBuilder>? = { $0 }) -> some BarrierFactory {
        ConnectivityBarrier.Factory(defaultScope: .dispatchers([Modules.Types.collect]),
                                    enforcedSettings: block?(ConnectivityBarrierSettingsBuilder()).build())
    }

    /**
     * Returns the `BarrierFactory` for creating the "BatchingBarrier". Use this barrier to only
     * dispatch events when a certain number of queued events has been reached for any of the
     * `Dispatcher` in scope.
     *
     * - parameter block: A block used to provide programmatic settings. See `EnforcingSettings`.
     *
     * By default, this barrier is not scoped to any module, thus being not active, until you call the following method or provide some scope with local or remote settings.
     * ```swift
     *  config.addBarrier(Barriers.batching())
     * ```
     * Without any enforced settings passed BatchingBarrier will be scoped to Collect module automatically.
     * That default scope can be overwritten using programmatic/remote/local settings configuration.
     * Example of programmatic approach:
     * ```swift
     *  config.addBarrier(Barriers.batching(forcingSettings: { enforcedSettings in
     *      enforcedSettings.setScope(.dispatchers(["MyDispatcher"]))
     *  }))
     * ```
     */
    static func batching(forcingSettings block: EnforcingSettings<BatchingBarrierSettingsBuilder>? = { $0 }) -> some BarrierFactory {
        BatchingBarrier.Factory(defaultScope: .dispatchers([Modules.Types.collect]),
                                enforcedSettings: block?(BatchingBarrierSettingsBuilder()).build())
    }
}
