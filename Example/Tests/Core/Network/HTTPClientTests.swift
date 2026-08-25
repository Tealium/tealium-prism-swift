//
//  HTTPClientTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 12/05/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

#if !os(watchOS)
// URLProtocolMock seems not to be working on watchos

final class HTTPClientTests: XCTestCase {
    private let queue = TealiumQueue(label: "testQueue", qos: .userInteractive)
    lazy var config: NetworkConfiguration = {
        var config = NetworkConfiguration(sessionConfiguration: NetworkConfiguration.defaultUrlSessionConfiguration,
                                          interceptors: [],
                                          interceptorManagerFactory: MockInterceptorManager.self,
                                          queue: queue)
        config.sessionConfiguration.protocolClasses = [URLProtocolMock.self]
        return config
    }()
    var interceptorManager: MockInterceptorManager {
        // swiftlint:disable:next force_cast
        client.interceptorManager as! MockInterceptorManager
    }
    lazy var client = HTTPClient(configuration: config, logger: nil)
    let mockLogger = MockLogger()
    lazy var loggingClient = HTTPClient(configuration: config, logger: mockLogger)

    override func tearDown() {
        URLProtocolMock.reset()
    }

    func test_url_session_has_interceptor_as_delegate() {
        XCTAssertIdentical(client.session.delegate, client.interceptorManager)
    }

    func test_url_session_has_queue_as_delegate_queue() {
        XCTAssertIdentical(client.session.delegateQueue.underlyingQueue, self.config.queue.dispatchQueue)
    }

