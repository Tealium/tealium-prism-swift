//
//  MomentsAPIWrapperTests.swift
//  MomentsAPITests_iOS
//
//  Created by Sebastian Krajna on 6/11/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class MomentsAPIWrapperTests: XCTestCase {
    let queue = TealiumQueue.worker
    let mockNetworkHelper = MockNetworkHelper()
    lazy var manager = ModulesManager(queue: queue)
    lazy var onManager = ReplaySubject<ModulesManager?>(manager)
    lazy var config: TealiumConfig = mockConfig
    lazy var wrapper = MomentsAPIWrapper(
        moduleProxy: ModuleProxy<MomentsAPIModule, MomentsAPIError>(
            queue: queue,
            onModulesManager: onManager.asObservable()
        )
    )

    func context() -> TealiumContext {
        MockContext(
            modulesManager: manager,
            config: config,
            networkHelper: mockNetworkHelper
        )
    }

    override func setUp() {
        super.setUp()
        config.modules = [Modules.momentsAPI()]
        let momentsAPISettings = ModuleSettings(
            moduleType: MomentsAPIModule.moduleType,
            configuration: [MomentsAPIConfiguration.Keys.region: MomentsAPIRegion.AWSRegion.usEast1]
        )
        manager.updateSettings(context: context(), settings: SDKSettings(modules: [
            momentsAPISettings.moduleId: momentsAPISettings
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
        waitForLongTimeout()
    }

    func test_fetchEngineResponse_handles_error() {
        let expectation = expectation(description: "Fetch completes with error")
        mockNetworkHelper.result = .failure(.urlError(URLError(.notConnectedToInternet)))

        _ = wrapper.fetchEngineResponse(engineID: "test-engine").subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .underlyingError(let momentsAPIError) = error,
                      case .networkError = momentsAPIError else {
                    XCTFail("Expected networkError, got \(result)")
                    return
                }
                expectation.fulfill()
            }
        }
        waitForLongTimeout()
    }

    func test_fetchEngineResponse_reports_moduleNotEnabled_when_module_not_present() {
        let expectation = expectation(description: "Fetch reports module not enabled")

        // Create a new manager without the module
        let managerWithoutModule = ModulesManager(queue: queue)
        let onManagerWithoutModule = ReplaySubject<ModulesManager?>(managerWithoutModule)
        let wrapperWithoutModule = MomentsAPIWrapper(
            moduleProxy: ModuleProxy<MomentsAPIModule, MomentsAPIError>(
                queue: queue,
                onModulesManager: onManagerWithoutModule.asObservable()
            )
        )

        _ = wrapperWithoutModule.fetchEngineResponse(engineID: "test-engine").subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .moduleNotEnabled(let module) = error else {
                    XCTFail("Expected moduleNotEnabled error, got \(error)")
                    return
                }
                XCTAssertTrue(module == "\(MomentsAPIModule.self)")
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: Self.longTimeout)
    }

    func test_fetchEngineResponse_reports_moduleNotEnabled_when_module_disabled() {
        let expectation = expectation(description: "Fetch reports module not enabled")

        let momentsAPISettings = ModuleSettings(
            moduleType: MomentsAPIModule.moduleType,
            enabled: false,
            configuration: [:]
        )
        manager.updateSettings(context: context(), settings: SDKSettings(modules: [
            momentsAPISettings.moduleId: momentsAPISettings
        ]))

        _ = wrapper.fetchEngineResponse(engineID: "test-engine").subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .moduleNotEnabled(let module) = error,
                      module == "\(MomentsAPIModule.self)" else {
                    XCTFail("Expected moduleNotEnabled error, got \(result)")
                    return
                }
                expectation.fulfill()
            }
        }

        waitForExpectations(timeout: Self.longTimeout)
    }

    func test_fetchEngineResponse_handles_http_error() {
        let expectation = expectation(description: "Fetch completes with HTTP error")
        mockNetworkHelper.result = .failure(.non200Status(400))

        _ = wrapper.fetchEngineResponse(engineID: "test-engine").subscribe { result in
            XCTAssertResultIsFailure(result) { error in
                guard case let .underlyingError(underlying) = error,
                      case let .networkError(networkError) = underlying,
                      case let .non200Status(status) = networkError else {
                    XCTFail("Expected non 200 status error, got \(result)")
                    return
                }
                XCTAssertEqual(status, 400)
                expectation.fulfill()
            }
        }
        waitForLongTimeout()
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
                guard case .underlyingError(let momentsAPIError) = error,
                      case .networkError(let networkError) = momentsAPIError,
                      case .unknown(let decodingError) = networkError else {
                    XCTFail("Expected networkError, got \(result)")
                    return
                }
                XCTAssertTrue(decodingError is DecodingError)
                expectation.fulfill()
            }
        }
        waitForLongTimeout()
    }
}
