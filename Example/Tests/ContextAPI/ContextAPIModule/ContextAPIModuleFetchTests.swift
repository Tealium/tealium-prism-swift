//
//  ContextAPIModuleFetchTests.swift
//  ContextAPITests_iOS
//
//  Created by Sebastian Krajna on 6/11/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

func XCTAssertContextAPIShutdown(_ error: ModuleError<ContextAPIError>, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertModuleShutdown(error, wrapping: ContextAPIError.self, module: ContextAPIModule.moduleType, file: file, line: line)
}

final class ContextAPIModuleFetchTests: ContextAPIModuleBaseTests {

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

    func test_fetchEngineResponse_uses_visitorId_from_the_visitorIdProvider() throws {
        let requestSent = expectation(description: "Request is sent with the provider's visitor id")
        try mockNetworkHelper.encodeResult(EngineResponse())
        let disposable = DisposableContainer()
        mockNetworkHelper.requests.subscribe { request in
            guard case .get(let url, _, _) = request,
                  let requestUrl = try? url.asUrl() else {
                return
            }
            XCTAssertTrue(requestUrl.absoluteString.contains("testVisitorId"))
            disposable.dispose()
            requestSent.fulfill()
        }.addTo(disposable)
        module.fetchEngineResponse(engineID: "test-engine") { _ in }
        waitForDefaultTimeout()
    }

    func test_fetchEngineResponse_fails_with_moduleNotEnabled_when_visitorIdProvider_is_nil() {
        visitorIdProvider = nil
        let requestCompleted = expectation(description: "Fetch completes with a failure")
        module.fetchEngineResponse(engineID: "test-engine") { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .moduleNotEnabled(let moduleType) = error else {
                    XCTFail("Expected ModuleError.moduleNotEnabled, got \(error)")
                    return
                }
                XCTAssertEqual(moduleType, Modules.Types.visitorId)
            }
            requestCompleted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_fetchEngineResponse_wraps_service_failures_once() {
        mockNetworkHelper.setError(.non200Status(500, nil))
        let requestCompleted = expectation(description: "Fetch completes with a failure")
        module.fetchEngineResponse(engineID: "test-engine") { result in
            XCTAssertResultIsFailure(result) { error in
                guard case .underlyingError(let contextAPIError) = error,
                      case .networkError(let networkError) = contextAPIError,
                      case .non200Status(500, _) = networkError.type else {
                    XCTFail("Expected underlyingError wrapping a networkError, got \(error)")
                    return
                }
            }
            requestCompleted.fulfill()
        }
        waitForDefaultTimeout()
    }

    func test_fetchEngineResponse_fails_once_with_moduleShutdown_when_shut_down_while_visitorId_lookup_is_pending() {
        // A lookup that never calls back, as when the modules haven't been created yet.
        getVisitorIdProvider = { _ in Disposables.subscription { } }
        let requestCompleted = expectation(description: "Fetch completes with a failure")
        module.fetchEngineResponse(engineID: "test-engine") { result in
            XCTAssertResultIsFailure(result) { error in
                XCTAssertContextAPIShutdown(error)
            }
            // Over-fulfilling fails the test, so this also checks it completes only once.
            requestCompleted.fulfill()
        }
        module.shutdown()
        waitForDefaultTimeout()
    }

    func test_fetchEngineResponse_fails_once_with_moduleShutdown_when_shut_down_while_network_call_is_in_flight() throws {
        let requestCompleted = expectation(description: "Fetch completes with a failure")
        // The mock completes the cancelled request with `.cancelled` once the delay has passed.
        mockNetworkHelper.delay = 10
        try mockNetworkHelper.encodeResult(EngineResponse())
        module.fetchEngineResponse(engineID: "test-engine") { result in
            XCTAssertResultIsFailure(result) { error in
                XCTAssertContextAPIShutdown(error)
            }
            // Over-fulfilling fails the test, so this also checks it completes only once.
            requestCompleted.fulfill()
        }
        module.shutdown()
        let cancellationDelivered = expectation(description: "The delayed network completion has run")
        mockNetworkHelper.queue.asyncAfter(deadline: .now() + .milliseconds(10)) {
            cancellationDelivered.fulfill()
        }
        wait(for: [requestCompleted, cancellationDelivered], timeout: Self.longTimeout)
    }

    func test_fetchEngineResponse_fails_with_moduleShutdown_when_called_after_shutdown() throws {
        try mockNetworkHelper.encodeResult(EngineResponse())
        module.shutdown()
        let requestCompleted = expectation(description: "Fetch completes with a failure")
        module.fetchEngineResponse(engineID: "test-engine") { result in
            XCTAssertResultIsFailure(result) { error in
                XCTAssertContextAPIShutdown(error)
            }
            requestCompleted.fulfill()
        }
        waitForDefaultTimeout()
    }
}
