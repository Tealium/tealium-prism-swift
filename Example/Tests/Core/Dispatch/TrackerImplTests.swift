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
    let collector1 = MockCollector(moduleId: "MockCollector1")
    let collector2 = MockCollector(moduleId: "MockCollector2")
    /**
     * Stands in for `ModuleManager.observeModules`: nothing is emitted until the modules are ready,
     * and every `track` call subscribes again to get the collectors of the last pass.
     */
    @ReplaySubject<[Collector]> var onCollectors
    @StateSubject(SDKSettings())
    var sdkSettings
    lazy var loadRuleEngine = LoadRuleEngine(sdkSettings: sdkSettings,
                                             logger: nil)
    let mockDispatchManager = MockDispatchManager()
    let sessionManager = MockSessionManager()
    lazy var tracker = TrackerImpl(onCollectors: onCollectors,
                                   loadRuleEngine: loadRuleEngine,
                                   dispatchManager: mockDispatchManager,
                                   sessionManager: sessionManager,
                                   logger: nil)

    /// Fixtures for tests that need a real `ModuleManager` readiness gate (MT-2154), instead of the
    /// `ReplaySubject` stand-in above.
    lazy var moduleManager = ModuleManager()
    lazy var config = TealiumConfig(account: "test",
                                    profile: "test",
                                    environment: "dev",
                                    modules: [MockCollector.factory(), MockCollector2.factory(), CallbackOnInitModule.factory()],
                                    settingsFile: nil,
                                    settingsUrl: nil)
    lazy var context = MockContext(moduleManager: moduleManager, config: config)
    lazy var trackerWithModuleManager = TrackerImpl(onCollectors: moduleManager.observeModules { $0 as? Collector },
                                                    loadRuleEngine: loadRuleEngine,
                                                    dispatchManager: mockDispatchManager,
                                                    sessionManager: sessionManager,
                                                    logger: nil)

    override func setUp() {
        super.setUp()
        _onCollectors.onNext([collector1, collector2])
    }

    private func settings(enabling enabled: [(moduleType: String, order: Int?)],
                          disabling disabled: [String] = []) -> SDKSettings {
        var modules = enabled.reduce(into: [String: ModuleSettings]()) { result, module in
            result[module.moduleType] = ModuleSettings(moduleType: module.moduleType, order: module.order)
        }
        for moduleType in disabled {
            modules[moduleType] = ModuleSettings(moduleType: moduleType, enabled: false)
        }
        return SDKSettings(modules: modules)
    }

    func test_track_collects_from_all_collectors() {
        let collected = expectation(description: "Collector called")
        collected.expectedFulfillmentCount = 2
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
        _sdkSettings.add(modules: [
            collector1.id: ModuleSettings(moduleId: collector1.id, moduleType: MockCollector.moduleType, rules: "ruleId"),
            collector2.id: ModuleSettings(moduleId: collector2.id, moduleType: MockCollector.moduleType, rules: .not("ruleId"))
        ], loadRules: [
            "ruleId": LoadRule(id: "ruleId", conditions: .just(condition))
        ])
        _ = collector1.onCollect.subscribe { _ in
            collected.fulfill()
        }
        _ = collector2.onCollect.subscribe { _ in
            notCollected.fulfill()
        }
        tracker.track(Dispatch(name: "event_to_drop"), source: .application)
        waitForDefaultTimeout()
    }

    func test_track_waits_until_the_modules_are_ready_before_collecting() {
        let collected = expectation(description: "Collector called")
        _onCollectors.clear() // Back to "the modules haven't been created yet"
        tracker.track(Dispatch(name: "event"), source: .application)
        let collector = MockCollector()
        _ = collector.onCollect.subscribe { _ in
            collected.fulfill()
        }
        _onCollectors.onNext([collector])
        waitForDefaultTimeout()
    }

    func test_track_dispatches_enriched_dispatch() {
        let dispatched = expectation(description: "DispatchManager called")
        _ = mockDispatchManager.onDispatch.subscribeOnce { newDispatch in
            XCTAssertNotNil(newDispatch.payload.getDataItem(key: self.collector1.id))
            XCTAssertNotNil(newDispatch.payload.getDataItem(key: self.collector2.id))
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
        _onCollectors.clear()
        sessionManager.onRegisterDispatch.subscribeOnce { _ in
            registerDispatchCalled.fulfill()
        }
        tracker.track(Dispatch(name: "event"), source: .application)
        waitForDefaultTimeout()
    }

    /// No collector enabled is an answer, unlike no emission at all: the event must not be held back.
    func test_track_dispatches_when_the_modules_are_ready_without_any_collector() {
        let dispatched = expectation(description: "DispatchManager called")
        _onCollectors.onNext([])
        _ = mockDispatchManager.onDispatch.subscribeOnce { _ in
            dispatched.fulfill()
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
        collector1.onCollect
            .subscribeOnce { _ in
                collectionCalled.fulfill()
            }
        tracker.track(Dispatch(name: "event"), source: .application)
        wait(for: [registerDispatchCalled, collectionCalled],
             timeout: Self.defaultTimeout,
             enforceOrder: true)
    }

    func test_track_from_a_module_init_is_enriched_by_the_collectors_of_the_same_pass() throws {
        addTeardownBlock { CallbackOnInitModule.onInit = nil }

        // Pass 1: MockCollector is the only collector.
        moduleManager.updateSettings(context: context,
                                     settings: settings(enabling: [(MockCollector.moduleType, nil)]))

        let mockCollector = try XCTUnwrap(moduleManager.modules.value.first { $0.id == MockCollector.moduleType } as? MockCollector)

        let mockCollectorNotCalled = expectation(description: "MockCollector must not collect once it is disabled")
        mockCollectorNotCalled.isInverted = true
        _ = mockCollector.onCollect.subscribe { _ in
            mockCollectorNotCalled.fulfill()
        }

        let dispatched = expectation(description: "The dispatch reaches the dispatch manager")
        var capturedDispatch: Dispatch?
        _ = mockDispatchManager.onDispatch.subscribeOnce { dispatch in
            capturedDispatch = dispatch
            dispatched.fulfill()
        }

        CallbackOnInitModule.onInit = { [trackerWithModuleManager] in
            trackerWithModuleManager.track(Dispatch(name: "event"), source: .application)
        }

        // Pass 2: MockCollector is disabled. CallbackOnInitModule (order 0) is created and tracks
        // synchronously from its init, before MockCollector2 (order 1) exists in this same pass.
        moduleManager.updateSettings(context: context,
                                     settings: settings(enabling: [(CallbackOnInitModule.moduleType, 0),
                                                                   ("MockCollector2", 1)],
                                                        disabling: [MockCollector.moduleType]))

        let mockCollector2 = try XCTUnwrap(moduleManager.modules.value.first { $0.id == "MockCollector2" } as? MockCollector2)

        XCTAssertTrue(capturedDispatch?.payload.keys.contains(mockCollector2.id) ?? false)
        XCTAssertFalse(capturedDispatch?.payload.keys.contains(mockCollector.id) ?? true)

        waitForDefaultTimeout()
    }
}
