//
//  OperatorsTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 13/07/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import XCTest
@testable import tealium_swift

final class OperatorsTests: XCTestCase {
    
    let observable123 = TealiumObservable.Just(1, 2, 3)
    
    func test_map_transforms_events() {
        let expectations = [
            expectation(description: "Event 1*10 is transformed"),
            expectation(description: "Event 2*10 is transformed"),
            expectation(description: "Event 3*10 is transformed")
        ]
        _ = observable123.map { $0*10 }
            .subscribe { event in
                if event == 10 {
                    expectations[0].fulfill()
                } else if event == 20 {
                    expectations[1].fulfill()
                } else if event == 30 {
                    expectations[2].fulfill()
                }
            }
        
        wait(for: expectations, timeout: 2.0, enforceOrder: true)
    }
    
    func test_map_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = TealiumPublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: TealiumObservable<Int> = observable.map { $0*10 }
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        pub.publish(1)
        helper?.subscription?.dispose()
        helper = nil
        waitForExpectations(timeout: 2.0)
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
                return number*10
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
        wait(for: expectations, timeout: 2.0, enforceOrder: true)
    }
    
    func test_compactMap_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = TealiumPublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: TealiumObservable<Int> = observable.compactMap { $0*10 }
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        pub.publish(1)
        helper?.subscription?.dispose()
        helper = nil
        waitForExpectations(timeout: 2.0)
    }
    
    func test_filter_removes_events() {
        let expectations = [
            expectation(description: "Event 1 is reported"),
            expectation(description: "Event 2 is not reported"),
            expectation(description: "Event 3 is reported")
        ]
        expectations[1].isInverted = true
        _ = observable123.filter { $0 != 2 }
            .subscribe { event in
                if event == 1 {
                    expectations[0].fulfill()
                } else if event == 2 {
                    expectations[1].fulfill()
                } else if event == 3 {
                    expectations[2].fulfill()
                }
            }
        wait(for: expectations, timeout: 2.0, enforceOrder: true)
    }
    
    func test_filter_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = TealiumPublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: TealiumObservable<Int> = observable.filter { $0 != 2 }
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        pub.publish(1)
        pub.publish(2)
        helper?.subscription?.dispose()
        helper = nil
        waitForExpectations(timeout: 2.0)
    }
    func test_subscribeOn_subscribes_on_provided_queue() {
        let expectation = expectation(description: "Subscribe handler is called")
        let queue = DispatchQueue(label: "ObservableTestQueue")
        let observable = TealiumObservableCreate<Void> { observer in
            dispatchPrecondition(condition: .onQueue(queue))
            expectation.fulfill()
            return TealiumSubscription { }
        }
        _ = observable.subscribeOn(queue)
            .subscribe { }
        queue.sync {
            waitForExpectations(timeout: 2.0)
        }
    }
    
    func test_subscribeOn_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = TealiumPublisher<Int>()
        let observable = pub.asObservable()
        let queue = DispatchQueue(label: "ObservableTestQueue")
        let generatedObservable: TealiumObservable<Int> = observable.subscribeOn(queue)
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        queue.sync {
            pub.publish(1)
        }
        helper?.subscription?.dispose()
        helper = nil
        queue.sync {
            waitForExpectations(timeout: 2.0)
        }
    }
    
    func test_observeOn_observes_on_provided_queue() {
        let expectation = expectation(description: "Observer is called")
        expectation.assertForOverFulfill = false
        let queue = DispatchQueue(label: "ObservableTestQueue")
        _ = observable123.observeOn(queue)
            .subscribe { _ in
                dispatchPrecondition(condition: .onQueue(queue))
                expectation.fulfill()
            }
        queue.sync {
            waitForExpectations(timeout: 2.0)
        }
    }
    
    func test_observeOn_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = TealiumPublisher<Int>()
        let observable = pub.asObservable()
        let queue = DispatchQueue(label: "ObservableTestQueue")
        let generatedObservable: TealiumObservable<Int> = observable.observeOn(queue)
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        pub.publish(1)
        queue.sync {
            helper?.subscription?.dispose()
            helper = nil
            waitForExpectations(timeout: 2.0)
        }
    }
    
    func test_flatMap_returns_new_observables_flattening_it() {
        let flatMappedEventIsCalled = expectation(description: "FlatMapped event is called 3 times")
        flatMappedEventIsCalled.expectedFulfillmentCount = 3
        _ = observable123.flatMap { integer in
            TealiumObservable.Just("flatMapped")
        }.subscribe { event in
            XCTAssertEqual(event, "flatMapped")
            flatMappedEventIsCalled.fulfill()
        }
        waitForExpectations(timeout: 5)
    }
    
    func test_flatMap_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = TealiumPublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: TealiumObservable<Int> = observable.flatMap { _ in TealiumObservable.Just(2) }
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        pub.publish(1)
        helper?.subscription?.dispose()
        helper = nil
        waitForExpectations(timeout: 2.0)
    }
    
    func test_start_with_prefixes_the_events_with_provided_events() {
        let expectations = [
                expectation(description: "Event 0 is reported"),
                expectation(description: "Event 1 is reported"),
                expectation(description: "Event 2 is reported"),
                expectation(description: "Event 3 is reported")
        ]
        _ = observable123.startWith(0)
            .subscribe { number in
                expectations[number].fulfill()
            }
        wait(for: expectations, timeout: 2.0, enforceOrder: true)
    }
    
    func test_startWith_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = TealiumPublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: TealiumObservable<Int> = observable.startWith(0)
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        pub.publish(1)
        helper?.subscription?.dispose()
        helper = nil
        waitForExpectations(timeout: 2.0)
    }
    
    func test_merge_publishes_events_of_both_observables() {
        let expectations = [
            expectation(description: "Event 0 is published"),
            expectation(description: "Event 1 is published"),
            expectation(description: "Event 2 is published"),
            expectation(description: "Event 3 is published"),
            expectation(description: "Event 4 is published")
        ]
        let pub1 = TealiumPublisher<Int>()
        let pub2 = TealiumPublisher<Int>()
        
        _ = pub1.asObservable()
            .merge(pub2.asObservable())
            .subscribe { number in
                expectations[number].fulfill()
            }
        pub1.publish(0)
        pub2.publish(1)
        pub2.publish(2)
        pub1.publish(3)
        pub2.publish(4)
        wait(for: expectations, timeout: 2.0, enforceOrder: true)
    }
    
    func test_merge_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = TealiumPublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: TealiumObservable<Int> = observable.merge(TealiumObservable.Just(2))
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        pub.publish(1)
        helper?.subscription?.dispose()
        helper = nil
        waitForExpectations(timeout: 2.0)
    }
    
    func test_first_returns_only_first_event() {
        let expectation = expectation(description: "Only first event is reported")
        _ = observable123.first()
            .subscribe { _ in
                expectation.fulfill()
            }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func test_first_returns_only_first_event_that_is_included() {
        let expectation = expectation(description: "Only first event is reported")
        _ = observable123.first { $0 == 2}
            .subscribe { number in
                XCTAssertEqual(number, 2)
                expectation.fulfill()
            }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func test_first_disposes_subscription_after_the_event_is_reported() {
        let expectation = expectation(description: "Only first event is reported")
        let subscription = observable123.first()
            .subscribe { _ in
                expectation.fulfill()
            }
        XCTAssertTrue(subscription.isDisposed)
        waitForExpectations(timeout: 2.0)
    }
    
    func test_first_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = TealiumPublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: TealiumObservable<Int> = observable.first()
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        helper?.subscription?.dispose()
        helper = nil
        waitForExpectations(timeout: 2.0)
    }
    
    func test_first_cleans_retain_cycles_after_first_event() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = TealiumPublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: TealiumObservable<Int> = observable.first()
        _ = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        pub.publish(1)
        waitForExpectations(timeout: 2.0)
    }
    
    func test_combineLatest_doesnt_send_event_if_first_has_provided_no_events() {
        let expectation = expectation(description: "CombineLatest doesn't provide event")
        expectation.isInverted = true
        let pub1 = TealiumPublisher<Int>()
        let pub2 = TealiumPublisher<String>()
        
        _ = pub1.asObservable()
            .combineLatest(pub2.asObservable())
            .subscribe { (number, string) in
                expectation.fulfill()
            }
        pub1.publish(1)
        waitForExpectations(timeout: 2.0)
    }
    
    func test_combineLatest_doesnt_send_event_if_second_has_provided_no_events() {
        let expectation = expectation(description: "CombineLatest doesn't provide event")
        expectation.isInverted = true
        let pub1 = TealiumPublisher<Int>()
        let pub2 = TealiumPublisher<String>()
        
        _ = pub1.asObservable()
            .combineLatest(pub2.asObservable())
            .subscribe { (number, string) in
                expectation.fulfill()
            }
        pub2.publish("a")
        waitForExpectations(timeout: 2.0)
    }
    
    func test_combineLatest_sends_event_if_both_provided_an_event() {
        let expectation = expectation(description: "CombineLatest provides an event")
        let pub1 = TealiumPublisher<Int>()
        let pub2 = TealiumPublisher<String>()
        
        _ = pub1.asObservable()
            .combineLatest(pub2.asObservable())
            .subscribe { (number, string) in
                expectation.fulfill()
            }
        pub1.publish(1)
        pub2.publish("a")
        waitForExpectations(timeout: 2.0)
    }
    
    func test_combineLatest_after_first_sends_events_at_each_event_from_both_observables() {
        let expectations = [
            expectation(description: "CombineLatest provides event (1, a)"),
            expectation(description: "CombineLatest provides event (2, a)"),
            expectation(description: "CombineLatest provides event (2, b)"),
            expectation(description: "CombineLatest provides no other events")
            ]
        expectations[3].isInverted = true
        let pub1 = TealiumPublisher<Int>()
        let pub2 = TealiumPublisher<String>()
        
        _ = pub1.asObservable()
            .combineLatest(pub2.asObservable())
            .subscribe { (number, string) in
                switch (number, string) {
                case (1, "a"):
                    expectations[0].fulfill()
                case (2, "a"):
                    expectations[1].fulfill()
                case (2, "b"):
                    expectations[2].fulfill()
                default:
                    expectations[3].fulfill()
                }
            }
        pub1.publish(1)
        pub2.publish("a")
        pub1.publish(2)
        pub2.publish("b")
        wait(for: expectations, timeout: 2.0, enforceOrder: true)
    }
    
    func test_combineLatest_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = TealiumPublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: TealiumObservable<(Int, String)> = observable.combineLatest(TealiumObservable.Just("a"))
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        pub.publish(1)
        helper?.subscription?.dispose()
        helper = nil
        waitForExpectations(timeout: 2.0)
    }
    
    func test_distinct_only_provides_different_events() {
        let expectations = [
            expectation(description: "Event 0 is provided"),
            expectation(description: "Event 1 is provided"),
            expectation(description: "Event 2 is provided"),
        ]
        let observable = TealiumObservable.Just(0, 0, 0, 0, 0, 1, 1, 2)
        _ = observable.distinct()
            .subscribe { number in
                expectations[number].fulfill()
            }
        
        wait(for: expectations, timeout: 2.0, enforceOrder: true)
    }
    
    func test_distinct_subscription_dispose_cleans_retain_cycles() {
        let expectation = expectation(description: "Retain Cycle removed")
        let pub = TealiumPublisher<Int>()
        let observable = pub.asObservable()
        let generatedObservable: TealiumObservable<Int> = observable.distinct()
        var helper: SubscriptionRetainCycleHelper? = SubscriptionRetainCycleHelper(publisher: generatedObservable, onDeinit: {
            expectation.fulfill()
        })
        pub.publish(1)
        pub.publish(1)
        pub.publish(2)
        helper?.subscription?.dispose()
        helper = nil
        waitForExpectations(timeout: 2.0)
    }
}
