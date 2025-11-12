//
//  Tealium+SettingsTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 15/07/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

enum TestError: Error {
    case fileNotFound(named: String)
}

final class TealiumSettingsTests: TealiumBaseTests {
    override func setUp() {
        settingsFile = "local"
        settingsUrl = "https://www.tealium.com/settings"
        super.setUp()
        config.bundle = Bundle(for: self.classForCoder)
        try? mockRemoteSettings(named: "settings")

    }

    func mockRemoteSettings(named: String) throws {
        guard let path = TealiumFileManager.fullJSONPath(from: Bundle(for: self.classForCoder), relativePath: named)
            else {
            throw TestError.fileNotFound(named: named)
        }
        let jsonData = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        if let url = settingsUrl {
            client.resultMap[url] = .success(.init(data: jsonData, urlResponse: .successful()))
        }
    }

    func test_remote_settings_update_core_settings() {
        let tealiumImplInitialized = expectation(description: "Tealium implementation initialized")
        let settingsUpdated = expectation(description: "Settings updated")
        let teal = createTealium()
        teal.proxy.getProxiedObject { impl in
            guard let impl else {
                XCTFail("Tealium Implementation not created")
                return
            }
            _ = impl.settingsManager.settings.subscribe { settings in
                XCTAssertEqual(settings.core.queueExpiration, 200.seconds)
                settingsUpdated.fulfill()
            }
            tealiumImplInitialized.fulfill()
        }
        waitForLongTimeout()
    }

    func test_remote_settings_can_disable_module() {
        config.addModule(MockDispatcher1.factory())
        let tealiumImplInitialized = expectation(description: "Tealium implementation initialized")
        let teal = createTealium()
        teal.proxy.getProxiedObject { impl in
            guard let impl else {
                XCTFail("Tealium Implementation not created")
                return
            }
            XCTAssertFalse(impl.modulesManager.modules.value.contains { $0 is MockDispatcher1 },
                           "Modules must not contain the disabled modules")
            tealiumImplInitialized.fulfill()
        }
        waitForLongTimeout()
    }

    func test_remote_settings_can_disable_module_after_initially_being_enabled() {
        var completeSettingsRequest: (() -> Void)?
        client.delayBlock = { block in
            completeSettingsRequest = block
        }
        config.addModule(MockDispatcher1.factory())
        let tealiumImplInitialized = expectation(description: "Tealium implementation initialized")
        let modulesListUpdated = expectation(description: "Modules List Updated")
        let teal = createTealium()
        teal.proxy.getProxiedObject { impl in
            guard let impl else {
                XCTFail("Tealium Implementation not created")
                return
            }
            XCTAssertTrue(impl.modulesManager.modules.value.contains { $0 is MockDispatcher1 },
                          "Modules initially contains the module to be disabled")
            guard let completeSettingsRequest else {
                XCTFail("Network Request for Settings should already be performed")
                return
            }
            impl.modulesManager.modules.updates().subscribeOnce { modules in
                XCTAssertFalse(modules.contains { $0 is MockDispatcher1 },
                               "Modules must not contain the disabled modules after the settings update")
                modulesListUpdated.fulfill()
            }
            completeSettingsRequest()
            tealiumImplInitialized.fulfill()
        }
        waitForLongTimeout()
    }

    func test_remote_settings_can_enable_module_after_initially_being_disabled() {
        var completeSettingsRequest: (() -> Void)?
        client.delayBlock = { block in
            completeSettingsRequest = block
        }
        config.addModule(MockDispatcher2.factory())
        let tealiumImplInitialized = expectation(description: "Tealium implementation initialized")
        let modulesListUpdated = expectation(description: "Modules List Updated")
        let teal = createTealium()
        teal.proxy.getProxiedObject { impl in
            guard let impl else {
                XCTFail("Tealium Implementation not created")
                return
            }
            XCTAssertFalse(impl.modulesManager.modules.value.contains { $0 is MockDispatcher2 },
                           "Modules initially must not contain the module to is disabled")
            guard let completeSettingsRequest else {
                XCTFail("Network Request for Settings should already be performed")
                return
            }
            impl.modulesManager.modules.updates().subscribeOnce { modules in
                XCTAssertTrue(modules.contains { $0 is MockDispatcher2 },
                              "Modules must contain the re-enabled modules after the settings update")
                modulesListUpdated.fulfill()
            }
            completeSettingsRequest()
            tealiumImplInitialized.fulfill()
        }
        waitForLongTimeout()
    }

    func test_remote_settings_can_setup_batching_barrier() {
        config.addModule(MockDispatcher2.factory())
        config.addBarrier(Barriers.batching(defaultScopes: []))
        let eventsAreDispatchedInSingleBatch = expectation(description: "Events dispatched in single batch")
        let teal = createTealium()
        MockDispatcher.onDispatch.subscribe { dispatches in
            XCTAssertEqual(dispatches.map { $0.name },
                           ["Event1", "Event2", "Event3"])
            eventsAreDispatchedInSingleBatch.fulfill()
        }.addTo(disposer)
        teal.onReady { teal in
            teal.track("Event1")
            teal.track("Event2")
            teal.track("Event3")
        }
        waitForLongTimeout()
    }

    func test_broken_remote_settings_dont_block_the_library() throws {
        try mockRemoteSettings(named: "brokenSettings")
        let tealiumImplInitialized = expectation(description: "Tealium implementation initialized")
        _ = createTealium { result in
            XCTAssertResultIsSuccess(result)
            tealiumImplInitialized.fulfill()
        }
        waitForLongTimeout()
    }

    func test_loadRules_block_collection_from_collector() {
        let eventDispatched = expectation(description: "Two events are dispatched")
        eventDispatched.expectedFulfillmentCount = 2
        let moduleSettings = CollectorSettingsBuilder()
            .setRules(.not("event_contains_blocked"))
        config.addModule(MockCollector.factory(enforcedSettings: moduleSettings))
        config.addModule(MockDispatcher2.factory())
        MockDispatcher.onDispatch.subscribe { dispatches in
            for dispatch in dispatches {
                if dispatch.name == "event_blocked" {
                    XCTAssertNil(dispatch.payload.getDataItem(key: MockCollector.moduleType))
                } else {
                    XCTAssertEqual(dispatch.payload.get(key: MockCollector.moduleType, as: String.self), "value")
                }
            }
            eventDispatched.fulfill()
        }.addTo(disposer)
        let teal = createTealium()
        teal.track("event_blocked")
        teal.track("event_dispatched")
        waitForLongTimeout()
    }

    func test_loadRules_block_events_for_dispatcher() {
        let eventDispatched = expectation(description: "An event is dispatched")
        let moduleSettings = DispatcherSettingsBuilder()
            .setRules(.not("event_contains_blocked"))
        config.addModule(MockDispatcher2.factory(enforcedSettings: moduleSettings))
        MockDispatcher.onDispatch.subscribe { dispatches in
            XCTAssertEqual(dispatches.map { $0.name }, ["event_dispatched"])
            eventDispatched.fulfill()
        }.addTo(disposer)
        let teal = createTealium()
        teal.track("event_blocked")
        teal.track("event_dispatched")
        waitForLongTimeout()
    }
}
