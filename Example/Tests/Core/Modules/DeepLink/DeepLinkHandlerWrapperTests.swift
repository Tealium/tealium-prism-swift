//
//  DeepLinkHandlerWrapperTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 16/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class DeepLinkHandlerWrapperTests: XCTestCase {
    let dbProvider = MockDatabaseProvider()
    let queue = TealiumQueue.worker
    lazy var manager = ModuleManager(queue: queue)
    lazy var onManager = ReplaySubject<ModuleManager?>(manager)
    lazy var config: TealiumConfig = mockConfig
    lazy var wrapper = DeepLinkHandlerWrapper(moduleProxy: ModuleProxy(queue: queue,
                                                                       onModuleManager: onManager.asObservable()))

    func context() -> TealiumContext {
        MockContext(moduleManager: manager,
                    config: config,
                    databaseProvider: dbProvider,
                    queue: queue)
    }
    let disposer = AutomaticDisposer()

    override func setUp() {
        config.modules = [Modules.deepLink()]
        manager.updateSettings(context: context(), settings: SDKSettings(config.getEnforcedSDKSettings()))
    }

    func test_handle_calls_module_method_with_referrer() throws {
        let moduleCalledWithParams = expectation(description: "Module's method called with correct params")
        let referrer: Referrer = .app("com.test.app")
        let link = try "https://tealium.com".asUrl()
        manager.getModule(DeepLinkModule.self)?.dataStore.onDataUpdated.subscribe { data in
            guard data.get(key: TealiumDataKey.deepLinkURL) == "https://tealium.com",
                  data.get(key: TealiumDataKey.deepLinkReferrerApp) == "com.test.app" else {
                XCTFail("Invalid deep link URL")
                return
            }
            moduleCalledWithParams.fulfill()
        }.addTo(disposer)
        wrapper.handle(link: link, referrer: referrer)
        waitOnQueue(queue: queue)
    }

    func test_handle_calls_module_method_without_referrer() throws {
        let moduleCalledWithParams = expectation(description: "Module's method called with correct params")
        let link = try "https://tealium.com".asUrl()
        manager.getModule(DeepLinkModule.self)?.dataStore.onDataUpdated.subscribe { data in
            guard data.get(key: TealiumDataKey.deepLinkURL) == "https://tealium.com" else {
                XCTFail("Invalid deep link URL")
                return
            }
            moduleCalledWithParams.fulfill()
        }.addTo(disposer)
        wrapper.handle(link: link)
        waitOnQueue(queue: queue)
    }

    func test_handle_fails_with_moduleNotEnabled_when_trace_is_not_enabled() throws {
        let handled = expectation(description: "Handling completed")
        let link = try "https://tealium.com?tealium_trace_id=123".asUrl()
        wrapper.handle(link: link).subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .moduleNotEnabled(let module) = error else {
                    XCTFail("Error should be moduleNotEnabled, but failed with \(error)")
                    return
                }
                XCTAssertEqual(module, "\(TraceModule.self)")
            }
            handled.fulfill()
        }
        waitOnQueue(queue: queue)
    }

    /// The module reports a `ModuleError` already, so the wrapper hands it over untouched.
    func test_handle_fails_with_moduleShutdown_when_the_module_is_shut_down() throws {
        let handled = expectation(description: "Handling completed")
        let link = try "https://tealium.com?tealium_trace_id=123".asUrl()
        // Shut the module down without a settings pass, so the wrapper still reaches it.
        manager.getModule(DeepLinkModule.self)?.shutdown()
        wrapper.handle(link: link).subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                XCTAssertModuleShutdown(error, module: "\(DeepLinkModule.self)")
            }
            handled.fulfill()
        }
        waitOnQueue(queue: queue)
    }
}
