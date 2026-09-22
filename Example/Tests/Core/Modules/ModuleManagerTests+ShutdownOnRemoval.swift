//
//  ModuleManagerTests+ShutdownOnRemoval.swift
//  tealium-prism_Tests
//
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

// MARK: shutdown on module removal

extension ModuleManagerTests {

    func test_shutdown_called_to_modules_removed_from_settings() {
        let settings = SDKSettings(config.getEnforcedSDKSettings())
        moduleManager.updateSettings(context: context, settings: settings)
        XCTAssertEqual(moduleManager.modules.value.count, context.config.modules.count)
        let shutdown = expectation(description: "\(MockDispatcher1.moduleType) got shutdown")
        module1?.onShutdown.subscribeOnce { shutdown.fulfill() }
        // The entry is gone from the settings altogether, not present and disabled.
        let remaining = settings.modules.filter { $0.value.moduleType != MockDispatcher1.moduleType }
        moduleManager.updateSettings(context: context, settings: SDKSettings(modules: remaining))
        XCTAssertEqual(moduleManager.modules.value.map { $0.id }, [MockDispatcher2.moduleType])
        waitForDefaultTimeout()
    }

    func test_shutdown_called_to_the_instance_replaced_by_updateConfiguration() {
        config.addModule(ReplacingModule.factory())
        moduleManager.updateSettings(context: context, settings: SDKSettings(config.getEnforcedSDKSettings()))
        guard let oldInstance = moduleManager.getModule(ReplacingModule.self) else { return XCTFail("Not created") }
        let shutdown = expectation(description: "Previous instance got shutdown")
        oldInstance.onShutdown.subscribeOnce { shutdown.fulfill() }
        moduleManager.updateSettings(context: context, settings: SDKSettings(config.getEnforcedSDKSettings()))
        let newInstance = moduleManager.getModule(ReplacingModule.self)
        XCTAssertTrue(newInstance?.id == oldInstance.id && newInstance !== oldInstance)
        XCTAssertFalse(moduleManager.modules.value.contains { $0 === oldInstance })
        waitForDefaultTimeout()
    }

    /// Centralizing the shutdown in `updateSettings` must not make the disabled path shut down twice.
    func test_shutdown_called_exactly_once_to_modules_being_disabled() {
        let settings = SDKSettings(config.getEnforcedSDKSettings())
        moduleManager.updateSettings(context: context, settings: settings)
        let shutdown = expectation(description: "\(MockDispatcher1.moduleType) got shutdown once")
        shutdown.assertForOverFulfill = true
        let disposable = module1?.onShutdown.subscribe { shutdown.fulfill() }
        defer { disposable?.dispose() }
        moduleManager.updateSettings(context: context,
                                     settings: SDKSettings(modules: settings.modules + [
                                        MockDispatcher1.moduleType: ModuleSettings(moduleType: MockDispatcher1.moduleType,
                                                                                   enabled: false)
                                     ]))
        waitForDefaultTimeout()
    }

    /// `updateConfiguration` mutating a module in place must not be confused with it being replaced: only the
    /// latter has to re-emit, which is why `observeModules` compares by instance identity rather than `id`.
    func test_observeModules_re_emits_when_a_module_is_replaced_by_a_new_instance() {
        config.addModule(ReplacingModule.factory())
        var emissions = [[ReplacingModule]]()
        moduleManager.observeModules { $0 as? ReplacingModule }
            .subscribe { emissions.append($0) }
            .addTo(disposer)
        let settings = SDKSettings(config.getEnforcedSDKSettings())
        moduleManager.updateSettings(context: context, settings: settings)
        moduleManager.updateSettings(context: context, settings: settings)
        queue.dispatchQueue.sync { }
        XCTAssertEqual(emissions.count, 2)
        XCTAssertNotIdentical(emissions.last?.first, emissions.first?.first)
    }

    /// Sibling of the above for the single-module transform variant.
    func test_observeModule_with_transform_re_emits_when_the_module_is_replaced() {
        config.addModule(ReplacingModule.factory())
        var emissions = [ReplacingModule?]()
        moduleManager.observeModule { $0 as? ReplacingModule }
            .subscribe { emissions.append($0) }
            .addTo(disposer)
        let settings = SDKSettings(config.getEnforcedSDKSettings())
        moduleManager.updateSettings(context: context, settings: settings)
        moduleManager.updateSettings(context: context, settings: settings)
        queue.dispatchQueue.sync { }
        XCTAssertEqual(emissions.count, 2)
        XCTAssertNotIdentical(emissions.last.flatMap { $0 }, emissions.first.flatMap { $0 })
    }
}

/**
 * Hands back a brand new instance instead of `self` from `updateConfiguration`, the way a module
 * whose configuration change requires reconstruction behaves.
 */
private class ReplacingModule: MockModule {
    override func updateConfiguration(_ configuration: DataObject) -> Self? {
        Self(moduleId: id)
    }
}
