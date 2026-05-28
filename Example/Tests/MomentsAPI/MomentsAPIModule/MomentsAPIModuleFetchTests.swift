//
//  MomentsAPIModuleFetchTests.swift
//  MomentsAPITests_iOS
//
//  Created by Sebastian Krajna on 6/11/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class MomentsAPIModuleFetchTests: MomentsAPIModuleBaseTests {

    func test_fetchEngineResponse_calls_service_when_visitorID_is_valid() throws {
        let expectation = expectation(description: "Service is called successfully")
        try mockNetworkHelper.encodeResult(EngineResponse())
        module.fetchEngineResponse(engineID: "test-engine") { result in
            XCTAssertResultIsSuccess(result) { _ in
                expectation.fulfill()
            }
        }
        waitForDefaultTimeout()
    }

    func test_fetchEngineResponse_allows_multiple_concurrent_requests() throws {
        let firstRequestCompleted = expectation(description: "First request completes")
        let secondExpectation = expectation(description: "Second request completes")

        // Add delay so first request takes time to complete
        mockNetworkHelper.delay = 10 // 10ms delay
        try mockNetworkHelper.encodeResult(EngineResponse())

        // Start first request - it will have delay
        module.fetchEngineResponse(engineID: "engine1") { result in
            // First request will complete (module allows concurrent requests)
            XCTAssertResultIsSuccess(result) { _ in
                firstRequestCompleted.fulfill()
            }
        }

        // Start second request immediately (module doesn't cancel first, both will complete)
        mockNetworkHelper.delay = nil
        try mockNetworkHelper.encodeResult(EngineResponse())
        module.fetchEngineResponse(engineID: "engine2") { result in
            XCTAssertResultIsSuccess(result) { _ in
                secondExpectation.fulfill()
            }
        }

        waitForExpectations(timeout: 1.0)
    }
}
