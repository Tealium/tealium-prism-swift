//
//  BarrierManagerTests.swift
//  tealium-swift_Tests
//
//  Created by Tealium on 24/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class BarrierManagerTests: XCTestCase {
    @StateSubject([:])
    var barrierSettings: ObservableState<[String: BarrierSettings]>
    lazy var barrierManager = BarrierManager(sdkBarrierSettings: barrierSettings)

    func test_initializeBarriers_creates_configurable_barriers_from_factories() {
        let mockFactory1 = MockBarrierFactory<MockBarrier1>(defaultScope: [.all])
        let mockFactory2 = MockBarrierFactory<MockBarrier2>(defaultScope: [.dispatcher("test")])

        barrierManager.initializeBarriers(factories: [mockFactory1, mockFactory2], context: mockContext)
        XCTAssertEqual(barrierManager.configBarriers.value.count, 2)
        XCTAssertEqual(barrierManager.configBarriers.value[0].id, "barrier1")
        XCTAssertEqual(barrierManager.configBarriers.value[1].id, "barrier2")
    }

    func test_onBarriers_emits_initialized_barriers_with_default_scopes() {
        let onBarrierEmitted = expectation(description: "On Barrier emitted")
        let mockFactory1 = MockBarrierFactory<MockBarrier1>(defaultScope: [.all])
        let mockFactory2 = MockBarrierFactory<MockBarrier2>(defaultScope: [.dispatcher("test")])

        barrierManager.initializeBarriers(factories: [mockFactory1, mockFactory2], context: mockContext)
        barrierManager.onScopedBarriers.subscribeOnce { barriers in
            XCTAssertEqual(barriers[0].scopes, [.all])
            XCTAssertEqual(barriers[1].scopes, [.dispatcher("test")])
            onBarrierEmitted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_registerScopedBarrier_adds_barrier_with_scopes() {
        let mockBarrier = MockBarrier()
        let scopes: [BarrierScope] = [.all]

        barrierManager.registerScopedBarrier(mockBarrier, scopes: scopes)
        XCTAssertEqual(barrierManager.nonConfigBarriers.value.count, 1)
        XCTAssertTrue(barrierManager.nonConfigBarriers.value[0].barrier === mockBarrier)
        XCTAssertEqual(barrierManager.nonConfigBarriers.value[0].scopes, scopes)
    }

    func test_unregisterScopedBarrier_removes_barrier() {
        let mockBarrier1 = MockBarrier()
        let mockBarrier2 = MockBarrier()
        barrierManager.registerScopedBarrier(mockBarrier1, scopes: [.all])
        barrierManager.registerScopedBarrier(mockBarrier2, scopes: [.dispatcher("test")])

        barrierManager.unregisterScopedBarrier(mockBarrier1)
        XCTAssertEqual(barrierManager.nonConfigBarriers.value.count, 1)
        XCTAssertTrue(barrierManager.nonConfigBarriers.value[0].barrier === mockBarrier2)
    }

    func test_registerScopedBarrier_updates_existing_barrier_scopes() {
        let mockBarrier = MockBarrier()
        barrierManager.registerScopedBarrier(mockBarrier, scopes: [.all])

        barrierManager.registerScopedBarrier(mockBarrier, scopes: [.dispatcher("new")])
        XCTAssertEqual(barrierManager.nonConfigBarriers.value.count, 1)
        XCTAssertIdentical(barrierManager.nonConfigBarriers.value[0].barrier, mockBarrier)
        XCTAssertEqual(barrierManager.nonConfigBarriers.value[0].scopes, [.dispatcher("new")])
    }

    func test_onBarriers_combines_nonConfigBarriers_and_configBarriers() {
        let mockFactory = MockBarrierFactory<MockBarrier1>(defaultScope: [.all])
        let mockExtraBarrier = MockBarrier()

        barrierManager.initializeBarriers(factories: [mockFactory], context: mockContext)
        barrierManager.registerScopedBarrier(mockExtraBarrier, scopes: [.dispatcher("test")])
        let barriersReported = expectation(description: "Barriers are reported")

        barrierManager.onScopedBarriers.subscribeOnce { barriers in
            XCTAssertEqual(barriers.count, 2)
            XCTAssertIdentical(barriers[0].barrier, mockExtraBarrier)
            XCTAssertEqual(barriers[0].scopes, [.dispatcher("test")])
            XCTAssertTrue(barriers[1].barrier is MockBarrier1)
            XCTAssertEqual(barriers[1].scopes, [.all])
            barriersReported.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_barrierSettings_updates_trigger_configuration_updates() {
        let mockFactory = MockBarrierFactory<MockBarrier1>(defaultScope: [.all])

        barrierManager.initializeBarriers(factories: [mockFactory], context: mockContext)
        let configBarrier = barrierManager.configBarriers.value.first as? MockConfigurableBarrier
        XCTAssertNotNil(configBarrier)

        _barrierSettings.value = [
            "barrier1": BarrierSettings(barrierId: "barrier1",
                                        scopes: [.all],
                                        configuration: ["key": "value"])
        ]
        XCTAssertEqual(configBarrier?.lastConfiguration, ["key": "value"])
    }

    func test_barrierSettings_updates_changes_configurable_barriers_scopes() {
        let mockFactory = MockBarrierFactory<MockBarrier1>(defaultScope: [.all])

        barrierManager.initializeBarriers(factories: [mockFactory], context: mockContext)
        let configBarrier = barrierManager.configBarriers.value.first as? MockConfigurableBarrier
        XCTAssertNotNil(configBarrier)
        let barriersReported = expectation(description: "Barriers are reported")
        barrierManager.onScopedBarriers.subscribeOnce { barriers in
            XCTAssertEqual(barriers[0].scopes, [.all])
        }
        _barrierSettings.value = [
            "barrier1": BarrierSettings(barrierId: "barrier1",
                                        scopes: [.dispatcher("test")],
                                        configuration: ["key": "value"])
        ]
        barrierManager.onScopedBarriers.subscribeOnce { barriers in
            XCTAssertEqual(barriers[0].scopes, [.dispatcher("test")])
            barriersReported.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_scopedConfigBarriers_uses_defaultScopes_from_factories() {
        let mockFactory1 = MockBarrierFactory<MockBarrier1>(defaultScope: [.all])
        let mockFactory2 = MockBarrierFactory<MockBarrier2>(defaultScope: [.dispatcher("test")])

        barrierManager.initializeBarriers(factories: [mockFactory1, mockFactory2], context: mockContext)
        let barriersReported = expectation(description: "Barriers are reported")

        barrierManager.scopedConfigBarriers().subscribeOnce { scopedBarriers in
            XCTAssertEqual(scopedBarriers.count, 2)
            XCTAssertEqual(scopedBarriers[0].scopes, [.all])
            XCTAssertEqual(scopedBarriers[1].scopes, [.dispatcher("test")])
            barriersReported.fulfill()
        }
        waitForDefaultTimeout()
    }
}
