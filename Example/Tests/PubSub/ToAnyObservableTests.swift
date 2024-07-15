//
//  ToAnyObservableTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 01/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

class ToAnyObservableTests: XCTestCase {

    @ToAnyObservable(BasePublisher<Int>())
    public var publisherObservable: Observable<Int>

    @ToAnyObservable(BaseSubject<Int>())
    var subjectObservable: Observable<Int>

    @ToAnyObservable(ReplaySubject<Int>())
    var replayObservable: Observable<Int>

    @ToAnyObservable(BufferedSubject<Int>())
    var bufferedObservable: Observable<Int>

    func test_PublisherPropertyWrapper_notifies_events() {
        let eventNotified = expectation(description: "Event is notified")
        let value = 2
        _ = publisherObservable.subscribe { val in
            XCTAssertEqual(val, value)
            eventNotified.fulfill()
        }
        _publisherObservable.publish(value)

        waitForExpectations(timeout: 2.0)
    }

    func test_SubjectPropertyWrapper_notifies_events() {
        let eventNotified = expectation(description: "Event is notified")
        let value = 2
        _ = subjectObservable.subscribe { val in
            XCTAssertEqual(val, value)
            eventNotified.fulfill()
        }
        _subjectObservable.publish(value)
        waitForExpectations(timeout: 2.0)
    }

    func test_ReplaySubjectPropertyWrapper_notifies_events() {
        let eventNotified = expectation(description: "Event is notified")
        let value = 2
        _ = replayObservable.subscribe { val in
            XCTAssertEqual(val, value)
            eventNotified.fulfill()
        }
        _replayObservable.publish(value)
        waitForExpectations(timeout: 2.0)
    }

    func test_BufferedSubjectPropertyWrapper_notifies_events() {
        let eventNotified = expectation(description: "Event is notified")
        let value = 2
        _ = bufferedObservable.subscribe { val in
            XCTAssertEqual(val, value)
            eventNotified.fulfill()
        }
        _bufferedObservable.publish(value)
        waitForExpectations(timeout: 2.0)
    }

}
