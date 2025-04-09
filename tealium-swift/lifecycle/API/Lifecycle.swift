//
//  Lifecycle.swift
//  tealium-swift
//
//  Created by Denis Guzov on 27/08/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

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
     *   - completion: Optional completion block, which is going to be called with error if operation is unsuccessful, or without any arguments otherwise.
     */
    func launch(_ dataObject: DataObject?, _ completion: ErrorHandlingCompletion?)

    /**
     * Sends a wake event and gathers all lifecycle data at the time event is triggered.
     * - Warning: Only use if lifecycle auto-tracking is disabled.
     * - Parameters:
     *   - dataObject: Optional data to be sent with wake event.
     *   - completion: Optional completion block, which is going to be called with error if operation is unsuccessful, or without any arguments otherwise.
     */
    func wake(_ dataObject: DataObject?, _ completion: ErrorHandlingCompletion?)

    /**
     * Sends a sleep event and gathers all lifecycle data at the time event is triggered.
     * - Warning: Only use if lifecycle auto-tracking is disabled.
     * - Parameters:
     *   - dataObject: Optional data to be sent with sleep event.
     *   - completion: Optional completion block, which is going to be called with error if operation is unsuccessful, or without any arguments otherwise.
     */
    func sleep(_ dataObject: DataObject?, _ completion: ErrorHandlingCompletion?)
}

public extension Lifecycle {
    /**
     * Sends a launch event and gathers all lifecycle data at the time event is triggered.
     * - Warning: Only use if lifecycle auto-tracking is disabled.
     */
    func launch() {
        launch(nil)
    }
    /**
     * Sends a launch event and gathers all lifecycle data at the time event is triggered.
     * - Warning: Only use if lifecycle auto-tracking is disabled.
     * - parameter dataObject: Optional data to be sent with event.
     */
    func launch(_ dataObject: DataObject?) {
        launch(dataObject, nil)
    }
    /**
     * Sends a wake event and gathers all lifecycle data at the time event is triggered.
     * - Warning: Only use if lifecycle auto-tracking is disabled.
     */
    func wake() {
        wake(nil)
    }
    /**
     * Sends a wake event and gathers all lifecycle data at the time event is triggered.
     * - Warning: Only use if lifecycle auto-tracking is disabled.
     * - parameter dataObject: Optional data to be sent with event.
     */
    func wake(_ dataObject: DataObject?) {
        wake(dataObject, nil)
    }
    /**
     * Sends a sleep event and gathers all lifecycle data at the time event is triggered.
     * - Warning: Only use if lifecycle auto-tracking is disabled.
     */
    func sleep() {
        sleep(nil)
    }
    /**
     * Sends a sleep event and gathers all lifecycle data at the time event is triggered.
     * - Warning: Only use if lifecycle auto-tracking is disabled.
     * - parameter dataObject: Optional data to be sent with event.
     */
    func sleep(_ dataObject: DataObject?) {
        sleep(dataObject, nil)
    }
}
