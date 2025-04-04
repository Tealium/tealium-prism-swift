//
//  ModulesManagerTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 25/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class ModulesManagerTests: XCTestCase {
    var config = TealiumConfig(account: "test",
                               profile: "test",
                               environment: "dev",
                               modules: [MockDispatcher1.factory, MockDispatcher2.factory],
                               settingsFile: "",
                               settingsUrl: nil)
    let databaseProvider = MockDatabaseProvider()
    let queue = TealiumQueue.worker
    lazy var modulesManager = ModulesManager(queue: queue)
    @StateSubject(CoreSettings())
    var coreSettings
    lazy var barrierCoordinator = BarrierCoordinator(registeredBarriers: [],
                                                     onScopedBarriers: .Just([]))
    lazy var transformerCoordinator = TransformerCoordinator(transformers: StateSubject([]).toStatefulObservable(),
                                                             transformations: StateSubject([]).toStatefulObservable(),
                                                             queue: .main)
    lazy var context = createContext()
    func createContext() -> TealiumContext {
        TealiumContext(modulesManager: modulesManager,
                       config: config,
                       coreSettings: coreSettings,
                       tracker: MockTracker(),
                       barrierRegistry: barrierCoordinator,
                       transformerRegistry: transformerCoordinator,
                       databaseProvider: databaseProvider,
                       moduleStoreProvider: ModuleStoreProvider(databaseProvider: databaseProvider,
                                                                modulesRepository: MockModulesRepository()),
                       logger: nil,
                       networkHelper: MockNetworkHelper(),
                       activityListener: ApplicationStatusListener.shared,
                       queue: queue,
                       visitorId: mockVisitorId)
    }
    var consentManager: MockConsentManager? {
        modulesManager.getModule()
    }

    var module1: MockDispatcher1? {
        modulesManager.getModule()
    }

    var module2: MockDispatcher2? {
        modulesManager.getModule()
    }

    func test_updateSettings_initializes_all_modules() {
        modulesManager.updateSettings(context: context, settings: SDKSettings(modules: [:]))
        let modules = modulesManager.modules.value
        XCTAssertEqual(modules.count, context.config.modules.count)
    }

    func test_updateSettings_doesnt_initialize_disabled_modules() {
        modulesManager.updateSettings(context: context, settings: SDKSettings(modules: [MockDispatcher1.id: ["enabled": false]]))
        let modules = modulesManager.modules.value
        XCTAssertEqual(modules.count, context.config.modules.count - 1)
        XCTAssertFalse(modules.contains(where: { $0.id == MockDispatcher1.id }))
    }

    func test_updateSettings_changes_list_of_initialized_modules() {
        modulesManager.updateSettings(context: context, settings: SDKSettings(modules: [:]))
        let modules = modulesManager.modules.value
        XCTAssertEqual(modules.count, context.config.modules.count)
        modulesManager.updateSettings(context: context, settings: SDKSettings(modules: [MockDispatcher1.id: ["enabled": false]]))
        let modulesAfterUpdate = modulesManager.modules.value
        XCTAssertEqual(modulesAfterUpdate.count, context.config.modules.count - 1)
        XCTAssertFalse(modulesAfterUpdate.contains(where: { $0.id == MockDispatcher1.id }))
    }

    func test_updateSettings_sends_new_settings_to_all_modules() {
        modulesManager.updateSettings(context: context, settings: SDKSettings(modules: [:]))
        let modules = modulesManager.modules.value
        XCTAssertEqual(modules.count, context.config.modules.count)
        let updatedSettings = expectation(description: "Every module got settings updated")
        updatedSettings.expectedFulfillmentCount = modules.count
        modules.compactMap { $0 as? MockModule }
            .forEach { module in
                module.moduleConfiguration
                    .updates()
                    .subscribeOnce { _ in
                        updatedSettings.fulfill()
                    }
            }
        modulesManager.updateSettings(context: context, settings: SDKSettings(modules: [:]))
        waitForDefaultTimeout()
    }

    func test_updateSettings_doesnt_send_new_settings_to_modules_being_disabled() {
        modulesManager.updateSettings(context: context, settings: SDKSettings(modules: [:]))
        let modules = modulesManager.modules.value
        XCTAssertEqual(modules.count, context.config.modules.count)
        let updatedSettings = expectation(description: "\(MockDispatcher1.id) must not get settings updated even while being disabled")
        updatedSettings.isInverted = true
        module1?.moduleConfiguration.updates().subscribeOnce { _ in
            updatedSettings.fulfill()
        }
        modulesManager.updateSettings(context: context, settings: SDKSettings(modules: [MockDispatcher1.id: ["enabled": false]]))
        waitForDefaultTimeout()
    }

    func test_shutdown_called_to_modules_being_disabled() {
        modulesManager.updateSettings(context: context, settings: SDKSettings(modules: [:]))
        let modules = modulesManager.modules.value
        XCTAssertEqual(modules.count, context.config.modules.count)
        let shutdown = expectation(description: "\(MockDispatcher1.id) got shutdown")
        module1?.onShutdown.subscribeOnce {
            shutdown.fulfill()
        }
        modulesManager.updateSettings(context: context, settings: SDKSettings(modules: [MockDispatcher1.id: ["enabled": false]]))
        waitForDefaultTimeout()
    }

    func test_updateSettings_initializes_modules_with_their_own_configuration() {
        let module1Settings: DataObject = ["configuration": ["key1": "value1"]]
        let module2Settings: DataObject = ["configuration": ["key2": "value2"]]
        modulesManager.updateSettings(context: context, settings: SDKSettings(modules: [
            MockDispatcher1.id: module1Settings,
            MockDispatcher2.id: module2Settings
        ]))
        let modules = modulesManager.modules.value
        XCTAssertEqual(modules.count, context.config.modules.count)
        XCTAssertEqual(module1?.moduleConfiguration.value, ModuleSettings.converter.convert(dataItem: module1Settings.toDataItem())?.configuration)
        XCTAssertEqual(module2?.moduleConfiguration.value, ModuleSettings.converter.convert(dataItem: module2Settings.toDataItem())?.configuration)
    }

    func test_updateSettings_updates_modules_with_their_own_configuration() {
        let module1Settings: DataObject = ["configuration": ["key1": "value1"]]
        let module2Settings: DataObject = ["configuration": ["key2": "value2"]]
        modulesManager.updateSettings(context: context, settings: SDKSettings(modules: [:]))
        let modules = modulesManager.modules.value
        XCTAssertEqual(modules.count, context.config.modules.count)
        modulesManager.updateSettings(context: context, settings: SDKSettings(modules: [
            MockDispatcher1.id: module1Settings,
            MockDispatcher2.id: module2Settings
        ]))
        XCTAssertEqual(module1?.moduleConfiguration.value, ModuleSettings.converter.convert(dataItem: module1Settings.toDataItem())?.configuration)
        XCTAssertEqual(module2?.moduleConfiguration.value, ModuleSettings.converter.convert(dataItem: module2Settings.toDataItem())?.configuration)
    }

    func test_getModule_returns_module_if_initialized() {
        modulesManager.updateSettings(context: context, settings: SDKSettings(modules: [:]))
        XCTAssertNil(modulesManager.getModule(TealiumCollect.self))
        XCTAssertNotNil(modulesManager.getModule(MockDispatcher1.self))
    }

    func test_getModule_completes_on_tealiumQueue_with_initialized_module() {
        modulesManager.updateSettings(context: context, settings: SDKSettings(modules: [:]))
        let getModuleCompleted = expectation(description: "GetModule completes")
        modulesManager.getModule { (module: MockDispatcher1?) in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            getModuleCompleted.fulfill()
            XCTAssertNotNil(module)
        }
        waitOnQueue(queue: queue)
    }

    func test_getModule_completes_on_tealiumQueue_with_missing_module() {
        modulesManager.updateSettings(context: context, settings: SDKSettings(modules: [:]))
        let getModuleCompleted = expectation(description: "GetModule completes")
        modulesManager.getModule { (module: TealiumCollect?) in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            getModuleCompleted.fulfill()
            XCTAssertNil(module)
        }
        waitOnQueue(queue: queue)
    }

    func test_shutdown_removes_all_modules() {
        modulesManager.updateSettings(context: context, settings: SDKSettings())
        XCTAssertGreaterThan(modulesManager.modules.value.count, 0)
        modulesManager.shutdown()
        XCTAssertEqual(modulesManager.modules.value.count, 0)
    }

    func test_shutdown_clears_retain_cycles() {
        // Could use RetainCycleHelper here but it makes the code harder to read actually
        config.addModule(DefaultModuleFactory<LeakingModule>())
        modulesManager.updateSettings(context: context, settings: SDKSettings())
        weak var leakingModule = modulesManager.getModule(LeakingModule.self)
        XCTAssertNotNil(leakingModule)
        weak var weakManager = modulesManager
        modulesManager.shutdown()
        // Clear all properties with references to modulesManager
        modulesManager = ModulesManager(queue: queue)
        context = createContext()
        XCTAssertNil(leakingModule)
        XCTAssertNil(weakManager)
    }
}

private class LeakingModule: MockModule {
    override class var id: String { "leaking" }
    let modulesManager: ModulesManager
    let context: TealiumContext
    required init?(context: TealiumContext, moduleConfiguration: DataObject) {
        self.modulesManager = context.modulesManager
        self.context = context
        super.init(context: context, moduleConfiguration: moduleConfiguration)
    }
}
