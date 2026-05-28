//
//  BarrierManagerTests.swift
//  tealium-prism_Tests
//
//  Created by Tealium on 24/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class BarrierManagerTests: XCTestCase {
    @StateSubject([:])
    var barrierSettings: ObservableState<[String: BarrierSettings]>
    lazy var barrierManager = BarrierManager(sdkBarrierSettings: barrierSettings)

    func test_initializeBarriers_creates_configurable_barriers_from_factories() {
        let mockFactory1 = MockBarrierFactory<MockBarrier1>(defaultScope: .all)
        let mockFactory2 = MockBarrierFactory<MockBarrier2>(defaultScope: .dispatchers(["test"]))

        barrierManager.initializeBarriers(factories: [mockFactory1, mockFactory2], context: mockContext)
        XCTAssertEqual(barrierManager.configBarriers.value.count, 2)
        XCTAssertEqual(barrierManager.configBarriers.value[0].id, "barrier1")
        XCTAssertEqual(barrierManager.configBarriers.value[1].id, "barrier2")
    }

    func test_onBarriers_emits_initialized_barriers_with_default_scope() {
        let onBarrierEmitted = expectation(description: "On Barrier emitted")
        let mockFactory1 = MockBarrierFactory<MockBarrier1>(defaultScope: .all)
        let mockFactory2 = MockBarrierFactory<MockBarrier2>(defaultScope: .dispatchers(["test"]))

        barrierManager.initializeBarriers(factories: [mockFactory1, mockFactory2], context: mockContext)
        barrierManager.onScopedBarriers.subscribeOnce { barriers in
            XCTAssertEqual(barriers[0].scope, .all)
            XCTAssertEqual(barriers[1].scope, .dispatchers(["test"]))
            onBarrierEmitted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_registerScopedBarrier_adds_barrier_with_scope() {
        let mockBarrier = MockBarrier()

        barrierManager.registerScopedBarrier(mockBarrier, scope: .all)
        XCTAssertEqual(barrierManager.nonConfigBarriers.value.count, 1)
        XCTAssertTrue(barrierManager.nonConfigBarriers.value[0].barrier === mockBarrier)
        XCTAssertEqual(barrierManager.nonConfigBarriers.value[0].scope, .all)
    }

    func test_unregisterScopedBarrier_removes_barrier() {
        let mockBarrier1 = MockBarrier()
        let mockBarrier2 = MockBarrier()
        barrierManager.registerScopedBarrier(mockBarrier1, scope: .all)
        barrierManager.registerScopedBarrier(mockBarrier2, scope: .dispatchers(["test"]))

        barrierManager.unregisterScopedBarrier(mockBarrier1)
        XCTAssertEqual(barrierManager.nonConfigBarriers.value.count, 1)
        XCTAssertTrue(barrierManager.nonConfigBarriers.value[0].barrier === mockBarrier2)
    }

    func test_registerScopedBarrier_updates_existing_barrier_scope() {
        let mockBarrier = MockBarrier()
        barrierManager.registerScopedBarrier(mockBarrier, scope: .all)

        barrierManager.registerScopedBarrier(mockBarrier, scope: .dispatchers(["new"]))
        XCTAssertEqual(barrierManager.nonConfigBarriers.value.count, 1)
        XCTAssertIdentical(barrierManager.nonConfigBarriers.value[0].barrier, mockBarrier)
        XCTAssertEqual(barrierManager.nonConfigBarriers.value[0].scope, .dispatchers(["new"]))
    }

    func test_onBarriers_combines_nonConfigBarriers_and_configBarriers() {
        let mockFactory = MockBarrierFactory<MockBarrier1>(defaultScope: .all)
        let mockExtraBarrier = MockBarrier()

        barrierManager.initializeBarriers(factories: [mockFactory], context: mockContext)
        barrierManager.registerScopedBarrier(mockExtraBarrier, scope: .dispatchers(["test"]))
        let barriersReported = expectation(description: "Barriers are reported")

        barrierManager.onScopedBarriers.subscribeOnce { barriers in
            XCTAssertEqual(barriers.count, 2)
            XCTAssertIdentical(barriers[0].barrier, mockExtraBarrier)
            XCTAssertEqual(barriers[0].scope, .dispatchers(["test"]))
            XCTAssertTrue(barriers[1].barrier is MockBarrier1)
            XCTAssertEqual(barriers[1].scope, .all)
            barriersReported.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_barrierSettings_updates_trigger_configuration_updates() {
        let mockFactory = MockBarrierFactory<MockBarrier1>(defaultScope: .all)

        barrierManager.initializeBarriers(factories: [mockFactory], context: mockContext)
        guard let configBarrier = barrierManager.configBarriers.value.first as? MockConfigurableBarrier else {
            XCTFail("Expected MockConfigurableBarrier"); return
        }

        _barrierSettings.value = [
            "barrier1": BarrierSettings(barrierId: "barrier1",
                                        scope: .all,
                                        configuration: ["key": "value"])
        ]
        XCTAssertEqual(configBarrier.lastConfiguration, ["key": "value"])
    }

    func test_barrierSettings_updates_changes_configurable_barriers_scope() {
        let mockFactory = MockBarrierFactory<MockBarrier1>(defaultScope: .all)

        barrierManager.initializeBarriers(factories: [mockFactory], context: mockContext)
        guard barrierManager.configBarriers.value.first is MockConfigurableBarrier else {
            XCTFail("Expected MockConfigurableBarrier"); return
        }
        let barriersReported = expectation(description: "Barriers are reported")
        barrierManager.onScopedBarriers.subscribeOnce { barriers in
            XCTAssertEqual(barriers[0].scope, .all)
        }
        _barrierSettings.value = [
            "barrier1": BarrierSettings(barrierId: "barrier1",
                                        scope: .dispatchers(["test"]),
                                        configuration: ["key": "value"])
        ]
        barrierManager.onScopedBarriers.subscribeOnce { barriers in
            XCTAssertEqual(barriers[0].scope, .dispatchers(["test"]))
            barriersReported.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_scopedConfigBarriers_uses_defaultScope_from_factories() {
        let mockFactory1 = MockBarrierFactory<MockBarrier1>(defaultScope: .all)
        let mockFactory2 = MockBarrierFactory<MockBarrier2>(defaultScope: .dispatchers(["test"]))

        barrierManager.initializeBarriers(factories: [mockFactory1, mockFactory2], context: mockContext)
        let barriersReported = expectation(description: "Barriers are reported")

        barrierManager.scopedConfigBarriers().subscribeOnce { scopedBarriers in
            XCTAssertEqual(scopedBarriers.count, 2)
            XCTAssertEqual(scopedBarriers[0].scope, .all)
            XCTAssertEqual(scopedBarriers[1].scope, .dispatchers(["test"]))
            barriersReported.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_initializeBarriers_passes_configuration_from_settings_to_factory() {
        _barrierSettings.value = [
            "barrier1": BarrierSettings(barrierId: "barrier1", scope: .all, configuration: ["key": "value"])
        ]
        let mockFactory = MockBarrierFactory<MockBarrier1>(defaultScope: .all)

        barrierManager.initializeBarriers(factories: [mockFactory], context: mockContext)
        XCTAssertEqual(mockFactory.barrier.lastConfiguration, ["key": "value"])
    }

    func test_initializeBarriers_passes_empty_config_when_no_settings_for_barrier() {
        _barrierSettings.value = [:]
        let mockFactory = MockBarrierFactory<MockBarrier1>(defaultScope: .all)

        barrierManager.initializeBarriers(factories: [mockFactory], context: mockContext)
        XCTAssertEqual(mockFactory.barrier.lastConfiguration, [:])
    }

    func test_initializeBarriers_scopes_barriers_using_settings_scope_over_default() {
        _barrierSettings.value = [
            "barrier1": BarrierSettings(barrierId: "barrier1", scope: .dispatchers(["from_settings"]))
        ]
        let mockFactory = MockBarrierFactory<MockBarrier1>(defaultScope: .dispatchers(["from_factory"]))

        barrierManager.initializeBarriers(factories: [mockFactory], context: mockContext)
        let scopeEmitted = expectation(description: "Scope emitted")
        barrierManager.scopedConfigBarriers().subscribeOnce { barriers in
            XCTAssertEqual(barriers[0].scope, .dispatchers(["from_settings"]))
            scopeEmitted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_unregisterScopedBarrier_does_not_remove_config_registered_barrier() {
        let mockFactory = MockBarrierFactory<MockBarrier1>(defaultScope: .all)
        barrierManager.initializeBarriers(factories: [mockFactory], context: mockContext)

        barrierManager.unregisterScopedBarrier(mockFactory.barrier)
        XCTAssertEqual(barrierManager.configBarriers.value.count, 1)
        XCTAssertEqual(barrierManager.configBarriers.value[0].id, "barrier1")
    }
}
