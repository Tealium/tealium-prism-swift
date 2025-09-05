//
//  Lifecycle.swift
//  tealium-swift
//
//  Created by Denis Guzov on 27/08/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

#if lifecycle
import TealiumCore
#endif

/**
 * The Lifecycle Module sends events related to application lifecycle -
 * launch, wake, and sleep.
 */
public protocol Lifecycle {
    /**
     * Sends a launch event and gathers all lifecycle data at the time event is triggered.
     * - Warning: Only use if lifecycle auto-tracking is disabled.
     * - Parameters:
     *   - dataObject: Optional data to be sent with launch event.
     * - Returns: A `Single` onto which you can subscribe to receive the completion with the eventual error in case of failure.
     */
    @discardableResult
    func launch(_ dataObject: DataObject?) -> SingleResult<Void>

    /**
     * Sends a wake event and gathers all lifecycle data at the time event is triggered.
     * - Warning: Only use if lifecycle auto-tracking is disabled.
     * - Parameters:
     *   - dataObject: Optional data to be sent with wake event.
     * - Returns: A `Single` onto which you can subscribe to receive the completion with the eventual error in case of failure.
     */
    @discardableResult
    func wake(_ dataObject: DataObject?) -> SingleResult<Void>

    /**
     * Sends a sleep event and gathers all lifecycle data at the time event is triggered.
     * - Warning: Only use if lifecycle auto-tracking is disabled.
     * - Parameters:
     *   - dataObject: Optional data to be sent with sleep event.
     * - Returns: A `Single` onto which you can subscribe to receive the completion with the eventual error in case of failure.
     */
    @discardableResult
    func sleep(_ dataObject: DataObject?) -> SingleResult<Void>
}

public extension Lifecycle {
    /**
     * Sends a launch event and gathers all lifecycle data at the time event is triggered.
     * - Warning: Only use if lifecycle auto-tracking is disabled.
     * - Returns: A `Single` onto which you can subscribe to receive the completion with the eventual error in case of failure.
     */
    @discardableResult
    func launch() -> SingleResult<Void> {
        launch(nil)
    }

    /**
     * Sends a wake event and gathers all lifecycle data at the time event is triggered.
     * - Warning: Only use if lifecycle auto-tracking is disabled.
     * - Returns: A `Single` onto which you can subscribe to receive the completion with the eventual error in case of failure.
     */
    @discardableResult
    func wake() -> SingleResult<Void> {
        wake(nil)
    }

    /**
     * Sends a sleep event and gathers all lifecycle data at the time event is triggered.
     * - Warning: Only use if lifecycle auto-tracking is disabled.
     * - Returns: A `Single` onto which you can subscribe to receive the completion with the eventual error in case of failure.
     */
    @discardableResult
    func sleep() -> SingleResult<Void> {
        sleep(nil)
    }
}
