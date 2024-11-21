//
//  ModuleProxyTests.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/11/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class ModuleProxyTests: XCTestCase {
    class ModuleWithObservable: MockModule {
        let someObservable = Observable<Int>.Just(1)
    }
    let mockDbProvider = MockDatabaseProvider()
    let queue = TealiumQueue.worker
    lazy var manager = ModulesManager(queue: queue)
    @ToAnyObservable<ReplaySubject<ModulesManager?>>(ReplaySubject<ModulesManager?>())
    var onModulesManager: Observable<ModulesManager?>
    lazy var proxy = ModuleProxy<ModuleWithObservable>(onModulesManager: onModulesManager)
    lazy var config: TealiumConfig = mockConfig
    func context() -> TealiumContext {
        TealiumContext(modulesManager: ModulesManager(queue: queue),
                       config: config,
                       coreSettings: StateSubject(CoreSettings(coreDataObject: [:])).toStatefulObservable(),
                       tracker: MockTracker(),
                       barrierRegistry: BarrierCoordinator(registeredBarriers: [], onScopedBarriers: .Just([])),
                       transformerRegistry: TransformerCoordinator(registeredTransformers: [],
                                                                   scopedTransformations: StateSubject([]).toStatefulObservable(),
                                                                   queue: queue),
                       databaseProvider: mockDbProvider,
                       moduleStoreProvider: ModuleStoreProvider(databaseProvider: mockDbProvider,
                                                                modulesRepository: MockModulesRepository()),
                       logger: nil,
                       networkHelper: MockNetworkHelper(),
                       activityListener: ApplicationStatusListener.shared,
                       queue: queue,
                       visitorId: mockVisitorId)
    }

    func test_getModule_waits_for_first_manager_to_be_published_to_report_the_completion() {
        let completed = expectation(description: "GetModule completes")
        proxy.getModule { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            completed.fulfill()
        }
        queue.dispatchQueue.sync {
            _onModulesManager.publish(manager)
            waitForDefaultTimeout()
        }
    }

    func test_getModule_returns_nil_when_module_is_not_present() {
        let completed = expectation(description: "GetModule completes")
        _onModulesManager.publish(manager)
        proxy.getModule { module in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            XCTAssertNil(module)
            completed.fulfill()
        }
        queue.dispatchQueue.sync {
            waitForDefaultTimeout()
        }
    }

    func test_getModule_returns_module_when_module_is_present() {
        let completed = expectation(description: "GetModule completes")
        config.modules = [ModuleWithObservable.factory]
        manager.updateSettings(context: context(),
                               settings: SDKSettings(modulesSettings: [:]))
        _onModulesManager.publish(manager)
        proxy.getModule { module in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            XCTAssertNotNil(module)
            completed.fulfill()
        }
        queue.dispatchQueue.sync {
            waitForDefaultTimeout()
        }
    }

    func test_observeModule_emits_transformed_observable_when_module_is_present() {
        let completed = expectation(description: "ObserveModule completes")
        config.modules = [ModuleWithObservable.factory]
        manager.updateSettings(context: context(),
                               settings: SDKSettings(modulesSettings: [:]))
        _onModulesManager.publish(manager)
        let subscribable: any Subscribable<Int> = proxy.observeModule { module in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            return module.someObservable
        }
        _ = subscribable.subscribe { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            completed.fulfill()
        }
        queue.dispatchQueue.sync {
            waitForDefaultTimeout()
        }
    }

    func test_observeModule_with_keyPath_emits_transformed_observable_when_module_is_present() {
        let completed = expectation(description: "ObserveModule completes")
        config.modules = [ModuleWithObservable.factory]
        manager.updateSettings(context: context(),
                               settings: SDKSettings(modulesSettings: [:]))
        _onModulesManager.publish(manager)
        let subscribable: any Subscribable<Int> = proxy.observeModule(\.someObservable)
        _ = subscribable.subscribe { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            completed.fulfill()
        }
        queue.dispatchQueue.sync {
            waitForDefaultTimeout()
        }
    }

    func test_observeModule_doesnt_emit_transformed_observable_if_module_is_disabled() {
        let completed = expectation(description: "ObserveModule completes")
        completed.isInverted = true
        config.modules = [ModuleWithObservable.factory]
        manager.updateSettings(context: context(),
                               settings: SDKSettings(modulesSettings: ["MockModule": ["enabled": false]]))
        _onModulesManager.publish(manager)
        let subscribable: any Subscribable<Int> = proxy.observeModule { module in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            return module.someObservable
        }
        _ = subscribable.subscribe { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            completed.fulfill()
        }
        queue.dispatchQueue.sync {
            waitForDefaultTimeout()
        }
    }

    func test_observeModule_with_keyPath_doesnt_emit_transformed_observable_if_module_is_disabled() {
        let completed = expectation(description: "ObserveModule completes")
        completed.isInverted = true
        config.modules = [ModuleWithObservable.factory]
        manager.updateSettings(context: context(),
                               settings: SDKSettings(modulesSettings: ["MockModule": ["enabled": false]]))
        _onModulesManager.publish(manager)
        let subscribable: any Subscribable<Int> = proxy.observeModule(\.someObservable)
        _ = subscribable.subscribe { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            completed.fulfill()
        }
        queue.dispatchQueue.sync {
            waitForDefaultTimeout()
        }
    }

    func test_observeModule_emits_transformed_observable_after_module_is_enabled() {
        let completed = expectation(description: "ObserveModule completes")
        config.modules = [ModuleWithObservable.factory]
        manager.updateSettings(context: context(),
                               settings: SDKSettings(modulesSettings: ["MockModule": ["enabled": false]]))
        _onModulesManager.publish(manager)
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
                                        settings: SDKSettings(modulesSettings: ["MockModule": ["enabled": true]]))
        }
        queue.dispatchQueue.sync {
            waitForDefaultTimeout()
        }
    }

    func test_observeModule_with_keyPath_emits_transformed_observable_after_module_is_enabled() {
        let completed = expectation(description: "ObserveModule completes")
        config.modules = [ModuleWithObservable.factory]
        manager.updateSettings(context: context(),
                               settings: SDKSettings(modulesSettings: ["MockModule": ["enabled": false]]))
        _onModulesManager.publish(manager)
        let subscribable: any Subscribable<Int> = proxy.observeModule(\.someObservable)
        _ = subscribable.subscribe { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            completed.fulfill()
        }
        queue.ensureOnQueue {
            self.manager.updateSettings(context: self.context(),
                                        settings: SDKSettings(modulesSettings: ["MockModule": ["enabled": true]]))
        }
        queue.dispatchQueue.sync {
            waitForDefaultTimeout()
        }
    }

    func test_observeModule_emits_transformed_observable_everytime_module_is_enabled() {
        let completed = expectation(description: "ObserveModule completes")
        completed.expectedFulfillmentCount = 2
        config.modules = [ModuleWithObservable.factory]
        manager.updateSettings(context: context(),
                               settings: SDKSettings(modulesSettings: ["MockModule": ["enabled": false]]))
        _onModulesManager.publish(manager)
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
                                        settings: SDKSettings(modulesSettings: ["MockModule": ["enabled": true]]))
            self.manager.updateSettings(context: self.context(),
                                        settings: SDKSettings(modulesSettings: ["MockModule": ["enabled": false]]))
            self.manager.updateSettings(context: self.context(),
                                        settings: SDKSettings(modulesSettings: ["MockModule": ["enabled": true]]))
        }
        queue.dispatchQueue.sync {
            waitForDefaultTimeout()
        }
    }

    func test_observeModule_with_keyPath_emits_transformed_observable_everytime_module_is_enabled() {
        let completed = expectation(description: "ObserveModule completes")
        completed.expectedFulfillmentCount = 2
        config.modules = [ModuleWithObservable.factory]
        manager.updateSettings(context: context(),
                               settings: SDKSettings(modulesSettings: ["MockModule": ["enabled": false]]))
        _onModulesManager.publish(manager)
        let subscribable: any Subscribable<Int> = proxy.observeModule(\.someObservable)
        _ = subscribable.subscribe { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            completed.fulfill()
        }
        queue.ensureOnQueue {
            self.manager.updateSettings(context: self.context(),
                                        settings: SDKSettings(modulesSettings: ["MockModule": ["enabled": true]]))
            self.manager.updateSettings(context: self.context(),
                                        settings: SDKSettings(modulesSettings: ["MockModule": ["enabled": false]]))
            self.manager.updateSettings(context: self.context(),
                                        settings: SDKSettings(modulesSettings: ["MockModule": ["enabled": true]]))
        }
        queue.dispatchQueue.sync {
            waitForDefaultTimeout()
        }
    }
}
