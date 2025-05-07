//
//  ModuleProxy+ExecuteTaskTests.swift
//  tealium-swift
//
//  Created by Den Guzov on 08/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class ModuleProxyExecuteTaskTests: XCTestCase {
    let dbProvider = MockDatabaseProvider()
    let queue = TealiumQueue.worker
    let tracker = MockTracker()
    lazy var manager = ModulesManager(queue: queue)
    lazy var onManager: ReplaySubject<ModulesManager?> = ReplaySubject(initialValue: manager)
    lazy var config: TealiumConfig = mockConfig

    lazy var moduleProxy = ModuleProxy<MockModule>(onModulesManager: onManager.asObservable())
    func context() -> TealiumContext {
        MockContext(modulesManager: manager,
                    config: config,
                    tracker: tracker,
                    databaseProvider: dbProvider,
                    queue: queue)
    }

    override func setUp() {
        config.modules = [DefaultModuleFactory<MockModule>()]
        manager.updateSettings(context: context(), settings: SDKSettings([:]))
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
        manager.updateSettings(context: context(), settings: SDKSettings(modules: [MockModule.id: ModuleSettingsBuilder().setEnabled(false).build()]))
        let errorCaught = expectation(description: "Error caught")
        let single = moduleProxy.executeModuleTask { _ in
        }
        _ = single.subscribe { result in
            guard case .moduleNotEnabled = result.getError() as? TealiumError else {
                XCTFail("Unexpected result: \(result)")
                return
            }
            errorCaught.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_executeModuleAsyncTask_completes_with_error_which_task_has_thrown() {
        let errorCaught = expectation(description: "Error caught")
        let single: any Single<Result<Void, Error>> = moduleProxy.executeModuleAsyncTask { _, completion in
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

    func test_executeModuleAsyncTask_completes_without_error_when_task_completes_successfully() {
        let errorNotCaught = expectation(description: "Error not caught")
        let single: any Single<Result<Void, Error>> = moduleProxy.executeModuleAsyncTask { _, completion in
            completion(.success(()))
        }
        _ = single.subscribe { result in
            XCTAssertNil(result.getError())
            errorNotCaught.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    func test_executeModuleAsyncTask_completes_with_moduleNotEnabled_error_when_module_disabled() {
        manager.updateSettings(context: context(), settings: SDKSettings(modules: [MockModule.id: ModuleSettingsBuilder().setEnabled(false).build()]))
        let errorCaught = expectation(description: "Error caught")
        let single: any Single<Result<Void, Error>> = moduleProxy.executeModuleAsyncTask { _, completion in
            completion(.success(()))
        }
        _ = single.subscribe { result in
            guard case .moduleNotEnabled = result.getError() as? TealiumError else {
                XCTFail("Unexpected result: \(result)")
                return
            }
            errorCaught.fulfill()
        }
        waitOnQueue(queue: queue)
    }
}
