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
    lazy var manager = ModulesManager(queue: queue)
    lazy var onManager = ReplaySubject<ModulesManager?>(manager)
    lazy var config: TealiumConfig = mockConfig

    lazy var moduleProxy = ModuleProxy<MockModule>(queue: queue,
                                                   onModulesManager: onManager.asObservable())
    func context() -> TealiumContext {
        MockContext(modulesManager: manager,
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
            throw TealiumError.genericError("test error")
        }
        _ = single.subscribe { result in
            guard case .genericError("test error") = result.getError() as? TealiumError else {
                XCTFail("Unexpected result: \(result)")
                return
            }
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
            guard case .moduleNotEnabled(let mockModule) = result.getError() as? TealiumError else {
                XCTFail("Unexpected result: \(result)")
                return
            }
            XCTAssertTrue(mockModule == MockModule.self)
            errorCaught.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_executeAsyncModuleTask_completes_with_error_which_task_has_thrown() {
        let errorCaught = expectation(description: "Error caught")
        let single: SingleResult<Void> = moduleProxy.executeAsyncModuleTask { _, completion in
            completion(.failure(TealiumError.genericError("test error")))
        }
        _ = single.subscribe { result in
            guard case .genericError("test error") = result.getError() as? TealiumError else {
                XCTFail("Unexpected result: \(result)")
                return
            }
            errorCaught.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_executeAsyncModuleTask_completes_without_error_when_task_completes_successfully() {
        let errorNotCaught = expectation(description: "Error not caught")
        let single: SingleResult<Void> = moduleProxy.executeAsyncModuleTask { _, completion in
            completion(.success(()))
        }
        _ = single.subscribe { result in
            XCTAssertNil(result.getError())
            errorNotCaught.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_executeAsyncModuleTask_completes_with_moduleNotEnabled_error_when_module_disabled() {
        manager.updateSettings(context: context(), settings: SDKSettings(modules: [
            MockModule.moduleType: ModuleSettings(moduleType: MockModule.moduleType,
                                                  enabled: false)
        ]))
        let errorCaught = expectation(description: "Error caught")
        let single: SingleResult<Void> = moduleProxy.executeAsyncModuleTask { _, completion in
            completion(.success(()))
        }
        _ = single.subscribe { result in
            guard case .moduleNotEnabled(let mockModule) = result.getError() as? TealiumError else {
                XCTFail("Unexpected result: \(result)")
                return
            }
            XCTAssertTrue(mockModule == MockModule.self)
            errorCaught.fulfill()
        }
        waitOnQueue(queue: queue)
    }
}
