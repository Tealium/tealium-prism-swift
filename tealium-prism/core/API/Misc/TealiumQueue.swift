//
//  TealiumQueue.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/08/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A wrapper class around DispatchQueue to only dispatch asynchronously when we are on a different queue.
 *
 * Making it dispatch synchronously in a generic library would instead be not safe and could lead to deadlocks.
 * An example of deadlock that would look safe is this:
 * ```
 * DispatchQueue.main.async {
 *     let queue = TealiumQueue(label: "something")
 *     queue.ensureOnQueue {
 *         print("This will print")
 *         DispatchQueue.main.sync { // This is something that a user might do on one of our completions
 *             print("This will never print")
 *         }
 *     }
 *     queue.syncOnQueue { // This is something that might be part of our library if we do introduce a method like this
 *         print("This will never print")
 *     }
 * }
 * ```
 *
 * Therefore we only have, and only should have, an async method which is `ensureOnQueue`.
 */
public class TealiumQueue {
    /// The main queue for UI-related operations.
    public static let main = TealiumQueue(dispatchQueue: .main)
    /// A background worker queue for SDK operations.
    public static let worker = TealiumQueue(label: "com.tealium.swift", qos: .utility)

    private let queueSpecificKey = DispatchSpecificKey<Void>()
    /// The underlying dispatch queue.
    public let dispatchQueue: DispatchQueue
    var enforceQoS = DispatchQoS.unspecified
    /// Creates a new queue with the specified label and quality of service.
    /// - Parameters:
    ///   - label: The label for the queue.
    ///   - qos: The quality of service level.
    public convenience init(label: String, qos: DispatchQoS = .default) {
        self.init(dispatchQueue: DispatchQueue(label: label, qos: qos))
    }

    init(dispatchQueue: DispatchQueue) {
        self.dispatchQueue = dispatchQueue
        self.dispatchQueue.setSpecific(key: queueSpecificKey, value: ())
    }

    /**
     * Ensures that the work will be executed on the queue. If we are currently running on that queue the code will be synchronous, otherwise it will be asynchronous.
     * 
     * Can skip dispatch only if we don't want to specify any other parameters for the dispatch.
     * If we do than we need to call directly the queue.async method as we don't just want to make sure it's the correct queue.
     * This method can, and will, be asynchronous if we are on a different queue.
     */
    public func ensureOnQueue(_ work: @escaping () -> Void) {
        if isOnQueue() {
            work()
        } else {
            if enforceQoS != .unspecified {
                dispatchQueue.async(qos: enforceQoS, flags: .enforceQoS, execute: work)
            } else {
                dispatchQueue.async(execute: work)
            }
        }
    }

    /// Returns true if the currently running code is on the queue embedded in this class.
    public func isOnQueue() -> Bool {
        DispatchQueue.getSpecific(key: queueSpecificKey) != nil
    }

    deinit {
        dispatchQueue.setSpecific(key: queueSpecificKey, value: nil)
    }
}
