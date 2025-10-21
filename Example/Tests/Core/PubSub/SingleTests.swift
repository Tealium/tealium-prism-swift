//
//  SingleTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 10/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class SingleTests: XCTestCase {

    func test_emits_only_first_event_of_underlying_observable() {
        let observerCalled = expectation(description: "Observer called")
        let publisher = BasePublisher<Int>()
        let single = SingleImpl<Int>(observable: publisher.asObservable(),
                                     queue: .main)
        _ = single.subscribe { number in
            dispatchPrecondition(condition: .onQueue(.main))
            XCTAssertEqual(number, 1)
            observerCalled.fulfill()
        }
        publisher.publish(1)
        publisher.publish(2)

        waitForDefaultTimeout()
    }

    func test_emits_events_on_given_queue() {
        let observerCalled = expectation(description: "Observer called")
        let publisher = BasePublisher<Int>()
        let queue = TealiumQueue.worker
        let single = SingleImpl<Int>(observable: publisher.asObservable(),
                                     queue: queue)
        _ = single.subscribe { _ in
            dispatchPrecondition(condition: .onQueue(queue.dispatchQueue))
            observerCalled.fulfill()
        }

        queue.dispatchQueue.sync {
            publisher.publish(1)
            waitForDefaultTimeout()
        }
    }

    func test_onSuccess_is_called_when_result_is_successful() {
        let observerCalled = expectation(description: "Observer called")
        let single = SingleImpl<Result<Int, Error>>(observable: Observables.just(.success(1)),
                                                    queue: .main)

        _ = single.onSuccess { value in
            XCTAssertEqual(value, 1)
            observerCalled.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_onSuccess_is_not_called_when_result_is_unsuccessful() {
        let observerCalled = expectation(description: "Observer called")
        observerCalled.isInverted = true
        let single = SingleImpl<Result<Int, Error>>(observable: Observables.just(.failure(TealiumError.genericError("Failed"))),
                                                    queue: .main)

        _ = single.onSuccess { _ in
            observerCalled.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_onFailure_is_called_when_result_is_unsuccessful() {
        let observerCalled = expectation(description: "Observer called")
        let single = SingleImpl<Result<Int, Error>>(observable: Observables.just(.failure(TealiumError.genericError("Failed"))),
                                                    queue: .main)

        _ = single.onFailure { error in
            guard case let .genericError(message) = error as? TealiumError else {
                XCTFail("Unexpected error: \(error)")
                return
            }
            XCTAssertEqual(message, "Failed")
            observerCalled.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_onFailure_is_not_called_when_result_is_successful() {
        let observerCalled = expectation(description: "Observer called")
        observerCalled.isInverted = true
        let single = SingleImpl<Result<Int, Error>>(observable: Observables.just(.success(1)),
                                                    queue: .main)

        _ = single.onFailure { _ in
            observerCalled.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_toAsync_returns_item_when_successful() async throws {
        let single = SingleImpl<Result<Int, Error>>(observable: Observables.just(.success(1)),
                                                    queue: .main)

        let item = try await single.toAsync()
        XCTAssertEqual(item, 1)
    }

    func test_toAsync_throws_error_when_unsuccessful() async throws {
        let single = SingleImpl<Result<Int, Error>>(observable: Observables.just(.failure(TealiumError.genericError("Failed"))),
                                                    queue: .main)
        do {
            _ = try await single.toAsync()
            XCTFail("Expected to throw")
        } catch {
            guard case let .genericError(message) = error as? TealiumError else {
                XCTFail("Unexpected error \(error)")
                return
            }
            XCTAssertEqual(message, "Failed")
        }
    }
}
