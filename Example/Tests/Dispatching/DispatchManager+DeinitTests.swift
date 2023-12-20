//
//  DispatchManager+DeinitTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 07/12/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class DispatchManagerDeinitTests: DispatchManagerTestCase {

    func test_stopDispatchLoop_cancels_inProgress_dispatches() {
        disableModule(module: module2)
        guard let module = module1 else {
            XCTFail("module1 not found")
            return
        }
        module.delay = 500
        let eventsAreNotDispatched = expectation(description: "Events are not dispatched")
        eventsAreNotDispatched.isInverted = true
        dispatchManager.track(TealiumDispatch(name: "someEvent"))
        _ = module.onDispatch.subscribe { _ in
            eventsAreNotDispatched.fulfill()
        }
        dispatchManager.stopDispatchLoop()
        waitForExpectations(timeout: 1.0)
    }

    func test_dispatchManager_can_be_deinitialized() {
        barrier.setState(.closed)
        let helper = RetainCycleHelper(variable: dispatchManager)
        dispatchManager.track(TealiumDispatch(name: "someEvent"))
        dispatchManager = getDispatchManager()
        helper.forceAndAssertObjectDeinit()
    }
}
