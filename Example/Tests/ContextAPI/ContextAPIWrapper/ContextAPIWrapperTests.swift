//
//  ContextAPIWrapperTests.swift
//  ContextAPITests_iOS
//
//  Created by Sebastian Krajna on 6/11/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ContextAPIWrapperTests: XCTestCase {
    let queue = TealiumQueue.worker
    let mockNetworkHelper = MockNetworkHelper()
    let manager = ModuleManager()
    lazy var onManager = ReplaySubject<Result<ModuleManager, TealiumError>>(.success(manager))
    lazy var config: TealiumConfig = mockConfig
    lazy var wrapper = ContextAPIWrapper(
        moduleProxy: ModuleProxy<ContextAPIModule, ContextAPIError>(
            queue: queue,
            onModuleManager: onManager.asObservable()
        )
    )

    func context() -> TealiumContext {
        MockContext(
            moduleManager: manager,
            config: config,
            networkHelper: mockNetworkHelper
        )
    }

    override func setUp() {
        super.setUp()
        // ContextAPI reads the visitor ID from the VisitorId module through the ModuleManager
        config.modules = [Modules.contextAPI(), Modules.visitorId()]
        let contextAPISettings = ModuleSettings(
            moduleType: ContextAPIModule.moduleType,
            configuration: [ContextAPIConfiguration.Keys.region: ContextAPIRegion.AWSRegion.usEast1]
        )
        let visitorIdSettings = ModuleSettings(moduleType: Modules.Types.visitorId)
        manager.updateSettings(context: context(), settings: SDKSettings(modules: [
            contextAPISettings.moduleId: contextAPISettings,
            visitorIdSettings.moduleId: visitorIdSettings
        ]))
    }

    func test_fetchEngineResponse_completes_successfully() throws {
        let expectation = expectation(description: "Fetch completes successfully")

        let mockResponse = EngineResponse(
            audiences: ["audience1"],
            badges: ["badge1"],
            flags: ["isVip": true],
            dates: nil,
            metrics: nil,
            properties: ["segment": "premium"]
        )
        try mockNetworkHelper.encodeResult(mockResponse)

        _ = wrapper.fetchEngineResponse(engineID: "test-engine").subscribe { result in
            XCTAssertResultIsSuccess(result) { response in
                XCTAssertEqual(response.audiences, ["audience1"])
                XCTAssertEqual(response.badges, ["badge1"])
                XCTAssertEqual(response.flags?["isVip"], true)
                XCTAssertEqual(response.properties?["segment"], "premium")
                expectation.fulfill()
            }
        }
        waitOnQueue(queue: queue)
    }

    func test_fetchEngineResponse_handles_error() {
        let expectation = expectation(description: "Fetch completes with error")
        mockNetworkHelper.setError(.urlError(URLError(.notConnectedToInternet)))

        _ = wrapper.fetchEngineResponse(engineID: "test-engine").subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .underlyingError(let contextAPIError) = error,
                      case .networkError = contextAPIError else {
                    XCTFail("Expected networkError, got \(result)")
                    return
                }
                expectation.fulfill()
            }
        }
        waitOnQueue(queue: queue)
    }

    func test_fetchEngineResponse_reports_moduleNotEnabled_when_module_not_present() {
        let expectation = expectation(description: "Fetch reports module not enabled")

        // Create a new manager without the module
        let managerWithoutModule = ModuleManager()
        managerWithoutModule.mockReady()
        let onManagerWithoutModule = ReplaySubject<Result<ModuleManager, TealiumError>>(.success(managerWithoutModule))
        let wrapperWithoutModule = ContextAPIWrapper(
            moduleProxy: ModuleProxy<ContextAPIModule, ContextAPIError>(
                queue: queue,
                onModuleManager: onManagerWithoutModule.asObservable()
            )
        )

        _ = wrapperWithoutModule.fetchEngineResponse(engineID: "test-engine").subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .moduleNotEnabled(let module) = error else {
                    XCTFail("Expected moduleNotEnabled error, got \(error)")
                    return
                }
                XCTAssertEqual(module, ContextAPIModule.moduleType)
                expectation.fulfill()
            }
        }

        waitOnQueue(queue: queue)
    }

    func test_fetchEngineResponse_reports_moduleNotEnabled_when_module_disabled() {
        let expectation = expectation(description: "Fetch reports module not enabled")

        let contextAPISettings = ModuleSettings(
            moduleType: ContextAPIModule.moduleType,
            enabled: false,
            configuration: [:]
        )
        manager.updateSettings(context: context(), settings: SDKSettings(modules: [
            contextAPISettings.moduleId: contextAPISettings
        ]))

        _ = wrapper.fetchEngineResponse(engineID: "test-engine").subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .moduleNotEnabled(let module) = error else {
                    XCTFail("Expected moduleNotEnabled error, got \(result)")
                    return
                }
                XCTAssertEqual(module, ContextAPIModule.moduleType)
                expectation.fulfill()
            }
        }

        waitOnQueue(queue: queue)
    }

    /// The module reports a `ModuleError` already, so the wrapper hands it over untouched.
    func test_fetchEngineResponse_reports_moduleNotEnabled_when_visitorId_module_disabled() {
        let expectation = expectation(description: "Fetch reports VisitorId not enabled")

        let contextAPISettings = ModuleSettings(
            moduleType: ContextAPIModule.moduleType,
            configuration: [ContextAPIConfiguration.Keys.region: ContextAPIRegion.AWSRegion.usEast1]
        )
        let visitorIdSettings = ModuleSettings(moduleType: Modules.Types.visitorId, enabled: false)
        manager.updateSettings(context: context(), settings: SDKSettings(modules: [
            contextAPISettings.moduleId: contextAPISettings,
            visitorIdSettings.moduleId: visitorIdSettings
        ]))

        _ = wrapper.fetchEngineResponse(engineID: "test-engine").subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .moduleNotEnabled(let module) = error else {
                    XCTFail("Expected moduleNotEnabled error, got \(error)")
                    return
                }
                XCTAssertEqual(module, Modules.Types.visitorId)
                expectation.fulfill()
            }
        }

        waitOnQueue(queue: queue)
    }

    func test_fetchEngineResponse_reports_moduleShutdown_when_module_is_shut_down() {
        let expectation = expectation(description: "Fetch reports module shutdown")
        // Shut the module down without a settings pass, so the wrapper still reaches it.
        manager.getModule(ContextAPIModule.self)?.shutdown()

        _ = wrapper.fetchEngineResponse(engineID: "test-engine").subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                XCTAssertContextAPIShutdown(error)
            }
            expectation.fulfill()
        }

        waitOnQueue(queue: queue)
    }

    func test_fetchEngineResponse_handles_http_error() {
        let expectation = expectation(description: "Fetch completes with HTTP error")
        mockNetworkHelper.setError(.non200Status(400, nil))

        _ = wrapper.fetchEngineResponse(engineID: "test-engine").subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case let .underlyingError(underlying) = error,
                      case let .networkError(networkError) = underlying,
                      case let .non200Status(status, _) = networkError.type else {
                    XCTFail("Expected non 200 status error, got \(result)")
                    return
                }
                XCTAssertEqual(status, 400)
                expectation.fulfill()
            }
        }
        waitOnQueue(queue: queue)
    }

    func test_fetchEngineResponse_handles_json_parsing_error() {
        let expectation = expectation(description: "Fetch completes with JSON parsing error")

        let networkResponse = NetworkResponse(
            data: Data("invalid json".utf8),
            urlResponse: .successful()
        )
        mockNetworkHelper.result = .success(networkResponse)

        _ = wrapper.fetchEngineResponse(engineID: "test-engine").subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .underlyingError(let contextAPIError) = error,
                      case .networkError(let networkError) = contextAPIError,
                      case .unknown(let decodingError) = networkError.type else {
                    XCTFail("Expected networkError, got \(result)")
                    return
                }
                XCTAssertTrue(decodingError is DecodingError)
                expectation.fulfill()
            }
        }
        waitOnQueue(queue: queue)
    }
}
