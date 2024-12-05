//
//  DataLayerWrapper+TransactionallyTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 13/11/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class DataLayerWrapperTransactionallyTests: BaseDataLayerWrapperTests {
    func test_callback_is_called_on_the_right_queue() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        wrapper.transactionally { _, _, _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_apply_put_does_nothing_without_commit() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        let getCompleted = expectation(description: "Get callback is called")
        wrapper.transactionally { apply, _, _ in
            apply(.put("key", "value", .forever))
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        wrapper.getDataItem(key: "key") { item in
            XCTAssertNil(item)
            getCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_apply_put_does_nothing_after_commit() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        let getCompleted = expectation(description: "Get callback is called")
        wrapper.transactionally { apply, _, commit in
            try? commit()
            apply(.put("key", "value", .forever))
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        wrapper.getDataItem(key: "key") { item in
            XCTAssertNil(item)
            getCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_apply_remove_does_nothing_without_commit() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        let getCompleted = expectation(description: "Get callback is called")
        wrapper.put(key: "key", value: "value")
        wrapper.transactionally { apply, _, _ in
            apply(.remove("key"))
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        wrapper.get(key: "key") { item in
            XCTAssertEqual(item, "value")
            getCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_apply_remove_does_nothing_after_commit() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        let getCompleted = expectation(description: "Get callback is called")
        wrapper.put(key: "key", value: "value")
        wrapper.transactionally { apply, _, commit in
            try? commit()
            apply(.remove("key"))
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        wrapper.get(key: "key") { item in
            XCTAssertEqual(item, "value")
            getCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_commit_completes_the_transaction_for_previous_apply_put() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        let getCompleted = expectation(description: "Get callback is called")
        wrapper.transactionally { apply, _, commit in
            apply(.put("key", "value", .forever))
            try? commit()
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        wrapper.get(key: "key") { item in
            XCTAssertEqual(item, "value")
            getCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_commit_completes_the_transaction_for_previous_apply_remove() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        let getCompleted = expectation(description: "Get callback is called")
        wrapper.put(key: "key", value: "value")
        wrapper.transactionally { apply, _, commit in
            apply(.remove("key"))
            try? commit()
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        wrapper.getDataItem(key: "key") { item in
            XCTAssertNil(item)
            getCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_getDataItem_returns_data_already_present_in_the_dataLayer() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        wrapper.put(key: "key", value: "value")
        wrapper.transactionally { _, getDataItem, _ in
            XCTAssertEqual(getDataItem("key")?.get(), "value")
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_getDataItem_returns_data_added_by_previous_commit() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        wrapper.transactionally { apply, getDataItem, commit in
            apply(.put("key", "value", .forever))
            try? commit()
            XCTAssertEqual(getDataItem("key")?.get(), "value")
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_getDataItem_returns_nil_for_value_not_committed_yet() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        wrapper.transactionally { apply, getDataItem, commit in
            apply(.put("key", "value", .forever))
            XCTAssertNil(getDataItem("key"))
            try? commit()
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_getDataItem_returns_data_already_present_in_the_dataLayer_before_committing_a_remove() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        wrapper.put(key: "key", value: "value")
        wrapper.transactionally { apply, getDataItem, commit in
            apply(.remove("key"))
            XCTAssertEqual(getDataItem("key")?.get(), "value")
            try? commit()
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_getDataItem_returns_nil_after_committing_a_remove() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        wrapper.put(key: "key", value: "value")
        wrapper.transactionally { apply, getDataItem, commit in
            apply(.remove("key"))
            try? commit()
            XCTAssertNil(getDataItem("key"))
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_commit_again_in_same_transaction_block_does_nothing() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        let getCompleted = expectation(description: "Get callback is called")
        wrapper.transactionally { apply, _, commit in
            apply(.put("key", "value", .forever))
            try? commit()
            apply(.put("key", "value2", .forever))
            try? commit()
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        wrapper.get(key: "key") { item in
            XCTAssertEqual(item, "value")
            getCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }
}
