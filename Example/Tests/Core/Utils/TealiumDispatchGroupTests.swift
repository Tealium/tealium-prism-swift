//
//  TealiumDispatchGroupTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 27/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class TealiumDispatchGroupTests: XCTestCase {
    let queue = TealiumQueue(label: "test.queue")
    lazy var group = TealiumDispatchGroup(queue: queue)

    func test_completion_is_called_on_provided_queue() {
        let parallelExecutionCompletes = expectation(description: "Parallel execution completes")
        _ = group.parallelExecution([
            { completion in
                DispatchQueue.main.async {
                    completion(())
                }
                return Disposables.disposed()
            }
        ]) { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            parallelExecutionCompletes.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_completion_is_called_with_results_in_provided_order() {
        let parallelExecutionCompletes = expectation(description: "Parallel execution completes")
        _ = group.parallelExecution([
            { completion in
                DispatchQueue.main.async {
                    completion(1)
                }
                return Disposables.disposed()
            },
            { completion in
                completion(2)
                return Disposables.disposed()
            }
        ]) { results in
            XCTAssertEqual(results, [1, 2])
            parallelExecutionCompletes.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_dispose_prevents_completion_from_being_called() {
        let parallelExecutionCompletes = expectation(description: "Parallel execution completes")
        parallelExecutionCompletes.isInverted = true

        let disposable = group.parallelExecution([
            { (completion: @escaping (Int) -> Void) -> any Disposable in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    completion(1)
                }
                return Disposables.disposed()
            }
        ]) { _ in
            parallelExecutionCompletes.fulfill()
        }

        disposable.dispose()
        waitForDefaultTimeout()
    }

    func test_dispose_during_inflight_work_does_not_crash() {
        let allWorksStarted = expectation(description: "All works started")
        allWorksStarted.expectedFulfillmentCount = 3

        let disposable = group.parallelExecution([
            { completion in
                allWorksStarted.fulfill()
                completion(1)
                return Disposables.disposed()
            },
            { completion in
                allWorksStarted.fulfill()
                completion(2)
                return Disposables.disposed()
            },
            { completion in
                allWorksStarted.fulfill()
                completion(3)
                return Disposables.disposed()
            }
        ]) { _ in }

        // Dispose while work items may still be completing.
        disposable.dispose()
        wait(for: [allWorksStarted], timeout: 1)
    }

    func test_completion_is_called_after_all_have_completed() {
        let firstWorkCompleted = expectation(description: "First execution completes")
        let secondWorkCompleted = expectation(description: "Second execution completes")
        let parallelExecutionCompletes = expectation(description: "Parallel execution completes")
        _ = group.parallelExecution([
            { completion in
                firstWorkCompleted.fulfill()
                completion(1)
                return Disposables.disposed()
            },
            { completion in
                DispatchQueue.main.async {
                    secondWorkCompleted.fulfill()
                    completion(2)
                }
                return Disposables.disposed()
            }
        ]) { results in
            XCTAssertEqual(results, [1, 2])
            parallelExecutionCompletes.fulfill()
        }
        wait(for: [firstWorkCompleted, secondWorkCompleted, parallelExecutionCompletes], enforceOrder: true)
    }

    func test_completion_clears_resources_when_disposed() {
        let resourcesCleared = expectation(description: "Resources cleared")
        weak var weakTester: DeinitTester?

        // Keep a strong ref to completion only while setting up.
        var completion: (([Int]) -> Void)?

        do {
            let tester = DeinitTester {
                resourcesCleared.fulfill()
            }
            weakTester = tester

            // completion holds tester strongly; if completion is released,
            // tester will deinit and fulfill the expectation.
            completion = { _ in
                _ = tester
            }

            // A "work" that never calls its callback; group will be drained
            // via the Subscription in parallelExecution when we dispose.
            let works: [(@escaping (Int) -> Void) -> any Disposable] = [
                { _ in Disposables.disposed() }
            ]

            // sut = whatever owns `parallelExecution`, with a serial queue
            // swiftlint:disable:next force_unwrapping
            let disposable = group.parallelExecution(works, completion: completion!)

            // Cancellation path: this should eventually cause all
            // SelfDestructingCompletion instances to call `leave()`.
            disposable.dispose()

            // Drop our own reference so only the group's `notify` closure
            // can be holding onto `completion` (and thus `probe`).
            completion = nil
        }
        waitForLongTimeout()
        XCTAssertNil(weakTester)
    }
}
