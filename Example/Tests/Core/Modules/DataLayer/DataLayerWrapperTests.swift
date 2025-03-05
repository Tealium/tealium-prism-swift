//
//  DataLayerWrapperTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 13/11/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

class BaseDataLayerWrapperTests: XCTestCase {
    let dbProvider = MockDatabaseProvider()
    let queue = TealiumQueue.worker
    lazy var manager = ModulesManager(queue: queue)
    lazy var onManager: ReplaySubject<ModulesManager?> = ReplaySubject(initialValue: manager)
    lazy var config: TealiumConfig = mockConfig
    lazy var wrapper = DataLayerWrapper(moduleProxy: ModuleProxy(onModulesManager: onManager.asObservable()))

    func context() -> TealiumContext {
        TealiumContext(modulesManager: manager,
                       config: config,
                       coreSettings: StateSubject(CoreSettings(coreDataObject: [:])).toStatefulObservable(),
                       tracker: MockTracker(),
                       barrierRegistry: BarrierCoordinator(registeredBarriers: [], onScopedBarriers: .Just([])),
                       transformerRegistry: TransformerCoordinator(transformers: StateSubject([]).toStatefulObservable(),
                                                                   scopedTransformations: StateSubject([]).toStatefulObservable(),
                                                                   queue: queue),
                       databaseProvider: dbProvider,
                       moduleStoreProvider: ModuleStoreProvider(databaseProvider: dbProvider,
                                                                modulesRepository: SQLModulesRepository(dbProvider: dbProvider)),
                       logger: nil,
                       networkHelper: MockNetworkHelper(),
                       activityListener: ApplicationStatusListener.shared,
                       queue: queue,
                       visitorId: mockVisitorId)
    }

    override func setUp() {
        config.modules = [TealiumModules.dataLayer()]
        manager.updateSettings(context: context(), settings: SDKSettings(modulesSettings: [:]))
    }
}

final class DataLayerWrapperTests: BaseDataLayerWrapperTests {

    func test_put_and_remove_single_value() {
        let completionCalled = expectation(description: "Completion is called")
        wrapper.put(key: "key", value: "value")
        wrapper.get(key: "key") { value in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            XCTAssertEqual(value, "value")
            completionCalled.fulfill()
        }
        waitOnQueue(queue: queue)
        let secondCompletionCalled = expectation(description: "Second completion is called")
        wrapper.remove(key: "key")
        wrapper.getDataItem(key: "key") { value in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            XCTAssertNil(value)
            secondCompletionCalled.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_put_and_remove_multiple_values() {
        let completionCalled = expectation(description: "Completion is called")
        completionCalled.expectedFulfillmentCount = 2
        wrapper.put(data: ["key1": "value1", "key2": "value2"])
        wrapper.get(key: "key1") { value in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            XCTAssertEqual(value, "value1")
            completionCalled.fulfill()
        }
        wrapper.get(key: "key2") { value in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            XCTAssertEqual(value, "value2")
            completionCalled.fulfill()
        }
        waitOnQueue(queue: queue)
        let secondCompletionCalled = expectation(description: "Second completion is called")
        secondCompletionCalled.expectedFulfillmentCount = 2
        wrapper.remove(keys: ["key1", "key2"])
        wrapper.getDataItem(key: "key1") { value in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            XCTAssertNil(value)
            secondCompletionCalled.fulfill()
        }
        wrapper.getDataItem(key: "key2") { value in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            XCTAssertNil(value)
            secondCompletionCalled.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_clear_removes_all_values() {
        let completionCalled = expectation(description: "Completion is called")
        completionCalled.expectedFulfillmentCount = 2
        wrapper.put(data: ["key1": "value1", "key2": "value2"])
        wrapper.get(key: "key1") { value in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            XCTAssertEqual(value, "value1")
            completionCalled.fulfill()
        }
        wrapper.get(key: "key2") { value in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            XCTAssertEqual(value, "value2")
            completionCalled.fulfill()
        }
        waitOnQueue(queue: queue)
        let secondCompletionCalled = expectation(description: "Second completion is called")
        secondCompletionCalled.expectedFulfillmentCount = 2
        wrapper.clear()
        wrapper.getDataItem(key: "key1") { value in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            XCTAssertNil(value)
            secondCompletionCalled.fulfill()
        }
        wrapper.getDataItem(key: "key2") { value in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            XCTAssertNil(value)
            secondCompletionCalled.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_onDataUpdated_reports_data_changes() {
        let eventEmitted = expectation(description: "Event is emitted")
        let dataObject: DataObject = ["key": "value"]
        _ = wrapper.onDataUpdated.subscribe { data in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            XCTAssertEqual(data, dataObject)
            eventEmitted.fulfill()
        }
        wrapper.put(data: dataObject)
        waitOnQueue(queue: queue)
    }

    func test_onDataUpdated_reports_removed_keys() {
        let eventEmitted = expectation(description: "Event is emitted")
        let dataObject: DataObject = ["key1": "value1", "key2": "value2"]
        _ = wrapper.onDataRemoved.subscribe { keys in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            XCTAssertEqual(keys, ["key1", "key2"])
            eventEmitted.fulfill()
        }
        wrapper.put(data: dataObject)
        wrapper.remove(keys: ["key1", "key2"])
        waitOnQueue(queue: queue)
    }
}
