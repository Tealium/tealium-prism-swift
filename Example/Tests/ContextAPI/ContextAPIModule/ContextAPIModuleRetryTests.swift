//
//  ContextAPIModuleRetryTests.swift
//  ContextAPITests_iOS
//
//  Created by Enrico Zannini on 28/09/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class ContextAPIModuleRetryTests: XCTestCase {
    let queue = TealiumQueue(label: "contextAPIRetryTestQueue")
    lazy var connectivityManager = MockConnectivityManager(queue: queue)

    override func tearDown() {
        URLProtocolMock.reset()
    }

    func test_context_init_derives_the_client_with_three_attempts_and_no_connectivity_retries() throws {
        let client = MockNetworkClient(result: .success(.successful()))
        let context = MockContext(moduleManager: ModuleManager(), networkClient: client)
        let module = ContextAPIModule(context: context,
                                      moduleConfiguration: [ContextAPIConfiguration.Keys.region: ContextAPIRegion.usEast.rawValue])
        XCTAssertNotNil(module)
        XCTAssertEqual(client.additionalInterceptors.count, 1, "The client should be derived exactly once")
        let interceptors = try XCTUnwrap(client.additionalInterceptors.first)
        XCTAssertEqual(interceptors.count, 1, "Context API should not wait for connectivity")
        let retryInterceptor = try XCTUnwrap(interceptors.first as? RetryableErrorInterceptor)
        XCTAssertEqual(retryInterceptor.maxAttempts, 3)
        XCTAssertEqual(retryInterceptor.maxDelay, 20)
        XCTAssertEqual(retryInterceptor.retryAfterAboveMaxDelay, .giveUp)
        XCTAssertEqual(client.additionalMaxRetryCounts, [nil], "Context API should not limit the total retries")
    }

// URLProtocolMock seems not to be working on watchos
#if !os(watchOS)
    func test_throttled_request_with_retry_after_above_max_delay_fails_after_one_request() {
        URLProtocolMock.reply = .always((Data(), .mock(status: 429, headers: ["Retry-After": "120"]), nil))
        fetchEngineResponse(expectedRequests: 1) { result in
            XCTAssertResultIsFailure(result)
        }
    }

    func test_transient_failure_is_retried_once_and_then_succeeds() throws {
        URLProtocolMock.reply = .list([
            (Data(), .mock(status: 503), nil),
            (try Tealium.jsonEncoder.encode(EngineResponse()), .successful(), nil)
        ])
        fetchEngineResponse(expectedRequests: 2) { result in
            XCTAssertResultIsSuccess(result)
        }
    }

    /// Fetches an engine response through a `ContextAPIModule` whose context has a real `HTTPClient` on `URLProtocolMock`.
    /// The module is built with `init(context:moduleConfiguration:)`, the initializer that derives its retrying client.
    private func fetchEngineResponse(expectedRequests: Int,
                                     file: StaticString = #filePath,
                                     line: UInt = #line,
                                     verify: @escaping (Result<EngineResponse, ModuleError<ContextAPIError>>) -> Void) {
        let networkConfiguration = NetworkConfiguration(sessionConfiguration: NetworkConfiguration.defaultUrlSessionConfiguration,
                                                        interceptors: [connectivityManager],
                                                        queue: queue)
        networkConfiguration.sessionConfiguration.protocolClasses = [URLProtocolMock.self]
        let requestSent = expectation(description: "The request is sent \(expectedRequests) times")
        requestSent.expectedFulfillmentCount = expectedRequests
        URLProtocolMock.recordingRequests { _ in requestSent.fulfill() }
        let context = MockContext(moduleManager: ModuleManager(initialModules: [MockVisitorIdModule(visitorId: "testVisitorId")]),
                                  networkClient: HTTPClient(configuration: networkConfiguration, logger: nil),
                                  connectivityManager: connectivityManager,
                                  queue: queue)
        let module = ContextAPIModule(context: context,
                                      moduleConfiguration: [ContextAPIConfiguration.Keys.region: ContextAPIRegion.usEast.rawValue])
        XCTAssertNotNil(module, file: file, line: line)
        let fetchCompleted = expectation(description: "The fetch completes")
        module?.fetchEngineResponse(engineID: "test-engine") { result in
            verify(result)
            fetchCompleted.fulfill()
        }
        // The jittered retry can wait up to 0.1s on top of the URLSession round trips, more than the default timeout
        withExtendedLifetime((context, module)) {
            wait(for: [requestSent, fetchCompleted], timeout: Self.longTimeout)
        }
    }
#endif
}
