//
//  TrackerImplTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 26/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class TrackerImplTests: XCTestCase {
    @StateSubject([
        MockCollector1(),
        MockCollector2()
    ])
    var modules: ObservableState<[TealiumModule]>
    @StateSubject(SDKSettings())
    var sdkSettings: ObservableState<SDKSettings>
    lazy var loadRuleEngine = LoadRuleEngine(sdkSettings: sdkSettings)
    let mockDispatchManager = MockDispatchManager()
    lazy var tracker = TrackerImpl(modules: modules,
                                   loadRuleEngine: loadRuleEngine,
                                   dispatchManager: mockDispatchManager,
                                   logger: nil)

    func test_track_collects_from_all_collectors() {
        let collected = expectation(description: "Collector called")
        collected.expectedFulfillmentCount = 2
        guard let collector1 = modules.value.compactMap({ $0 as? MockCollector1 }).first,
                  let collector2 = modules.value.compactMap({ $0 as? MockCollector2 }).first else {
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
        _sdkSettings.value = SDKSettings(core: CoreSettings(),
                                         modules: [
                                            MockCollector1.id: ModuleSettings(rules: .just("ruleId")),
                                            MockCollector2.id: ModuleSettings(rules: .not(.just("ruleId")))
                                         ],
                                         loadRules: [
                                            "ruleId": LoadRule(id: "ruleId",
                                                               conditions: .just(condition))
                                         ])
        guard let collector1 = modules.value.compactMap({ $0 as? MockCollector1 }).first,
                  let collector2 = modules.value.compactMap({ $0 as? MockCollector2 }).first else {
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
        let collector = MockCollector1()
        _ = collector.onCollect.subscribe { _ in
            collected.fulfill()
        }
        _modules.value = [collector]
        waitForDefaultTimeout()
    }

    func test_track_dispatches_enriched_dispatch() {
        let dispatched = expectation(description: "DispatchManager called")
        _ = mockDispatchManager.onDispatch.subscribeOnce { newDispatch in
            XCTAssertNotNil(newDispatch.payload.getDataItem(key: MockCollector1.id))
            XCTAssertNotNil(newDispatch.payload.getDataItem(key: MockCollector2.id))
            dispatched.fulfill()
        }
        tracker.track(Dispatch(name: "event"), source: .application)
        waitForDefaultTimeout()
    }
}
