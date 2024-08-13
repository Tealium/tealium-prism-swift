//
//  TealiumDispatchGroupTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 27/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TealiumDispatchGroupTests: XCTestCase {
    let queue = DispatchQueue(label: "test.queue")
    lazy var group = TealiumDispatchGroup(queue: queue)

    func test_completion_is_called_on_provided_queue() {
        let parallelExecutionCompletes = expectation(description: "Parallel execution completes")
        group.parallelExecution([
            { completion in
                DispatchQueue.main.async {
                    completion(())
                }
            }
        ]) { _ in
            dispatchPrecondition(condition: .onQueue(self.queue))
            parallelExecutionCompletes.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func test_completion_is_called_with_results_in_provided_order() {
        let parallelExecutionCompletes = expectation(description: "Parallel execution completes")
        group.parallelExecution([
            { completion in
                DispatchQueue.main.async {
                    completion(1)
                }
            },
            { completion in
                completion(2)
            }
        ]) { results in
            XCTAssertEqual(results, [1, 2])
            parallelExecutionCompletes.fulfill()
        }
        waitForExpectations(timeout: 1.0)
    }

    func test_completion_is_called_after_all_have_completed() {
        let firstWorkCompleted = expectation(description: "First execution completes")
        let secondWorkCompleted = expectation(description: "Second execution completes")
        let parallelExecutionCompletes = expectation(description: "Parallel execution completes")
        group.parallelExecution([
            { completion in
                firstWorkCompleted.fulfill()
                completion(1)
            },
            { completion in
                DispatchQueue.main.async {
                    secondWorkCompleted.fulfill()
                    completion(2)
                }
            }
        ]) { results in
            XCTAssertEqual(results, [1, 2])
            parallelExecutionCompletes.fulfill()
        }
        wait(for: [firstWorkCompleted, secondWorkCompleted, parallelExecutionCompletes], enforceOrder: true)
    }
}
