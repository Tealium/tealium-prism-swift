//
//  Backoff.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 12/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// A delay, in seconds, computed from the number of retries already made. Useful to understand how much time we
/// should wait before retrying.
struct Backoff {
    /// Computes the delay, in seconds, for the given retry count: the number of retries already made, so 0 is the first retry.
    let calculate: (_ retryCount: Int) -> TimeInterval

    /// Returns a `Backoff` whose delay is `transform` applied to this instance's delay.
    func map(_ transform: @escaping (TimeInterval) -> TimeInterval) -> Backoff {
        Backoff { transform(self.calculate($0)) }
    }
}

extension Backoff {
    /**
     * A delay that grows exponentially with the retry count.
     *
     * For retry count `n` the delay is `min(maximum, initialDelay * multiplier^max(0, n))`: the first retry (`n` = 0) waits
     * `initialDelay` and every following one multiplies it by `multiplier`, until `maximum` is reached.
     *
     * The delay is always a finite number between 0 and `maximum`: a NaN result counts as 0, and a result that
     * overflows counts as `maximum`, or as the greatest finite value when `maximum` is infinite.
     * A NaN or negative `maximum` counts as 0.
     */
    static func exponential(initialDelay: TimeInterval, multiplier: TimeInterval = 2, maximum: TimeInterval) -> Backoff {
        let maximum = maximum.isNaN ? 0 : max(0, maximum)
        let finiteMaximum = maximum.isFinite ? maximum : .greatestFiniteMagnitude
        return Backoff { retryCount in
            let delay = initialDelay * pow(multiplier, Double(max(0, retryCount)))
            if delay.isNaN {
                return 0
            }
            return min(max(0, delay), finiteMaximum)
        }
    }

    /**
     * A random delay between 0 and the delay of `exponential(initialDelay:multiplier:maximum:)`, also known as "full jitter".
     *
     * - Parameters:
     *    - initialDelay: the upper bound of the first retry's delay.
     *    - multiplier: the factor applied to the upper bound at every following retry.
     *    - maximum: the greatest upper bound.
     *    - random: returns a random value in the given range; injectable for tests.
     */
    static func jitteredExponential(initialDelay: TimeInterval,
                                    multiplier: TimeInterval = 2,
                                    maximum: TimeInterval,
                                    random: @escaping (ClosedRange<Double>) -> Double = { Double.random(in: $0) }) -> Backoff {
        exponential(initialDelay: initialDelay, multiplier: multiplier, maximum: maximum)
            .map { upperBound in upperBound > 0 ? random(0...upperBound) : 0 }
    }
}
