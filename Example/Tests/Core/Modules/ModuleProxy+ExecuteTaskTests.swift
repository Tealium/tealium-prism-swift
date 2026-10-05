//
//  ModuleProxy+ExecuteTaskTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 08/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ModuleProxyExecuteTaskTests: XCTestCase {
    let dbProvider = MockDatabaseProvider()
    let queue = TealiumQueue.worker
    let tracker = MockTracker()
    let manager = ModuleManager()
    lazy var onManager = ReplaySubject<Result<ModuleManager, TealiumError>>(.success(manager))
    lazy var config: TealiumConfig = mockConfig

    lazy var moduleProxy = ModuleProxy<MockModule, Error>(queue: queue,
                                                          onModuleManager: onManager.asObservable())
    func context() -> TealiumContext {
        MockContext(moduleManager: manager,
                    config: config,
                    tracker: tracker,
                    databaseProvider: dbProvider,
                    queue: queue)
    }

    override func setUp() {
        config.modules = [MockModule.factory()]
        manager.updateSettings(context: context(), settings: SDKSettings(config.getEnforcedSDKSettings()))
    }

    func test_executeModuleTask_completes_with_error_which_task_has_thrown() {
        let errorCaught = expectation(description: "Error caught")
        let single = moduleProxy.executeModuleTask { _ in
            throw TestError.unknown
        }
        _ = single.subscribe { result in
            guard case .underlyingError(let error) = result.getError() else {
                XCTFail("Unexpected result: \(result)")
                return
            }
            XCTAssertTestErrorEquals(error, .unknown)
            errorCaught.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_executeModuleTask_completes_without_error_when_task_completes_successfully() {
        let errorNotCaught = expectation(description: "Error not caught")
        let single = moduleProxy.executeModuleTask { _ in
        }
        _ = single.subscribe { result in
            XCTAssertNil(result.getError())
            errorNotCaught.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_executeModuleTask_completes_with_moduleNotEnabled_error_when_module_disabled() {
        manager.updateSettings(context: context(),
                               settings: SDKSettings(modules: [
                                MockModule.moduleType: ModuleSettings(moduleType: MockModule.moduleType,
                                                                      enabled: false)
                               ]))
        let errorCaught = expectation(description: "Error caught")
        let single = moduleProxy.executeModuleTask { _ in
        }
        _ = single.subscribe { result in
            guard case .moduleNotEnabled(let mockModule) = result.getError() else {
                XCTFail("Unexpected result: \(result)")
                return
            }
            XCTAssertTrue(mockModule == "\(MockModule.self)")
            errorCaught.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_executeModuleTask_completes_with_moduleNotEnabled_error_when_module_disabled_and_succeeds_after_re_enabled() {
        let errorCaught = expectation(description: "Error caught while module disabled")
        let succeeded = expectation(description: "Task succeeded after module re-enabled")
        func settings(moduleEnabled: Bool) -> SDKSettings {
            SDKSettings(modules: [
                MockModule.moduleType: ModuleSettings(moduleType: MockModule.moduleType,
                                                      enabled: moduleEnabled)
            ])
        }
        queue.ensureOnQueue {
            self.manager.updateSettings(context: self.context(), settings: settings(moduleEnabled: false))
            _ = self.moduleProxy.executeModuleTask { _ in }.subscribe { result in
                guard case .moduleNotEnabled(let mockModule) = result.getError() else {
                    XCTFail("Unexpected result: \(result)")
                    return
                }
                XCTAssertEqual(mockModule, "\(MockModule.self)")
                errorCaught.fulfill()
                self.manager.updateSettings(context: self.context(), settings: settings(moduleEnabled: true))
                _ = self.moduleProxy.executeModuleTask { _ in }.subscribe { result in
                    XCTAssertNil(result.getError())
                    succeeded.fulfill()
                }
            }
        }
        waitOnQueue(queue: queue)
    }

    func test_executeAsyncModuleTask_completes_with_error_which_task_has_thrown() {
        let errorCaught = expectation(description: "Error caught")
        let single: SingleResult<Void, ModuleError<Error>> = moduleProxy.executeAsyncModuleTask { _, completion in
            completion(.failure(ModuleError.underlyingError(TestError.unknown)))
        }
        _ = single.subscribe { result in
            guard case .underlyingError(let error) = result.getError() else {
                XCTFail("Unexpected result: \(result)")
                return
            }
            XCTAssertTestErrorEquals(error, .unknown)
            errorCaught.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_executeAsyncModuleTask_completes_without_error_when_task_completes_successfully() {
        let errorNotCaught = expectation(description: "Error not caught")
        let single: SingleResult<Void, ModuleError<Error>> = moduleProxy.executeAsyncModuleTask { _, completion in
            completion(.success(()))
        }
        _ = single.subscribe { result in
            XCTAssertNil(result.getError())
            errorNotCaught.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_executeModuleTask_completes_with_tealiumError_instanceShutdown_when_manager_result_fails_with_instanceShutdown() {
        let onFailingManager = ReplaySubject<Result<ModuleManager, TealiumError>>(.failure(.instanceShutdown))
        let failingProxy = ModuleProxy<MockModule, Error>(queue: queue, onModuleManager: onFailingManager.asObservable())
        let errorCaught = expectation(description: "Error caught")
        let single = failingProxy.executeModuleTask { _ in }
        _ = single.subscribe { result in
            guard case .tealiumError(let error) = result.getError(), case .instanceShutdown = error else {
                XCTFail("Unexpected result: \(result)")
                return
            }
            errorCaught.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_executeModuleTask_completes_with_tealiumError_initializationError_when_manager_result_fails_with_initializationError() {
        let onFailingManager = ReplaySubject<Result<ModuleManager, TealiumError>>(.failure(.initializationError(TestError.unknown)))
        let failingProxy = ModuleProxy<MockModule, Error>(queue: queue, onModuleManager: onFailingManager.asObservable())
        let errorCaught = expectation(description: "Error caught")
        let single = failingProxy.executeModuleTask { _ in }
        _ = single.subscribe { result in
            guard case .tealiumError(let error) = result.getError(), case .initializationError(let underlyingError) = error else {
                XCTFail("Unexpected result: \(result)")
                return
            }
            XCTAssertTestErrorEquals(underlyingError, .unknown)
            errorCaught.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_executeAsyncModuleTask_completes_with_moduleNotEnabled_error_when_module_disabled() {
        manager.updateSettings(context: context(), settings: SDKSettings(modules: [
            MockModule.moduleType: ModuleSettings(moduleType: MockModule.moduleType,
                                                  enabled: false)
        ]))
        let errorCaught = expectation(description: "Error caught")
        let single: SingleResult<Void, ModuleError<Error>> = moduleProxy.executeAsyncModuleTask { _, completion in
            completion(.success(()))
        }
        _ = single.subscribe { result in
            guard case .moduleNotEnabled(let mockModule) = result.getError() else {
                XCTFail("Unexpected result: \(result)")
                return
            }
            XCTAssertTrue(mockModule == "\(MockModule.self)")
            errorCaught.fulfill()
        }
        waitOnQueue(queue: queue)
    }
}
