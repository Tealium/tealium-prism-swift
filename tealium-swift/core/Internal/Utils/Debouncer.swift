//
//  Debouncer.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol DebouncerProtocol {
    func debounce(time: TimeInterval, completion: @escaping () -> Void)
    func cancel()
}

/**
 * A class that delays the execution of a block of code until the time between debounce calls expires, resetting the timer on each subsequent debounce call.
 */
public class Debouncer: DebouncerProtocol {
    private var timer: RepeatingTimer?
    private let queue: TealiumQueue
    public init(queue: TealiumQueue) {
        self.queue = queue
    }

    /**
     * Delays the execution of a block until an interval has passed, cancelling previous debounce calls.
     *
     * The debounce timer is added with a 10% leeway, coerced between a minimum of 1 and up to 100 milliseconds, for performance reasons.
     *
     * - Parameters:
     *    - time: the `TimeInterval`in seconds that has to be waited without further debounce calls before executing the completion block.
     *    - completion: the block that has to be executed once the time has passed
     */
    public func debounce(time: TimeInterval, completion: @escaping () -> Void) {
        timer = RepeatingTimer(timeInterval: time,
                               repeating: .never,
                               leeway: approximateLeeway(seconds: time),
                               queue: queue) { [weak self] in
            self?.timer = nil
            completion()
        }
        timer?.resume()
    }

    /// Cancel the ongoing timer and prevents the debounced block to be executed.
    public func cancel() {
        timer = nil
    }

    /**
     * Approximate leeway based on 10% of the provided time, coerced between a minimum of 1 and maximum 100 milliseconds.
     */
    func approximateLeeway(seconds: TimeInterval) -> DispatchTimeInterval {
        let coercedSeconds = seconds.coerce(min: 0.01, max: 1)
        let milliseconds = Int(coercedSeconds * 1000)
        return .milliseconds(milliseconds / 10)
    }
}
