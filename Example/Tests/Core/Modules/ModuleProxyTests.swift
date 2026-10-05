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
    let manager = ModuleManager()
    @ReplaySubject<Result<ModuleManager, TealiumError>> var onModuleManager
    lazy var proxy = ModuleProxy<ModuleWithObservable, Error>(queue: queue,
                                                              onModuleManager: onModuleManager)
    lazy var config: TealiumConfig = mockConfig

    func context() -> TealiumContext {
        MockContext(moduleManager: manager,
                    config: config,
                    databaseProvider: mockDbProvider,
                    queue: queue)
    }

    func settings(moduleEnabled: Bool) -> SDKSettings {
        SDKSettings(modules: [ModuleWithObservable.moduleType: ModuleSettings(moduleType: ModuleWithObservable.moduleType,
                                                                              enabled: moduleEnabled)])
    }

    func test_getModule_waits_for_first_manager_to_be_emitted_and_be_ready_to_report_the_completion() {
        let notCompletedIfNotReady = expectation(description: "GetModule doesn't complete until manager is ready")
        notCompletedIfNotReady.isInverted = true
        let completed = expectation(description: "GetModule completes")
        proxy.getModule { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            notCompletedIfNotReady.fulfill()
            completed.fulfill()
        }
        queue.dispatchQueue.sync {
            _onModuleManager.onNext(.success(manager))
            wait(for: [notCompletedIfNotReady], timeout: Self.defaultTimeout)
            manager.mockReady()
            wait(for: [completed], timeout: Self.defaultTimeout)
        }
    }

    func test_getModule_returns_nil_when_module_is_not_present() {
        let completed = expectation(description: "GetModule completes")
        _onModuleManager.onNext(.success(manager))
        manager.mockReady()
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
        _onModuleManager.onNext(.success(manager))
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
        _onModuleManager.onNext(.success(manager))
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
        _onModuleManager.onNext(.success(manager))
        let subscribable: any Subscribable<Int> = proxy.observeModule(transform: \.someObservable)
        _ = subscribable.subscribe { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            completed.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_observeModule_with_optional_values_emits_nil_values() {
        let emitted = expectation(description: "ObserveModule emits the nil value")
        config.modules = [ModuleWithObservable.factory()]
        manager.updateSettings(context: context(),
                               settings: SDKSettings(config.getEnforcedSDKSettings()))
        _onModuleManager.onNext(.success(manager))
        let subscribable: any Subscribable<Int?> = proxy.observeModule { _ in Observables.just(nil) }
        _ = subscribable.subscribe { value in
            XCTAssertNil(value)
            emitted.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_observeModule_doesnt_emit_transformed_observable_if_module_is_disabled() {
        let completed = expectation(description: "ObserveModule completes")
        completed.isInverted = true
        config.modules = [ModuleWithObservable.factory()]
        manager.updateSettings(context: context(),
                               settings: settings(moduleEnabled: false))
        _onModuleManager.onNext(.success(manager))
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
        _onModuleManager.onNext(.success(manager))
        let subscribable: any Subscribable<Int> = proxy.observeModule(transform: \.someObservable)
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
        _onModuleManager.onNext(.success(manager))
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
        _onModuleManager.onNext(.success(manager))
        let subscribable: any Subscribable<Int> = proxy.observeModule(transform: \.someObservable)
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
        _onModuleManager.onNext(.success(manager))
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
        _onModuleManager.onNext(.success(manager))
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
        _onModuleManager.onNext(.success(manager))
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
        _onModuleManager.onNext(.success(manager))
        let subscribable: any Subscribable<Int> = proxy.observeModule(transform: \.someObservable)
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

    func test_observeModuleResult_emits_success_with_transformed_value_when_module_is_enabled() {
        let completed = expectation(description: "observeModuleResult completes")
        config.modules = [ModuleWithObservable.factory()]
        manager.updateSettings(context: context(),
                               settings: SDKSettings(config.getEnforcedSDKSettings()))
        _onModuleManager.onNext(.success(manager))
        let subscribable: any Subscribable<Result<Int, ModuleError<Error>>> = proxy.observeModuleResult { module in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            return module.someObservable
        }
        _ = subscribable.subscribe { result in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            XCTAssertResultIsSuccess(result) { value in
                XCTAssertEqual(value, 1)
            }
            completed.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_observeModuleResult_emits_nothing_until_modules_are_ready() {
        let notEmittedIfNotReady = expectation(description: "observeModuleResult doesn't emit until modules are ready")
        notEmittedIfNotReady.isInverted = true
        let emitted = expectation(description: "observeModuleResult emits once modules are ready")
        config.modules = [ModuleWithObservable.factory()]
        let subscribable: any Subscribable<Result<Int, ModuleError<Error>>> = proxy.observeModuleResult { module in
            module.someObservable
        }
        _ = subscribable.subscribe { _ in
            notEmittedIfNotReady.fulfill()
            emitted.fulfill()
        }
        queue.dispatchQueue.sync {
            _onModuleManager.onNext(.success(manager))
            wait(for: [notEmittedIfNotReady], timeout: Self.defaultTimeout)
            manager.mockReady()
            wait(for: [emitted], timeout: Self.defaultTimeout)
        }
    }

    func test_observeModuleResult_emits_success_then_moduleNotEnabled_then_success_as_module_is_disabled_and_re_enabled() {
        let completed = expectation(description: "observeModuleResult emits three times")
        completed.expectedFulfillmentCount = 3
        var results: [Result<Int, ModuleError<Error>>] = []
        config.modules = [ModuleWithObservable.factory()]
        manager.updateSettings(context: context(),
                               settings: SDKSettings(config.getEnforcedSDKSettings()))
        _onModuleManager.onNext(.success(manager))
        let subscribable: any Subscribable<Result<Int, ModuleError<Error>>> = proxy.observeModuleResult { module in
            module.someObservable
        }
        _ = subscribable.subscribe { result in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            results.append(result)
            completed.fulfill()
        }
        queue.ensureOnQueue {
            self.manager.updateSettings(context: self.context(),
                                        settings: self.settings(moduleEnabled: false))
            self.manager.updateSettings(context: self.context(),
                                        settings: self.settings(moduleEnabled: true))
        }
        waitOnQueue(queue: queue)
        guard results.count == 3 else {
            XCTFail("Expected 3 results but got \(results)")
            return
        }
        XCTAssertResultIsSuccess(results[0]) { XCTAssertEqual($0, 1) }
        guard case .failure(let firstFailure) = results[1],
              case .moduleNotEnabled(let module) = firstFailure else {
            XCTFail("Expected moduleNotEnabled but got \(results[1])")
            return
        }
        XCTAssertEqual(module, "\(ModuleWithObservable.self)")
        XCTAssertResultIsSuccess(results[2]) { XCTAssertEqual($0, 1) }
    }

    func test_observeModuleResult_emits_tealiumError_then_completes_when_manager_result_fails_with_initializationError() {
        let failed = expectation(description: "observeModuleResult emits tealiumError")
        let completed = expectation(description: "observeModuleResult completes")
        let subscribable: any Subscribable<Result<Int, ModuleError<Error>>> = proxy.observeModuleResult { module in
            module.someObservable
        }
        _ = subscribable.subscribe({ result in
            guard case .failure(.tealiumError(let error)) = result,
                  case .initializationError(let underlyingError) = error else {
                XCTFail("Unexpected result: \(result)")
                return
            }
            XCTAssertTestErrorEquals(underlyingError, .unknown)
            failed.fulfill()
        }, onComplete: {
            completed.fulfill()
        })
        queue.ensureOnQueue {
            self._onModuleManager.onNext(.failure(.initializationError(TestError.unknown)))
            self._onModuleManager.onComplete()
        }
        waitOnQueue(queue: queue)
    }

    func test_observeModuleResult_emits_tealiumError_then_completes_when_manager_result_fails_with_instanceShutdown() {
        let failed = expectation(description: "observeModuleResult emits tealiumError")
        let completed = expectation(description: "observeModuleResult completes")
        let subscribable: any Subscribable<Result<Int, ModuleError<Error>>> = proxy.observeModuleResult { module in
            module.someObservable
        }
        _ = subscribable.subscribe({ result in
            guard case .failure(.tealiumError(let error)) = result,
                  case .instanceShutdown = error else {
                XCTFail("Unexpected result: \(result)")
                return
            }
            failed.fulfill()
        }, onComplete: {
            completed.fulfill()
        })
        queue.ensureOnQueue {
            self._onModuleManager.onNext(.failure(.instanceShutdown))
            self._onModuleManager.onComplete()
        }
        waitOnQueue(queue: queue)
    }
}
