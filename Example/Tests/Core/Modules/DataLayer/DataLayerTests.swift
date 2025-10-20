//
//  DataLayerTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 20/11/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

private class DataLayerMock: DataLayerWrapper {
    struct Put {
        let key: String
        let value: any DataInput
        let expiry: Expiry
    }
    @Subject<Put> var onPut

    override func put(key: String, value: any DataInput, expiry: Expiry) -> SingleResult<Void> {
        _onPut.publish(Put(key: key, value: value, expiry: expiry))
        return super.put(key: key, value: value, expiry: expiry)
    }

    override func put(data: DataObject, expiry: Expiry) -> SingleResult<Void> {
        for key in data.keys {
            if let dataItem = data.getDataItem(key: key) {
                _onPut.publish(Put(key: key, value: dataItem.toDataInput(), expiry: expiry))
            }
        }
        return super.put(data: data, expiry: expiry)
    }
}

final class DataLayerTests: BaseDataLayerWrapperTests {
    private lazy var dataLayerMock = DataLayerMock(moduleProxy: ModuleProxy(queue: queue,
                                                                            onModulesManager: onManager.asObservable()))

    func test_put_convertible_inserts_converted_value() {
        let putCalled = expectation(description: "Put is called")
        dataLayerMock.onPut.subscribeOnce { put in
            XCTAssertEqual(put.value as? String, "value")
            putCalled.fulfill()
        }
        dataLayerMock.put(key: "key", converting: DataItem(converting: "value"))
        waitForDefaultTimeout()
    }

    func test_put_convertible_uses_forever_default_expiry() throws {
        let putCalled = expectation(description: "Put is called")
        dataLayerMock.onPut.subscribeOnce { put in
            XCTAssertEqual(put.expiry, .forever)
            putCalled.fulfill()
        }
        dataLayerMock.put(key: "key", converting: DataItem(converting: "value"))
        waitForDefaultTimeout()
    }

    func test_put_uses_forever_default_expiry() throws {
        let putCalled = expectation(description: "Put is called")
        dataLayerMock.onPut.subscribeOnce { put in
            XCTAssertEqual(put.expiry, .forever)
            putCalled.fulfill()
        }
        dataLayerMock.put(key: "key", value: "value")
        waitForDefaultTimeout()
    }

    func test_put_data_uses_forever_default_expiry() throws {
        let putCalled = expectation(description: "Put is called")
        dataLayerMock.onPut.subscribeOnce { put in
            XCTAssertEqual(put.expiry, .forever)
            putCalled.fulfill()
        }
        dataLayerMock.put(data: ["key": "value"])
        waitForDefaultTimeout()
    }
}
