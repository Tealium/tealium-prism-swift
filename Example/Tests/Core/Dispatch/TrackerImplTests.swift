//
//  TrackerImplTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 26/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class TrackerImplTests: XCTestCase {
    @StateSubject([
        MockCollector(moduleId: "MockCollector1"),
        MockCollector(moduleId: "MockCollector2")
    ])
    var modules: ObservableState<[Module]>
    @StateSubject(SDKSettings())
    var sdkSettings: ObservableState<SDKSettings>
    lazy var loadRuleEngine = LoadRuleEngine(sdkSettings: sdkSettings,
                                             logger: nil)
    let mockDispatchManager = MockDispatchManager()
    let sessionManager = MockSessionManager()
    lazy var tracker = TrackerImpl(modules: modules,
                                   loadRuleEngine: loadRuleEngine,
                                   dispatchManager: mockDispatchManager,
                                   sessionManager: sessionManager,
                                   logger: nil)

    func test_track_collects_from_all_collectors() {
        let collected = expectation(description: "Collector called")
        collected.expectedFulfillmentCount = 2
        let collectors = modules.value.compactMap({ $0 as? MockCollector })
        guard let collector1 = collectors.first(where: { $0.id == "MockCollector1" }),
              let collector2 = collectors.first(where: { $0.id == "MockCollector2" }) else {
            XCTFail("Collector not found")
            return
        }
        _ = collector1.onCollect.subscribe { _ in
            collected.fulfill()
        }
        _ = collector2.onCollect.subscribe { _ in
            collected.fulfill()
        }
        tracker.track(Dispatch(name: "event"), source: .application)
        waitForDefaultTimeout()
    }

    func test_track_only_collects_from_collectors_that_are_not_excluded_by_the_loadRules() {
        let collected = expectation(description: "Allowed Collector called")
        let notCollected = expectation(description: "Excluded Collector should not be called")
        notCollected.isInverted = true
        let condition = Condition.endsWith(ignoreCase: false,
                                           variable: "tealium_event",
                                           suffix: "to_drop")
        let collectorId1 = modules.value[0].id
        let collectorId2 = modules.value[1].id
        _sdkSettings.add(modules: [
            collectorId1: ModuleSettings(moduleId: collectorId1, moduleType: MockCollector.moduleType, rules: "ruleId"),
            collectorId2: ModuleSettings(moduleId: collectorId2, moduleType: MockCollector.moduleType, rules: .not("ruleId"))
        ], loadRules: [
            "ruleId": LoadRule(id: "ruleId", conditions: .just(condition))
        ])
        let collectors = modules.value.compactMap({ $0 as? MockCollector })
        guard let collector1 = collectors.first(where: { $0.id == collectorId1 }),
                  let collector2 = collectors.first(where: { $0.id == collectorId2 }) else {
            XCTFail("Collector not found")
            return
        }
        _ = collector1.onCollect.subscribe { _ in
            collected.fulfill()
        }
        _ = collector2.onCollect.subscribe { _ in
            notCollected.fulfill()
        }
        tracker.track(Dispatch(name: "event_to_drop"), source: .application)
        waitForDefaultTimeout()
    }

    func test_track_waits_until_modules_contains_at_least_one_module_before_collecting() {
        let collected = expectation(description: "Collector called")
        _modules.value = []
        tracker.track(Dispatch(name: "event"), source: .application)
        let collector = MockCollector()
        _ = collector.onCollect.subscribe { _ in
            collected.fulfill()
        }
        _modules.value = [collector]
        waitForDefaultTimeout()
    }

    func test_track_dispatches_enriched_dispatch() {
        let dispatched = expectation(description: "DispatchManager called")
        let collectorId1 = modules.value[0].id
        let collectorId2 = modules.value[1].id
        _ = mockDispatchManager.onDispatch.subscribeOnce { newDispatch in
            XCTAssertNotNil(newDispatch.payload.getDataItem(key: collectorId1))
            XCTAssertNotNil(newDispatch.payload.getDataItem(key: collectorId2))
            dispatched.fulfill()
        }
        tracker.track(Dispatch(name: "event"), source: .application)
        waitForDefaultTimeout()
    }

    func test_track_drops_events_when_tealiumConsentExplicitlyBlocked() {
        let resultCalled = expectation(description: "Result is called")
        self.mockDispatchManager.tealiumPurposeExplicitlyBlocked = true
        tracker.track(Dispatch(name: "event"), source: .application) { result in
            XCTAssertTrackResultIsDropped(result)
            resultCalled.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_track_does_not_register_dispatch_when_no_modules_emitted_yet() {
        let registerDispatchCalled = expectation(description: "Register dispatch should not be called")
        registerDispatchCalled.isInverted = true
        _modules.value = []
        sessionManager.onRegisterDispatch.subscribeOnce { _ in
            registerDispatchCalled.fulfill()
        }
        tracker.track(Dispatch(name: "event"), source: .application)
        waitForDefaultTimeout()
    }

    func test_track_registers_dispatch_when_modules_emit() {
        let registerDispatchCalled = expectation(description: "Register dispatch should be called")
        sessionManager.onRegisterDispatch.subscribeOnce { _ in
            registerDispatchCalled.fulfill()
        }
        tracker.track(Dispatch(name: "event"), source: .application)
        waitForDefaultTimeout()
    }

    func test_track_registers_dispatch_before_collection() {
        let registerDispatchCalled = expectation(description: "Register dispatch should be called")
        let collectionCalled = expectation(description: "Collect should be called")
        sessionManager.onRegisterDispatch.subscribeOnce { _ in
            registerDispatchCalled.fulfill()
        }
        modules.value
            .compactMap { $0 as? MockCollector }
            .first?.onCollect
            .subscribeOnce { _ in
                collectionCalled.fulfill()
            }
        tracker.track(Dispatch(name: "event"), source: .application)
        wait(for: [registerDispatchCalled, collectionCalled],
             timeout: Self.defaultTimeout,
             enforceOrder: true)
    }
}
