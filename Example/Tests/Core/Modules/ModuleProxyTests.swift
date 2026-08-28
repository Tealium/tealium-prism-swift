//
//  ModuleProxyTests.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 12/11/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ModuleProxyTests: XCTestCase {
    class ModuleWithObservable: MockModule {
        let someObservable = Observables.just(1)
    }
    let mockDbProvider = MockDatabaseProvider()
    let queue = TealiumQueue.worker
    lazy var manager = ModuleManager(queue: queue)
    @ReplaySubject<ModuleManager?> var onModuleManager
    lazy var proxy = ModuleProxy<ModuleWithObservable, Error>(queue: queue,
                                                              onModuleManager: onModuleManager)
    lazy var config: TealiumConfig = mockConfig

    func context() -> TealiumContext {
        MockContext(moduleManager: ModuleManager(queue: queue),
                    config: config,
                    databaseProvider: mockDbProvider,
                    queue: queue)
    }

    func settings(moduleEnabled: Bool) -> SDKSettings {
        SDKSettings(modules: [ModuleWithObservable.moduleType: ModuleSettings(moduleType: ModuleWithObservable.moduleType,
                                                                              enabled: moduleEnabled)])
    }

    func test_getModule_waits_for_first_manager_to_be_emitted_to_report_the_completion() {
        let completed = expectation(description: "GetModule completes")
        proxy.getModule { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            completed.fulfill()
        }
        queue.dispatchQueue.sync {
            _onModuleManager.onNext(manager)
            waitForDefaultTimeout()
        }
    }

    func test_getModule_returns_nil_when_module_is_not_present() {
        let completed = expectation(description: "GetModule completes")
        _onModuleManager.onNext(manager)
        proxy.getModule { module in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            XCTAssertNil(module)
            completed.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_getModule_returns_module_when_module_is_present() {
        let completed = expectation(description: "GetModule completes")
        config.modules = [ModuleWithObservable.factory()]
        manager.updateSettings(context: context(),
                               settings: SDKSettings(config.getEnforcedSDKSettings()))
        _onModuleManager.onNext(manager)
        proxy.getModule { module in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            XCTAssertNotNil(module)
            completed.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_observeModule_emits_transformed_observable_when_module_is_present() {
        let completed = expectation(description: "ObserveModule completes")
        config.modules = [ModuleWithObservable.factory()]
        manager.updateSettings(context: context(),
                               settings: SDKSettings(config.getEnforcedSDKSettings()))
        _onModuleManager.onNext(manager)
        let subscribable: any Subscribable<Int> = proxy.observeModule { module in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            return module.someObservable
        }
        _ = subscribable.subscribe { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            completed.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_observeModule_with_keyPath_emits_transformed_observable_when_module_is_present() {
        let completed = expectation(description: "ObserveModule completes")
        config.modules = [ModuleWithObservable.factory()]
        manager.updateSettings(context: context(),
                               settings: SDKSettings(config.getEnforcedSDKSettings()))
        _onModuleManager.onNext(manager)
        let subscribable: any Subscribable<Int> = proxy.observeModule(\.someObservable)
        _ = subscribable.subscribe { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            completed.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_observeModule_doesnt_emit_transformed_observable_if_module_is_disabled() {
        let completed = expectation(description: "ObserveModule completes")
        completed.isInverted = true
        config.modules = [ModuleWithObservable.factory()]
        manager.updateSettings(context: context(),
                               settings: settings(moduleEnabled: false))
        _onModuleManager.onNext(manager)
        let subscribable: any Subscribable<Int> = proxy.observeModule { module in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            return module.someObservable
        }
        _ = subscribable.subscribe { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            completed.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_observeModule_with_keyPath_doesnt_emit_transformed_observable_if_module_is_disabled() {
        let completed = expectation(description: "ObserveModule completes")
        completed.isInverted = true
        config.modules = [ModuleWithObservable.factory()]
        manager.updateSettings(context: context(),
                               settings: settings(moduleEnabled: false))
        _onModuleManager.onNext(manager)
        let subscribable: any Subscribable<Int> = proxy.observeModule(\.someObservable)
        _ = subscribable.subscribe { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            completed.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_observeModule_emits_transformed_observable_after_module_is_enabled() {
        let completed = expectation(description: "ObserveModule completes")
        config.modules = [ModuleWithObservable.factory()]
        manager.updateSettings(context: context(),
                               settings: settings(moduleEnabled: false))
        _onModuleManager.onNext(manager)
        let subscribable: any Subscribable<Int> = proxy.observeModule { module in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            return module.someObservable
        }
        _ = subscribable.subscribe { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            completed.fulfill()
        }
        queue.ensureOnQueue {
            self.manager.updateSettings(context: self.context(),
                                        settings: self.settings(moduleEnabled: true))
        }
        waitOnQueue(queue: queue)
    }

    func test_observeModule_with_keyPath_emits_transformed_observable_after_module_is_enabled() {
        let completed = expectation(description: "ObserveModule completes")
        config.modules = [ModuleWithObservable.factory()]
        manager.updateSettings(context: context(),
                               settings: settings(moduleEnabled: false))
        _onModuleManager.onNext(manager)
        let subscribable: any Subscribable<Int> = proxy.observeModule(\.someObservable)
        _ = subscribable.subscribe { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            completed.fulfill()
        }
        queue.ensureOnQueue {
            self.manager.updateSettings(context: self.context(),
                                        settings: self.settings(moduleEnabled: true))
        }
        waitOnQueue(queue: queue)
    }

    func test_observeModule_emits_transformed_observable_everytime_module_is_enabled() {
        let completed = expectation(description: "ObserveModule completes")
        completed.expectedFulfillmentCount = 2
        config.modules = [ModuleWithObservable.factory()]
        manager.updateSettings(context: context(),
                               settings: settings(moduleEnabled: false))
        _onModuleManager.onNext(manager)
        let subscribable: any Subscribable<Int> = proxy.observeModule { module in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            return module.someObservable
        }
        _ = subscribable.subscribe { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            completed.fulfill()
        }
        queue.ensureOnQueue {
            self.manager.updateSettings(context: self.context(),
                                        settings: self.settings(moduleEnabled: true))
            self.manager.updateSettings(context: self.context(),
                                        settings: self.settings(moduleEnabled: false))
            self.manager.updateSettings(context: self.context(),
                                        settings: self.settings(moduleEnabled: true))
        }
        waitOnQueue(queue: queue)
    }

    /// Registers two instances of `ModuleWithObservable` in the manager.
    func configureTwoInstances() {
        config.modules = [ModuleWithObservable.factory(
            allowsMultipleInstances: true,
            enforcedSettings: MultipleInstancesSettingsBuilder().setModuleId("Instance1").setOrder(1),
            MultipleInstancesSettingsBuilder().setModuleId("Instance2").setOrder(2))]
        manager.updateSettings(context: context(),
                               settings: SDKSettings(config.getEnforcedSDKSettings()))
    }

    func test_observeModules_emits_transform_over_all_registered_instances() {
        let completed = expectation(description: "observeModules emits")
        configureTwoInstances()
        _onModuleManager.onNext(manager)
        let subscribable: any Subscribable<Int> = proxy.observeModules { modules in
            Observables.just(modules.count)
        }
        _ = subscribable.subscribe { count in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            XCTAssertEqual(count, 2)
            completed.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_observeModules_re_emits_when_the_set_of_instances_changes() {
        let completed = expectation(description: "observeModules re-emits")
        completed.expectedFulfillmentCount = 2
        var counts: [Int] = []
        configureTwoInstances()
        _onModuleManager.onNext(manager)
        let subscribable: any Subscribable<Int> = proxy.observeModules { modules in
            Observables.just(modules.count)
        }
        _ = subscribable.subscribe { count in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            counts.append(count)
            completed.fulfill()
        }
        queue.ensureOnQueue {
            self.manager.updateSettings(context: self.context(),
                                        settings: self.settings(moduleEnabled: false))
        }
        waitOnQueue(queue: queue)
        XCTAssertEqual(counts, [2, 0])
    }

    func test_observeModule_with_keyPath_emits_transformed_observable_everytime_module_is_enabled() {
        let completed = expectation(description: "ObserveModule completes")
        completed.expectedFulfillmentCount = 2
        config.modules = [ModuleWithObservable.factory()]
        manager.updateSettings(context: context(),
                               settings: settings(moduleEnabled: false))
        _onModuleManager.onNext(manager)
        let subscribable: any Subscribable<Int> = proxy.observeModule(\.someObservable)
        _ = subscribable.subscribe { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            completed.fulfill()
        }
        queue.ensureOnQueue {
            self.manager.updateSettings(context: self.context(),
                                        settings: self.settings(moduleEnabled: true))
            self.manager.updateSettings(context: self.context(),
                                        settings: self.settings(moduleEnabled: false))
            self.manager.updateSettings(context: self.context(),
                                        settings: self.settings(moduleEnabled: true))
        }
        waitOnQueue(queue: queue)
    }
}
