//
//  Operators+IgnoreTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 21/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import TealiumPrism
import XCTest

final class OperatorsIgnoreTests: XCTestCase {
    func test_ignoreN_ignores_first_N_events() {
        let expectation = expectation(description: "4th event received")
        let sub = ReplaySubject(0)
        let observable = sub.asObservable()
        observable.ignore(3)
            .subscribeOnce { element in
                if element == 3 {
                    expectation.fulfill()
                }
            }
        sub.publish(1)
        sub.publish(2)
        sub.publish(3)
        waitForDefaultTimeout()
    }

    func test_ignore_does_not_emit_subsequent_synchronous_event_after_observer_side_effect_disposal() {
        assertNoEmissionAfterSideEffectDisposal(
            upstreamValues: [0, 1, 2],
            applyOperator: { $0.ignore(1) }
        )
    }

    func test_ignore_forwards_onComplete_when_upstream_completes_before_count_is_reached() {
        let emissionsReceived = expectation(description: "No emissions are received")
        emissionsReceived.isInverted = true
        let completed = expectation(description: "Downstream receives onComplete")
        _ = Observables.just(1, 2)
            .ignore(5)
            .subscribe { _ in
                emissionsReceived.fulfill()
            } onComplete: {
                completed.fulfill()
            }
        waitForDefaultTimeout()
    }

    func test_ignore_forwards_onComplete_after_emitting_remaining_elements() {
        let emissionsReceived = expectation(description: "Third element is emitted")
        let completed = expectation(description: "Downstream receives onComplete")
        var received: [Int] = []
        _ = Observables.just(1, 2, 3)
            .ignore(2)
            .subscribe { element in
                received.append(element)
                emissionsReceived.fulfill()
            } onComplete: {
                completed.fulfill()
            }
        wait(for: [emissionsReceived, completed], timeout: Self.defaultTimeout, enforceOrder: true)
        XCTAssertEqual(received, [3])
    }
}
