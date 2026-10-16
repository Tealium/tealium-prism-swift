//
//  DataLayerWrapper+TransactionallyTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 13/11/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class DataLayerWrapperTransactionallyTests: BaseDataLayerWrapperTests {
    func test_callback_is_called_on_the_right_queue() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        wrapper.transactionally { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_apply_put_does_nothing_without_commit() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        let getCompleted = expectation(description: "Get callback is called")
        wrapper.transactionally { transaction in
            transaction.apply(.put(key: "key", value: "value", expiry: .forever))
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        wrapper.getDataItem(key: "key").onSuccess { item in
            XCTAssertNil(item)
            getCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_apply_put_does_nothing_after_commit() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        let getCompleted = expectation(description: "Get callback is called")
        wrapper.transactionally { transaction in
            try transaction.commit()
            transaction.apply(.put(key: "key", value: "value", expiry: .forever))
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        wrapper.getDataItem(key: "key").onSuccess { item in
            XCTAssertNil(item)
            getCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_commit_with_no_edits_seals_the_transaction() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        let getCompleted = expectation(description: "Get callback is called")
        wrapper.transactionally { transaction in
            try transaction.commit()
            transaction.put(key: "key", value: "value", expiry: .forever)
            try transaction.commit()
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        wrapper.getDataItem(key: "key").onSuccess { item in
            XCTAssertNil(item)
            getCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_apply_remove_does_nothing_without_commit() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        let getCompleted = expectation(description: "Get callback is called")
        wrapper.put(key: "key", value: "value")
        wrapper.transactionally { transaction in
            transaction.apply(.remove(key: "key"))
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        wrapper.get(key: "key", as: String.self).onSuccess { item in
            XCTAssertEqual(item, "value")
            getCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_apply_remove_does_nothing_after_commit() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        let getCompleted = expectation(description: "Get callback is called")
        wrapper.put(key: "key", value: "value")
        wrapper.transactionally { transaction in
            try transaction.commit()
            transaction.apply(.remove(key: "key"))
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        wrapper.get(key: "key", as: String.self).onSuccess { item in
            XCTAssertEqual(item, "value")
            getCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_commit_completes_the_transaction_for_previous_apply_put() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        let getCompleted = expectation(description: "Get callback is called")
        wrapper.transactionally { transaction in
            transaction.apply(.put(key: "key", value: "value", expiry: .forever))
            try transaction.commit()
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        wrapper.get(key: "key", as: String.self).onSuccess { item in
            XCTAssertEqual(item, "value")
            getCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_commit_completes_the_transaction_for_previous_apply_remove() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        let getCompleted = expectation(description: "Get callback is called")
        wrapper.put(key: "key", value: "value")
        wrapper.transactionally { transaction in
            transaction.apply(.remove(key: "key"))
            try transaction.commit()
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        wrapper.getDataItem(key: "key").onSuccess { item in
            XCTAssertNil(item)
            getCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_getDataItem_returns_data_already_present_in_the_dataLayer() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        wrapper.put(key: "key", value: "value")
        wrapper.transactionally { transaction in
            XCTAssertEqual(transaction.getDataItem(key: "key")?.get(), "value")
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_getDataItem_returns_data_added_by_previous_commit() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        wrapper.transactionally { transaction in
            transaction.apply(.put(key: "key", value: "value", expiry: .forever))
            try transaction.commit()
            XCTAssertEqual(transaction.getDataItem(key: "key")?.get(), "value")
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_getDataItem_returns_nil_for_value_not_committed_yet() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        wrapper.transactionally { transaction in
            transaction.apply(.put(key: "key", value: "value", expiry: .forever))
            XCTAssertNil(transaction.getDataItem(key: "key"))
            try transaction.commit()
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_getDataItem_returns_data_already_present_in_the_dataLayer_before_committing_a_remove() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        wrapper.put(key: "key", value: "value")
        wrapper.transactionally { transaction in
            transaction.apply(.remove(key: "key"))
            XCTAssertEqual(transaction.getDataItem(key: "key")?.get(), "value")
            try transaction.commit()
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_getDataItem_returns_nil_after_committing_a_remove() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        wrapper.put(key: "key", value: "value")
        wrapper.transactionally { transaction in
            transaction.apply(.remove(key: "key"))
            try transaction.commit()
            XCTAssertNil(transaction.getDataItem(key: "key"))
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_commit_again_in_same_transaction_block_does_nothing() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        let getCompleted = expectation(description: "Get callback is called")
        wrapper.transactionally { transaction in
            transaction.apply(.put(key: "key", value: "value", expiry: .forever))
            try transaction.commit()
            transaction.apply(.put(key: "key", value: "value2", expiry: .forever))
            try transaction.commit()
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        wrapper.get(key: "key", as: String.self).onSuccess { item in
            XCTAssertEqual(item, "value")
            getCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_completes_successfully_when_no_error_is_thrown() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        let transactionSuccessful = expectation(description: "Transaction is completed successfully")
        wrapper.transactionally { transaction in
            transaction.apply(.put(key: "key", value: "value", expiry: .forever))
            try transaction.commit()
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }.onSuccess {
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            transactionSuccessful.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_typed_getters_return_data_already_present_in_the_dataLayer() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        wrapper.putAll(dataObject: [
            "string": "value",
            "number": 1,
            "array": ["a", "b"],
            "nested": ["inner": "innerValue"] as DataObject
        ] as DataObject)
        wrapper.transactionally { transaction in
            XCTAssertEqual(transaction.get(key: "string"), "value")
            XCTAssertEqual(transaction.get(key: "number"), 1)
            XCTAssertEqual(transaction.getArray(key: "array"), ["a", "b"])
            XCTAssertEqual(transaction.getDataDictionary(key: "nested")?.get(key: "inner"), "innerValue")
            XCTAssertEqual(transaction.extract(path: JSONPath["nested"]["inner"]), "innerValue")
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_typed_getters_return_data_added_by_previous_commit() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        wrapper.transactionally { transaction in
            transaction.put(key: "number", value: 1, expiry: .forever)
            XCTAssertNil(transaction.get(key: "number", as: Int.self))
            try transaction.commit()
            XCTAssertEqual(transaction.get(key: "number"), 1)
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_put_does_nothing_without_commit() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        let getCompleted = expectation(description: "Get callback is called")
        wrapper.transactionally { transaction in
            transaction.put(key: "key", value: "value", expiry: .forever)
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        wrapper.getDataItem(key: "key").onSuccess { item in
            XCTAssertNil(item)
            getCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_commit_completes_the_transaction_for_previous_put() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        let getCompleted = expectation(description: "Get callback is called")
        wrapper.transactionally { transaction in
            transaction.put(key: "key", value: "value", expiry: .forever)
            try transaction.commit()
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        wrapper.get(key: "key", as: String.self).onSuccess { item in
            XCTAssertEqual(item, "value")
            getCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_commit_completes_the_transaction_for_previous_putAll() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        let getCompleted = expectation(description: "Get callback is called")
        wrapper.transactionally { transaction in
            transaction.putAll(dataObject: ["key1": "value1", "key2": "value2"], expiry: .forever)
            try transaction.commit()
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        wrapper.getAll().onSuccess { data in
            XCTAssertEqual(data.get(key: "key1"), "value1")
            XCTAssertEqual(data.get(key: "key2"), "value2")
            getCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_commit_completes_the_transaction_for_previous_remove_key() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        let getCompleted = expectation(description: "Get callback is called")
        wrapper.put(key: "key", value: "value")
        wrapper.transactionally { transaction in
            transaction.remove(key: "key")
            try transaction.commit()
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        wrapper.getDataItem(key: "key").onSuccess { item in
            XCTAssertNil(item)
            getCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_commit_completes_the_transaction_for_previous_remove_keys() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        let getCompleted = expectation(description: "Get callback is called")
        wrapper.putAll(dataObject: ["key1": "value1", "key2": "value2", "key3": "value3"])
        wrapper.transactionally { transaction in
            transaction.remove(keys: ["key1", "key2"])
            try transaction.commit()
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        wrapper.getAll().onSuccess { data in
            XCTAssertFalse(data.keys.contains("key1"))
            XCTAssertFalse(data.keys.contains("key2"))
            XCTAssertEqual(data.get(key: "key3"), "value3")
            getCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_remove_keys_does_nothing_without_commit() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        let getCompleted = expectation(description: "Get callback is called")
        wrapper.putAll(dataObject: ["key1": "value1", "key2": "value2"])
        wrapper.transactionally { transaction in
            transaction.remove(keys: ["key1", "key2"])
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        wrapper.getAll().onSuccess { data in
            XCTAssertEqual(data.get(key: "key1"), "value1")
            XCTAssertEqual(data.get(key: "key2"), "value2")
            getCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_commit_completes_the_transaction_for_previous_clear() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        let getCompleted = expectation(description: "Get callback is called")
        wrapper.putAll(dataObject: ["key1": "value1", "key2": "value2"])
        wrapper.transactionally { transaction in
            transaction.clear()
            transaction.put(key: "key3", value: "value3", expiry: .forever)
            try transaction.commit()
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        wrapper.getAll().onSuccess { data in
            XCTAssertFalse(data.keys.contains("key1"))
            XCTAssertFalse(data.keys.contains("key2"))
            XCTAssertEqual(data.get(key: "key3"), "value3")
            getCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_clear_does_nothing_without_commit() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        let getCompleted = expectation(description: "Get callback is called")
        wrapper.putAll(dataObject: ["key1": "value1"])
        wrapper.transactionally { transaction in
            transaction.clear()
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        wrapper.getAll().onSuccess { data in
            XCTAssertEqual(data.get(key: "key1"), "value1")
            getCompleted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_completes_with_error_when_error_is_thrown() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        let transactionFailure = expectation(description: "Transaction is completed with error")
        wrapper.transactionally { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
            throw TestError.unknown
        }.onFailure { error in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            transactionFailure.fulfill()
            guard case let .underlyingError(error) = error else {
                XCTFail("Expected underlyingError but got \(error)")
                return
            }
            XCTAssertTestErrorEquals(error, .unknown)
        }
        waitOnQueue(queue: queue)
    }

    func test_transactionally_does_not_run_the_block_after_the_module_is_shut_down() {
        manager.shutdown()
        let blockNotCalled = expectation(description: "Transaction block is not called")
        blockNotCalled.isInverted = true
        let transactionFailure = expectation(description: "Transaction is completed with error")
        wrapper.transactionally { _ in
            blockNotCalled.fulfill()
        }.onFailure { error in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            transactionFailure.fulfill()
            guard case .moduleNotEnabled(let module) = error else {
                XCTFail("Expected moduleNotEnabled but got \(error)")
                return
            }
            XCTAssertEqual(module, DataLayerModule.moduleType)
        }
        waitOnQueue(queue: queue)
    }

    func test_commit_emits_onDataUpdated_and_onDataRemoved_exactly_once() {
        wrapper.putAll(dataObject: ["existingKey1": "old1", "existingKey2": "old2"])
        var updatedEmissions = [DataObject]()
        var removedEmissions = [[String]]()
        _ = wrapper.onDataUpdated.subscribe { data in
            updatedEmissions.append(data)
        }
        _ = wrapper.onDataRemoved.subscribe { keys in
            removedEmissions.append(keys)
        }
        let callbackCalled = expectation(description: "Transaction callback is called")
        wrapper.transactionally { transaction in
            transaction.put(key: "key1", value: "value1", expiry: .forever)
            transaction.apply(.put(key: "key2", value: "value2", expiry: .forever))
            transaction.remove(key: "existingKey1")
            transaction.apply(.remove(key: "existingKey2"))
            XCTAssertTrue(updatedEmissions.isEmpty)
            XCTAssertTrue(removedEmissions.isEmpty)
            try transaction.commit()
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        waitOnQueue(queue: queue)
        XCTAssertEqual(updatedEmissions.count, 1)
        XCTAssertEqual(removedEmissions.count, 1)
        XCTAssertEqual(updatedEmissions.first?.get(key: "key1"), "value1")
        XCTAssertEqual(updatedEmissions.first?.get(key: "key2"), "value2")
        XCTAssertEqual(removedEmissions.first, ["existingKey1", "existingKey2"])
    }

    func test_getAll_and_keys_reflect_only_committed_data() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        wrapper.putAll(dataObject: ["key1": "value1"])
        wrapper.transactionally { transaction in
            transaction.put(key: "key2", value: "value2", expiry: .forever)
            XCTAssertFalse(transaction.getAll().keys.contains("key2"))
            XCTAssertEqual(Set(transaction.keys()), ["key1"])
            try transaction.commit()
            XCTAssertEqual(transaction.getAll().get(key: "key2"), "value2")
            XCTAssertEqual(Set(transaction.keys()), ["key1", "key2"])
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_count_matches_committed_key_count_before_and_after_commit() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        wrapper.putAll(dataObject: ["key1": "value1", "key2": "value2"])
        wrapper.transactionally { transaction in
            transaction.put(key: "key3", value: "value3", expiry: .forever)
            XCTAssertEqual(transaction.count(), 2)
            try transaction.commit()
            XCTAssertEqual(transaction.count(), 3)
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_count_matches_committed_key_count_after_remove() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        wrapper.putAll(dataObject: ["key1": "value1", "key2": "value2", "key3": "value3"])
        wrapper.transactionally { transaction in
            transaction.remove(key: "key1")
            try transaction.commit()
            XCTAssertEqual(transaction.count(), 2)
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_count_matches_committed_key_count_after_clear() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        wrapper.putAll(dataObject: ["key1": "value1", "key2": "value2", "key3": "value3"])
        wrapper.transactionally { transaction in
            transaction.clear()
            transaction.put(key: "key4", value: "value4", expiry: .forever)
            try transaction.commit()
            XCTAssertEqual(transaction.count(), 1)
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            callbackCalled.fulfill()
        }
        waitOnQueue(queue: queue)
    }
}

final class DataLayerWrapperFailingCommitTests: BaseDataLayerWrapperTests {
    override var moduleFactories: [any ModuleFactory] {
        [StubModuleFactory(module: DataLayerModule(dataStore: FailingMockDataStore()))]
    }

    func test_commit_failure_completes_the_transaction_with_a_failure() {
        let callbackCalled = expectation(description: "Transaction callback is called")
        let transactionFailure = expectation(description: "Transaction is completed with error")
        wrapper.transactionally { transaction in
            do {
                try transaction.commit()
                XCTFail("commit() should throw when the data store fails to commit")
            } catch {
                dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
                callbackCalled.fulfill()
                throw error
            }
        }.onFailure { error in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            transactionFailure.fulfill()
            guard case .underlyingError = error else {
                XCTFail("Expected underlyingError but got \(error)")
                return
            }
        }
        waitOnQueue(queue: queue)
    }
}
