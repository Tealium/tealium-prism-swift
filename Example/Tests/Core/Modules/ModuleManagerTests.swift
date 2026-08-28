//
//  ModuleManagerTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 25/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ModuleManagerTests: XCTestCase {
    var configModules = [
        MockDispatcher1.factory(),
        MockDispatcher2.factory(allowsMultipleInstances: true)
    ]
    lazy var config = TealiumConfig(account: "test",
                                    profile: "test",
                                    environment: "dev",
                                    modules: configModules,
                                    settingsFile: "",
                                    settingsUrl: nil)
    let databaseProvider = MockDatabaseProvider()
    let queue = TealiumQueue.worker
    lazy var moduleManager = ModuleManager(queue: queue)
    lazy var transformerCoordinator = TransformerCoordinator(transformers: .constant([]),
                                                             transformations: .constant([]),
                                                             queue: .main,
                                                             logger: nil)
    lazy var context = createContext()
    func createContext() -> TealiumContext {
        MockContext(moduleManager: moduleManager,
                    config: config,
                    transformerRegistrar: transformerCoordinator,
                    databaseProvider: databaseProvider,
                    queue: queue)
    }

    var module1: MockDispatcher1? {
        moduleManager.getModule()
    }

    var module2: MockDispatcher2? {
        moduleManager.getModule()
    }

    func test_updateSettings_with_all_settings_initializes_all_modules() {
        moduleManager.updateSettings(context: context, settings: SDKSettings(config.getEnforcedSDKSettings()))
        let initializedModules = moduleManager.modules.value
        XCTAssertEqual(initializedModules.count, context.config.modules.count)
    }

    func test_updateSettings_with_empty_settings_initializes_no_modules() {
        moduleManager.updateSettings(context: context, settings: SDKSettings())
        let initializedModules = moduleManager.modules.value
        XCTAssertEqual(initializedModules.count, 0)
    }

    func test_updateSettings_does_not_initialize_modules_without_settings() {
        moduleManager.updateSettings(context: context, settings: SDKSettings(modules: [
            MockDispatcher1.moduleType: ModuleSettings(moduleType: MockDispatcher1.moduleType)
        ]))
        let initializedModules = moduleManager.modules.value
        XCTAssertEqual(initializedModules.count, 1)
        XCTAssertEqual(initializedModules.map { $0.id }, [MockDispatcher1.moduleType])
    }

    func test_updateSettings_doesnt_initialize_disabled_modules() {
        config.addModule(MockDispatcher.factory(enforcedSettings: ModuleSettingsBuilder().setEnabled(false)))
        moduleManager.updateSettings(context: context, settings: SDKSettings(config.getEnforcedSDKSettings()))
        let initializedModules = moduleManager.modules.value
        XCTAssertEqual(initializedModules.count, context.config.modules.count - 1)
        XCTAssertFalse(initializedModules.contains(where: { $0.id == MockDispatcher.moduleType }))
    }

    func test_updateSettings_sends_new_settings_to_all_modules() {
        moduleManager.updateSettings(context: context, settings: SDKSettings(config.getEnforcedSDKSettings()))
        let initializedModules = moduleManager.modules.value
        XCTAssertEqual(initializedModules.count, context.config.modules.count)
        let updatedSettings = expectation(description: "Every module got settings updated")
        updatedSettings.expectedFulfillmentCount = initializedModules.count
        initializedModules.compactMap { $0 as? MockModule }
            .forEach { module in
                module.moduleConfiguration
                    .updates()
                    .subscribeOnce { _ in
                        updatedSettings.fulfill()
                    }
            }
        moduleManager.updateSettings(context: context, settings: SDKSettings(config.getEnforcedSDKSettings()))
        waitForDefaultTimeout()
    }

    func test_updateSettings_doesnt_send_new_settings_to_modules_being_disabled() {
        let settings = SDKSettings(config.getEnforcedSDKSettings())
        moduleManager.updateSettings(context: context, settings: settings)
        let initializedModules = moduleManager.modules.value
        XCTAssertEqual(initializedModules.count, context.config.modules.count)
        let updatedSettings = expectation(description: "\(MockDispatcher1.moduleType) must not get settings updated even while being disabled")
        updatedSettings.isInverted = true
        module1?.moduleConfiguration.updates().subscribeOnce { _ in
            updatedSettings.fulfill()
        }
        moduleManager.updateSettings(context: context,
                                     settings: SDKSettings(modules: settings.modules + [
                                        MockDispatcher1.moduleType: ModuleSettings(moduleType: MockDispatcher1.moduleType,
                                                                                   enabled: false)
                                     ]))
        waitForDefaultTimeout()
    }

    func test_shutdown_called_to_modules_being_disabled() {
        let settings = SDKSettings(config.getEnforcedSDKSettings())
        moduleManager.updateSettings(context: context, settings: settings)
        let initializedModules = moduleManager.modules.value
        XCTAssertEqual(initializedModules.count, context.config.modules.count)
        let shutdown = expectation(description: "\(MockDispatcher1.moduleType) got shutdown")
        module1?.onShutdown.subscribeOnce {
            shutdown.fulfill()
        }
        moduleManager.updateSettings(context: context,
                                     settings: SDKSettings(modules: settings.modules + [
                                        MockDispatcher1.moduleType: ModuleSettings(moduleType: MockDispatcher1.moduleType,
                                                                                   enabled: false)
                                     ]))
        waitForDefaultTimeout()
    }

    func test_updateSettings_initializes_modules_with_their_own_configuration() {
        configModules = [
            MockDispatcher1.factory(enforcedSettings: ModuleSettingsBuilder().setProperty("value1", key: "key1")),
            MockDispatcher2.factory(allowsMultipleInstances: true, enforcedSettings: ModuleSettingsBuilder().setProperty("value2", key: "key2")),
        ]
        moduleManager.updateSettings(context: context, settings: SDKSettings(config.getEnforcedSDKSettings()))
        let initializedModules = moduleManager.modules.value
        XCTAssertEqual(initializedModules.count, context.config.modules.count)
        XCTAssertEqual(module1?.moduleConfiguration.value, ["key1": "value1"])
        XCTAssertEqual(module2?.moduleConfiguration.value, ["key2": "value2"])
    }

    func test_updateSettings_updates_modules_with_their_own_configuration() {
        let module1SettingsConfiguration: DataObject = ["key1": "value1"]
        let module2SettingsConfiguration: DataObject = ["key2": "value2"]
        moduleManager.updateSettings(context: context, settings: SDKSettings(config.getEnforcedSDKSettings()))
        let initializedModules = moduleManager.modules.value
        XCTAssertEqual(initializedModules.count, context.config.modules.count)
        moduleManager.updateSettings(context: context, settings: SDKSettings(modules: [
            MockDispatcher1.moduleType: ModuleSettings(moduleType: MockDispatcher1.moduleType,
                                                       configuration: module1SettingsConfiguration),
            MockDispatcher2.moduleType: ModuleSettings(moduleType: MockDispatcher2.moduleType,
                                                       configuration: module2SettingsConfiguration)
        ]))
        XCTAssertEqual(module1?.moduleConfiguration.value, module1SettingsConfiguration)
        XCTAssertEqual(module2?.moduleConfiguration.value, module2SettingsConfiguration)
    }

    func test_getModule_returns_module_if_initialized() {
        moduleManager.updateSettings(context: context, settings: SDKSettings(config.getEnforcedSDKSettings()))
        XCTAssertNil(moduleManager.getModule(CollectModule.self))
        XCTAssertNotNil(moduleManager.getModule(MockDispatcher1.self))
    }

    func test_getModule_completes_on_tealiumQueue_with_initialized_module() {
        moduleManager.updateSettings(context: context, settings: SDKSettings(config.getEnforcedSDKSettings()))
        let getModuleCompleted = expectation(description: "GetModule completes")
        moduleManager.getModule { (module: MockDispatcher1?) in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            getModuleCompleted.fulfill()
            XCTAssertNotNil(module)
        }
        waitOnQueue(queue: queue)
    }

    func test_getModule_completes_on_tealiumQueue_with_missing_module() {
        moduleManager.updateSettings(context: context, settings: SDKSettings(config.getEnforcedSDKSettings()))
        let getModuleCompleted = expectation(description: "GetModule completes")
        moduleManager.getModule { (module: CollectModule?) in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            getModuleCompleted.fulfill()
            XCTAssertNil(module)
        }
        waitOnQueue(queue: queue)
    }

    func test_shutdown_removes_all_modules() {
        moduleManager.updateSettings(context: context, settings: SDKSettings(config.getEnforcedSDKSettings()))
        XCTAssertGreaterThan(moduleManager.modules.value.count, 0)
        moduleManager.shutdown()
        XCTAssertEqual(moduleManager.modules.value.count, 0)
    }

    func test_shutdown_clears_retain_cycles() {
        // Could use RetainCycleHelper here but it makes the code harder to read actually
        config.addModule(LeakingModule.factory())
        moduleManager.updateSettings(context: context, settings: SDKSettings(config.getEnforcedSDKSettings()))
#if compiler(>=6.2.3)
        weak let leakingModule = moduleManager.getModule(LeakingModule.self)
        weak let weakManager = moduleManager
#else
        weak var leakingModule = moduleManager.getModule(LeakingModule.self)
        weak var weakManager = moduleManager
#endif
        XCTAssertNotNil(leakingModule)
        moduleManager.shutdown()
        // Clear all properties with references to moduleManager
        moduleManager = ModuleManager(queue: queue)
        context = createContext()
        XCTAssertNil(leakingModule)
        XCTAssertNil(weakManager)
    }

    func test_single_instance_modules_have_id_equal_to_module_type() {
        let ignoredId = "1"
        moduleManager.updateSettings(context: context, settings: SDKSettings(modules: [
            ignoredId: ModuleSettings(moduleId: ignoredId, moduleType: MockDispatcher1.moduleType, order: 1)
        ]))
        let initializedModules = moduleManager.modules.value
        XCTAssertEqual(initializedModules.first?.id, MockDispatcher1.moduleType)
    }

    func test_single_instance_modules_initializes_only_once() {
        let sdkSettings = SDKSettings(config.getEnforcedSDKSettings())
        moduleManager.updateSettings(context: context, settings: SDKSettings(modules: sdkSettings.modules + [
            "1": ModuleSettings(moduleId: "1", moduleType: MockDispatcher1.moduleType, order: 1),
            "2": ModuleSettings(moduleId: "2", moduleType: MockDispatcher1.moduleType, order: 2),

        ]))
        let initializedModules = moduleManager.modules.value
        XCTAssertEqual(initializedModules.map { $0.id },
                       [MockDispatcher1.moduleType, MockDispatcher2.moduleType])
    }

    func test_multiple_instance_modules_use_moduleId_from_settings() {
        let baseModuleID = "otherID"
        moduleManager.updateSettings(context: context, settings: SDKSettings(modules: [
            "\(baseModuleID)-0": ModuleSettings(moduleId: "\(baseModuleID)-0",
                                                moduleType: MockDispatcher1.moduleType,
                                                order: 0),
            "\(baseModuleID)-1": ModuleSettings(moduleId: "\(baseModuleID)-1",
                                                moduleType: MockDispatcher2.moduleType,
                                                order: 1),
            "\(baseModuleID)-2": ModuleSettings(moduleId: "\(baseModuleID)-2",
                                                moduleType: MockDispatcher2.moduleType,
                                                order: 2)
        ]))
        let initializedModules = moduleManager.modules.value
        XCTAssertEqual(initializedModules.map { $0.id },
                       [MockDispatcher1.moduleType, "\(baseModuleID)-1", "\(baseModuleID)-2"])
    }

    func test_multiple_instance_modules_instantiate_only_once_if_module_id_is_the_same() {
        let baseModuleID = "otherID"
        moduleManager.updateSettings(context: context, settings: SDKSettings(modules: [
            "\(baseModuleID)-1": ModuleSettings(moduleId: "\(baseModuleID)-1",
                                                moduleType: MockDispatcher2.moduleType,
                                                order: 1),
            "\(baseModuleID)-2": ModuleSettings(moduleId: "\(baseModuleID)-1",
                                                moduleType: MockDispatcher2.moduleType,
                                                order: 2)
        ]))
        let initializedModules = moduleManager.modules.value
        XCTAssertEqual(initializedModules.map { $0.id }, ["\(baseModuleID)-1"])
    }

    func test_multiple_instance_modules_only_instantiate_once_if_module_id_is_not_defined() {
        let sdkSettings = SDKSettings(config.getEnforcedSDKSettings())
        let baseModuleID = "otherID"
        moduleManager.updateSettings(context: context, settings: SDKSettings(modules: sdkSettings.modules + [
            "\(baseModuleID)-1": ModuleSettings(moduleType: MockDispatcher2.moduleType,
                                                order: 1),
            "\(baseModuleID)-2": ModuleSettings(moduleType: MockDispatcher2.moduleType,
                                                order: 2)
        ]))
        let initializedModules = moduleManager.modules.value
        XCTAssertEqual(initializedModules.map { $0.id }, [MockDispatcher2.moduleType, MockDispatcher1.moduleType])
    }

    func test_multiple_instance_modules_instantiate_every_time_if_only_one_moduleId_is_not_defined() {
        let sdkSettings = SDKSettings(config.getEnforcedSDKSettings())
        let baseModuleID = "otherID"
        moduleManager.updateSettings(context: context, settings: SDKSettings(modules: sdkSettings.modules + [
            "\(baseModuleID)-1": ModuleSettings(moduleType: MockDispatcher2.moduleType,
                                                order: 1),
            "\(baseModuleID)-2": ModuleSettings(moduleId: "\(baseModuleID)-1",
                                                moduleType: MockDispatcher2.moduleType,
                                                order: 2)
        ]))
        let initializedModules = moduleManager.modules.value
        XCTAssertEqual(initializedModules.map { $0.id }, [
            MockDispatcher2.moduleType,
            "\(baseModuleID)-1",
            MockDispatcher1.moduleType
        ])
    }

    func test_modules_are_ordered_following_order_from_settings() {
        let baseModuleID = "otherID"
        moduleManager.updateSettings(context: context, settings: SDKSettings(modules: [
            MockDispatcher1.moduleType: ModuleSettings(moduleType: MockDispatcher1.moduleType,
                                                       order: 0),
            "\(baseModuleID)-2": ModuleSettings(moduleId: "\(baseModuleID)-2",
                                                moduleType: MockDispatcher2.moduleType,
                                                order: 2),
            "\(baseModuleID)-1": ModuleSettings(moduleId: "\(baseModuleID)-1",
                                                moduleType: MockDispatcher2.moduleType,
                                                order: 1)
        ]))
        let initializedModules = moduleManager.modules.value
        XCTAssertEqual(initializedModules.map { $0.id },
                       [MockDispatcher1.moduleType, "\(baseModuleID)-1", "\(baseModuleID)-2"])
    }

    func test_modules_without_order_are_put_last() {
        let baseModuleID = "otherID"
        moduleManager.updateSettings(context: context, settings: SDKSettings(modules: [
            MockDispatcher1.moduleType: ModuleSettings(moduleType: MockDispatcher1.moduleType),
            "\(baseModuleID)-2": ModuleSettings(moduleId: "\(baseModuleID)-2",
                                                moduleType: MockDispatcher2.moduleType,
                                                order: 2),
            "\(baseModuleID)-1": ModuleSettings(moduleId: "\(baseModuleID)-1",
                                                moduleType: MockDispatcher2.moduleType,
                                                order: 1)
        ]))
        let initializedModules = moduleManager.modules.value
        XCTAssertEqual(initializedModules.map { $0.id },
                       ["\(baseModuleID)-1", "\(baseModuleID)-2", MockDispatcher1.moduleType])
    }
}

private class LeakingModule: MockModule {

    override class var moduleType: String { "leaking" }
    let moduleManager: ModuleManager
    let context: TealiumContext
    required init?(moduleId: String = LeakingModule.moduleType,
                   context: TealiumContext,
                   moduleConfiguration: DataObject) {
        self.moduleManager = context.moduleManager
        self.context = context
        super.init(moduleId: Self.moduleType, context: context, moduleConfiguration: moduleConfiguration)
    }

    required init(moduleId: String = MockModule.moduleType) {
        fatalError("init(moduleId:) has not been implemented")
    }
}