    func test_send_request_succeeds_with_data_and_response() {
        let expect = expectation(description: "Request will complete with a successful Result")
        let predictedResponse = mockSuccess()
        _ = client.sendRequest(URLRequest()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue.dispatchQueue))
            XCTAssertResultIsSuccess(result) { value in
                XCTAssertEqual(value.data, predictedResponse.0)
                XCTAssertEqual(value.urlResponse.statusCode, predictedResponse.1?.statusCode)
                expect.fulfill()
            }
        }
        waitForLongTimeout()
    }

    func test_send_request_fails_with_error() {
        let expect = expectation(description: "Request will complete with a failed Result")
        let predictedResponse = mockFailure()
        _ = client.sendRequest(URLRequest()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue.dispatchQueue))
            XCTAssertResultIsFailure(result) { error in
                XCTAssertNetworkError(error, equalsURLErrorWith: predictedResponse.2)
                expect.fulfill()
            }
        }
        waitForLongTimeout()
    }

    func test_send_request_gets_cancelled_immediately_when_dataTask_is_disposed() {
        let expect = expectation(description: "Request will complete with a cancel error")
        mockFailure(withDelay: 10)
        let task = client.sendRequest(URLRequest()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue.dispatchQueue))
            XCTAssertResultIsFailure(result) { error in
                XCTAssertNetworkError(error, is: .cancelled)
                expect.fulfill()
            }
        }
        task.dispose()
        waitOnQueue(queue: queue)
    }

    func test_succeeded_request_is_sent_to_intercept_response() {
        let expect = expectation(description: "Request will be sent to the interceptor")
        let predictedResponse = mockSuccess()
        interceptorManager.onInterceptResponse.subscribeOnce { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue.dispatchQueue))
            XCTAssertResultIsSuccess(result) { value in
                XCTAssertEqual(value.data, predictedResponse.0)
                XCTAssertEqual(value.urlResponse.statusCode, predictedResponse.1?.statusCode)
                expect.fulfill()
            }
        }
        _ = client.sendRequest(URLRequest()) { _ in
            dispatchPrecondition(condition: .onQueue(self.config.queue.dispatchQueue))
        }
        waitForLongTimeout()
    }

    func test_failed_request_is_sent_to_intercept_response() {
        let expect = expectation(description: "Request will be sent to the interceptor")
        let predictedResponse = mockFailure()
        interceptorManager.onInterceptResponse.subscribeOnce { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue.dispatchQueue))
            XCTAssertResultIsFailure(result) { error in
                XCTAssertNetworkError(error, equalsURLErrorWith: predictedResponse.2)
                expect.fulfill()
            }
        }
        _ = client.sendRequest(URLRequest()) { _ in
            dispatchPrecondition(condition: .onQueue(self.config.queue.dispatchQueue))
        }
        waitForLongTimeout()
    }

    func test_retry_count_is_increased_by_1() {
        let numberOfRetriesAllowed = 5
        let expectRetry = expectation(description: "Retry interceptor should be called the number of retries +1 (\(numberOfRetriesAllowed + 1)")
        expectRetry.expectedFulfillmentCount = numberOfRetriesAllowed + 1
        let expect = expectation(description: "Send request completion is called in the end only once")
        var currentRetryCount = -1
        let predictedResponse = mockSuccess()
        interceptorManager.interceptors.append(MockInterceptor(shouldRetry: { _, retryCount, _ in
            defer { expectRetry.fulfill() }
            XCTAssertEqual(currentRetryCount + 1, retryCount)
            currentRetryCount = retryCount
            if retryCount >= numberOfRetriesAllowed {
                return .doNotRetry
            } else {
                return .afterEvent(Observables.just(()))
            }
        }))
        _ = client.sendRequest(URLRequest()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue.dispatchQueue))
            XCTAssertResultIsSuccess(result) { value in
                XCTAssertEqual(value.data, predictedResponse.0)
                XCTAssertEqual(value.urlResponse.statusCode, predictedResponse.1?.statusCode)
                expect.fulfill()
            }
        }
        waitForLongTimeout()
    }

    func test_retryable_errors_are_retried_by_default() {
        config = .default
        config.interceptorManagerFactory = MockInterceptorManager.self
        config.sessionConfiguration.protocolClasses = [URLProtocolMock.self]
        URLProtocolMock.reply = .list([
            (nil, nil, URLError(.networkConnectionLost)),
            (Data(), HTTPURLResponse(), nil)
        ])
        let requestCompleted = expectation(description: "DefaultInterceptor should retry after first retriable error and succeed the subsequent request")
        _ = client.sendRequest(URLRequest()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue.dispatchQueue))
            XCTAssertResultIsSuccess(result)
            requestCompleted.fulfill()
        }
        waitForLongTimeout()
    }

    func test_retries_get_cancelled_when_dataTask_is_disposed() {
        let expectRetry = expectation(description: "Request should be retried multiple times before the request is cancelled")
        expectRetry.assertForOverFulfill = false
        let expect = expectation(description: "Request will complete with a cancel error")
        mockFailure()
        interceptorManager.interceptors.append(MockInterceptor(shouldRetry: { _, _, _ in
            expectRetry.fulfill()
            return .afterDelay(1)
        }))
        let task = client.sendRequest(URLRequest()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue.dispatchQueue))
            XCTAssertResultIsFailure(result) { error in
                XCTAssertNetworkError(error, is: .cancelled)
                expect.fulfill()
            }
        }
        wait(for: [expectRetry], timeout: Self.longTimeout)
        task.dispose()
        waitOnQueue(queue: queue)
    }

    func test_retries_get_cancelled_and_subsequent_request_completes_after_the_cancelled_one() {
        let expectCancelled = expectation(description: "Request will complete with a cancel error immediately")
        let expectSucceeded = expectation(description: "Request will complete with success and will happen after the first task completed with the cancel")
        mockSuccess(delay: 10)
        XCTAssertFalse(TealiumQueue.worker.isOnQueue())
        let task = client.sendRequest(URLRequest()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue.dispatchQueue))
            XCTAssertResultIsFailure(result) { error in
                XCTAssertNetworkError(error, is: .cancelled)
                expectCancelled.fulfill()
            }
        }
        task.dispose()
        mockSuccess()
        _ = client.sendRequest(URLRequest()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue.dispatchQueue))
            XCTAssertResultIsSuccess(result) { _ in
                expectSucceeded.fulfill()
            }
        }
        wait(for: [expectCancelled, expectSucceeded], timeout: Self.longTimeout, enforceOrder: true)
    }

    func test_sendRequest_with_builder_builds_sends_and_logs_build_traces_and_completion() {
        let buildingLogged = expectation(description: "Building request trace is logged")
        let builtLogged = expectation(description: "Built request trace is logged")
        let resultLogged = expectation(description: "Network Result is logged")
        let completedLogged = expectation(description: "Completed request is logged")
        let requestCompleted = expectation(description: "Request completes successfully")
        mockSuccess(data: Data("Something".utf8), headers: ["heder_key": "value"])
        _ = mockLogger.handler.onLogged.subscribe { event in
            guard event.category == LogCategory.httpClient else { return }
            if event.message.hasPrefix("Building request") {
                XCTAssertEqual(event.level, .trace)
                buildingLogged.fulfill()
            } else if event.message.hasPrefix("Built request") {
                XCTAssertEqual(event.level, .trace)
                builtLogged.fulfill()
            } else if event.message.hasPrefix("Completed request") {
                XCTAssertEqual(event.level, .debug)
                XCTAssertFalse(event.message.contains("Body"), "Debug level logs should not contain response body")
                XCTAssertFalse(event.message.contains("Headers"), "Debug level logs should not contain response headers")
                resultLogged.fulfill()
            } else if event.message.hasPrefix("Response for request") {
                XCTAssertEqual(event.level, .trace)
                XCTAssertTrue(event.message.contains("Body"), "Trace level logs should contain response body")
                XCTAssertTrue(event.message.contains("Headers"), "Trace level logs should contain response headers")
                completedLogged.fulfill()
            }
        }
        _ = loggingClient.sendRequest(RequestBuilder.makePOST(url: "https://www.tealium.com", json: ["key": "value"])) { result in
            XCTAssertResultIsSuccess(result)
            requestCompleted.fulfill()
        }
        waitForLongTimeout()
    }

    func test_sendRequest_with_malformed_url_completes_with_unknown_failure_and_disposed_disposable() {
        let requestCompleted = expectation(description: "Request completed")
        let disposable = client.sendRequest(RequestBuilder.makePOST(url: "", json: [:])) { result in
            XCTAssertResultIsFailure(result) { error in
                XCTAssertNetworkError(error, is: .unknown)
                requestCompleted.fulfill()
            }
        }
        XCTAssertTrue(disposable.isDisposed)
        waitForDefaultTimeout()
    }

    func test_sendRequest_with_build_failure_logs_an_error() {
        let errorLogged = expectation(description: "Build failure is logged as an error")
        _ = mockLogger.handler.onLogged.subscribe { event in
            guard event.category == LogCategory.httpClient, event.level == .error else { return }
            XCTAssertTrue(event.message.hasPrefix("Failed to build request"))
            errorLogged.fulfill()
        }
        _ = loggingClient.sendRequest(RequestBuilder.makePOST(url: "", json: [:])) { _ in }
        waitForLongTimeout()
    }

    @discardableResult
    private func mockSuccess(data: Data = Data(), headers: [String: String]? = nil, delay: Int? = nil) -> MockReply.Response {
        URLProtocolMock.succeedingWith(data: data, response: .successful(headers: headers))
        if let delay {
            mockDelay(delay)
        }
        return URLProtocolMock.reply.peak()
    }

    private func mockDelay(_ delay: Int) {
        URLProtocolMock.delaying { completion in
            if delay > 0 {
                self.queue.dispatchQueue.asyncAfter(deadline: .now() + .milliseconds(delay), execute: completion)
            } else {
                self.queue.dispatchQueue.async(execute: completion)
            }
        }
    }

    @discardableResult
    private func mockFailure(_ error: Error = URLError(URLError.notConnectedToInternet), withDelay delay: Int? = nil) -> MockReply.Response {
        URLProtocolMock.failingWith(error: error)
        if let delay {
            mockDelay(delay)
        }
        return URLProtocolMock.reply.peak()
    }
}
#endif
