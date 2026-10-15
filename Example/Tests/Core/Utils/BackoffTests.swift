//
//  BackoffTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 28/09/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class BackoffTests: XCTestCase {
    var receivedLowerBounds: [Double] = []
    var receivedUpperBounds: [Double] = []

    func jitteredBackoff(initialDelay: TimeInterval, maximum: TimeInterval) -> Backoff {
        .jitteredExponential(initialDelay: initialDelay, maximum: maximum) { range in
            self.receivedLowerBounds.append(range.lowerBound)
            self.receivedUpperBounds.append(range.upperBound)
            return range.upperBound
        }
    }

    // MARK: - jitteredExponential

    func test_jittered_backoff_passes_exponential_upper_bound_to_random_source() {
        let backoff = jitteredBackoff(initialDelay: 0.5, maximum: 20)
        for retryCount in 0...3 {
            _ = backoff.calculate(retryCount)
        }
        XCTAssertEqual(receivedLowerBounds, [0, 0, 0, 0])
        XCTAssertEqual(receivedUpperBounds, [0.5, 1, 2, 4])
    }

    func test_jittered_backoff_returns_random_source_value() {
        let backoff = Backoff.jitteredExponential(initialDelay: 1, maximum: 20) { range in
            range.upperBound / 2
        }
        XCTAssertEqual(backoff.calculate(2), 2)
    }

    func test_jittered_backoff_treats_negative_retry_counts_as_first_retry() {
        let backoff = jitteredBackoff(initialDelay: 1, maximum: 20)
        _ = backoff.calculate(0)
        _ = backoff.calculate(-1)
        _ = backoff.calculate(-3)
        XCTAssertEqual(receivedLowerBounds, [0, 0, 0])
        XCTAssertEqual(receivedUpperBounds, [1, 1, 1])
    }

    func test_jittered_backoff_is_capped_at_maximum() {
        let backoff = jitteredBackoff(initialDelay: 1, maximum: 20)
        _ = backoff.calculate(4)
        _ = backoff.calculate(5)
        XCTAssertEqual(backoff.calculate(1000), 20)
        XCTAssertEqual(backoff.calculate(Int.max), 20)
        XCTAssertEqual(receivedLowerBounds, [0, 0, 0, 0])
        XCTAssertEqual(receivedUpperBounds, [16, 20, 20, 20])
    }

    /// Unlike the legacy implementation, `random` is not invoked at all when the upper bound is 0.
    func test_jittered_backoff_clamps_negative_delays_to_zero_without_calling_random() {
        let backoff = jitteredBackoff(initialDelay: -1, maximum: -5)
        XCTAssertEqual(backoff.calculate(1), 0)
        XCTAssertEqual(receivedLowerBounds, [])
        XCTAssertEqual(receivedUpperBounds, [])
    }

    func test_jittered_backoff_default_random_source_stays_within_bounds() {
        let backoff = Backoff.jitteredExponential(initialDelay: 1, maximum: 20)
        for retryCount in 0...9 {
            let upper = min(20, pow(2, Double(retryCount)))
            let delay = backoff.calculate(retryCount)
            XCTAssertGreaterThanOrEqual(delay, 0)
            XCTAssertLessThanOrEqual(delay, upper)
        }
    }

    func test_jittered_backoff_does_not_call_random_when_upper_bound_is_zero() {
        let backoff = jitteredBackoff(initialDelay: 0, maximum: 20)
        XCTAssertEqual(backoff.calculate(0), 0)
        XCTAssertEqual(receivedLowerBounds, [])
        XCTAssertEqual(receivedUpperBounds, [])
    }

    // MARK: - exponential

    func test_exponential_matches_legacy_default_configuration() {
        let backoff = Backoff.exponential(initialDelay: 2, maximum: 150)
        let expected: [TimeInterval] = [2, 4, 8, 16, 32, 64, 128, 150, 150]
        for (index, expectedDelay) in expected.enumerated() {
            XCTAssertEqual(backoff.calculate(index), expectedDelay)
        }
        XCTAssertEqual(backoff.calculate(-3), 2)
        XCTAssertEqual(backoff.calculate(Int.max), 150)
    }

    func test_exponential_never_returns_a_non_finite_or_negative_value() {
        let hugeMultiplierFiniteMaximum = Backoff.exponential(initialDelay: 2, multiplier: .greatestFiniteMagnitude, maximum: 150)
        XCTAssertEqual(hugeMultiplierFiniteMaximum.calculate(4), 150)

        let hugeMultiplierInfiniteMaximum = Backoff.exponential(initialDelay: 2, multiplier: .greatestFiniteMagnitude, maximum: .infinity)
        XCTAssertEqual(hugeMultiplierInfiniteMaximum.calculate(4), .greatestFiniteMagnitude)

        let nanInitialDelay = Backoff.exponential(initialDelay: .nan, maximum: 150)
        XCTAssertEqual(nanInitialDelay.calculate(0), 0)

        let negativeMaximum = Backoff.exponential(initialDelay: 2, maximum: -10)
        XCTAssertEqual(negativeMaximum.calculate(0), 0)
    }

    // MARK: - map

    func test_map_identity_law() {
        let backoff = Backoff.exponential(initialDelay: 2, maximum: 150)
        // swiftlint:disable:next array_init
        let mapped = backoff.map { delay in delay }
        for retryCount in 0...10 {
            XCTAssertEqual(mapped.calculate(retryCount), backoff.calculate(retryCount))
        }
    }

    func test_map_composition_law() {
        let backoff = Backoff.exponential(initialDelay: 2, maximum: 150)
        let double: (TimeInterval) -> TimeInterval = { $0 * 2 }
        let addOne: (TimeInterval) -> TimeInterval = { $0 + 1 }
        let composed = backoff.map(double).map(addOne)
        let combined = backoff.map { addOne(double($0)) }
        for retryCount in 0...10 {
            XCTAssertEqual(composed.calculate(retryCount), combined.calculate(retryCount))
        }
    }

    func test_map_applies_transformation_to_result() {
        let backoff = Backoff.retryCount
        let mapped = backoff.map { $0 * 10 }
        for retryCount in 0...10 {
            XCTAssertEqual(mapped.calculate(retryCount), Double(retryCount) * 10)
        }
    }
}
