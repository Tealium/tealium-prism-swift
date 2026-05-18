//
//  SubjectPropertyWrapperTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 01/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

class SubjectPropertyWrapperTests: XCTestCase {

    @Subject<Int> var subjectObservable

    @ReplaySubject<Int> var replayObservable

    @StateSubject<Int>(1)
    var stateObservable

    func test_SubjectPropertyWrapper_notifies_events() {
        let eventNotified = expectation(description: "Event emitted after subscription is notified")
        _subjectObservable.onNext(1)
        _ = subjectObservable.subscribe { val in
            XCTAssertEqual(val, 2)
            eventNotified.fulfill()
        }
        _subjectObservable.onNext(2)
        waitForDefaultTimeout()
    }

    func test_ReplaySubjectPropertyWrapper_notifies_events() {
        let eventNotified = expectation(description: "Event is notified both for before and after subscription")
        eventNotified.expectedFulfillmentCount = 2
        var count = 1
        _replayObservable.onNext(1)
        _ = replayObservable.subscribe { val in
            XCTAssertEqual(val, count)
            count += 1
            eventNotified.fulfill()
        }
        _replayObservable.onNext(2)
        waitForDefaultTimeout()
    }

    func test_StateSubjectPropertyWrapper_notifies_events() {
        let eventNotified = expectation(description: "Event is notified both for before and after subscription")
        eventNotified.expectedFulfillmentCount = 2
        var count = 1
        _ = stateObservable.subscribe { val in
            XCTAssertEqual(val, count)
            count += 1
            eventNotified.fulfill()
        }
        _stateObservable.onNext(2)
        waitForDefaultTimeout()
    }

}
