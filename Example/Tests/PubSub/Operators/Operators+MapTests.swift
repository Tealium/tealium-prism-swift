//
//  Operators+MapTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 13/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class OperatorsMapTests: XCTestCase {

    let observable123 = TealiumObservable.Just(1, 2, 3)

    func test_map_transforms_events() {
        let expectations = [
            expectation(description: "Event 1*10 is transformed"),
            expectation(description: "Event 2*10 is transformed"),
            expectation(description: "Event 3*10 is transformed")
        ]
        _ = observable123.map { $0 * 10 }
            .subscribe { event in
                if event == 10 {
                    expectations[0].fulfill()
                } else if event == 20 {
                    expectations[1].fulfill()
                } else if event == 30 {
                    expectations[2].fulfill()
                }
            }
        wait(for: expectations, timeout: 1.0, enforceOrder: true)
    }

    func test_map_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = TealiumPublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: TealiumObservable<Int> = observable.map { $0 * 10 }
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        pub.publish(1)
        helper?.subscription?.dispose()
        helper = nil
        waitForExpectations(timeout: 1.0)
    }

    func test_compactMap_transforms_events_and_removes_nils() {
        let expectations = [
            expectation(description: "Event 1*10 is transformed"),
            expectation(description: "Event 3*10 is transformed"),
            expectation(description: "Event nil is removed")
        ]
        expectations[2].isInverted = true
        let observable = TealiumObservable.Just(1, nil, 3)
        _ = observable
            .compactMap({ (number: Int?) -> Int? in
                guard let number = number else { return nil }
                return number * 10
            })
            .subscribe { event in
                if event == 10 {
                    expectations[0].fulfill()
                } else if event == 30 {
                    expectations[1].fulfill()
                } else {
                    expectations[2].fulfill()
                }
            }
        wait(for: expectations, timeout: 1.0, enforceOrder: true)
    }

    func test_compactMap_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = TealiumPublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: TealiumObservable<Int> = observable.compactMap { $0 * 10 }
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        pub.publish(1)
        helper?.subscription?.dispose()
        helper = nil
        waitForExpectations(timeout: 1.0)
    }
}
