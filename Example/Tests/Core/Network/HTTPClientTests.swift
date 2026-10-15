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
                                          queue: queue)
        config.sessionConfiguration.protocolClasses = [URLProtocolMock.self]
        return config
    }()
    lazy var client = HTTPClient(configuration: config, logger: nil)
    let mockLogger = MockLogger()
    lazy var loggingClient = HTTPClient(configuration: config, logger: mockLogger)

    override func tearDown() {
        URLProtocolMock.reset()
    }

    /// Builds an `HTTPClient` on `URLProtocolMock` whose `InterceptorManager` is seeded with `interceptors` up front.
    private func makeClient(interceptors: [RequestInterceptor]) -> HTTPClient {
        let config = NetworkConfiguration(sessionConfiguration: NetworkConfiguration.defaultUrlSessionConfiguration,
                                          interceptors: interceptors,
                                          queue: queue)
        config.sessionConfiguration.protocolClasses = [URLProtocolMock.self]
        return HTTPClient(configuration: config, logger: nil)
    }

    func test_url_session_has_no_delegate() {
        XCTAssertNil(client.session.delegate)
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
        let client = makeClient(interceptors: [MockInterceptor(onAttemptResult: { _, _, result in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            XCTAssertResultIsSuccess(result) { value in
                XCTAssertEqual(value.data, predictedResponse.0)
                XCTAssertEqual(value.urlResponse.statusCode, predictedResponse.1?.statusCode)
                expect.fulfill()
            }
        })])
        _ = client.sendRequest(URLRequest()) { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
        }
        waitForLongTimeout()
    }

    func test_failed_request_is_sent_to_intercept_response() {
        let expect = expectation(description: "Request will be sent to the interceptor")
        let predictedResponse = mockFailure()
        let client = makeClient(interceptors: [MockInterceptor(onAttemptResult: { _, _, result in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            XCTAssertResultIsFailure(result) { error in
                XCTAssertNetworkError(error, equalsURLErrorWith: predictedResponse.2)
                expect.fulfill()
            }
        })])
        _ = client.sendRequest(URLRequest()) { _ in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
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
        let client = makeClient(interceptors: [MockInterceptor(shouldRetry: { _, retryCount, _ in
            defer { expectRetry.fulfill() }
            XCTAssertEqual(currentRetryCount + 1, retryCount)
            currentRetryCount = retryCount
            if retryCount >= numberOfRetriesAllowed {
                return .doNotRetry
            } else {
                return .afterEvent(Observables.just(()))
            }
        })])
        _ = client.sendRequest(URLRequest()) { result in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
            XCTAssertResultIsSuccess(result) { value in
                XCTAssertEqual(value.data, predictedResponse.0)
                XCTAssertEqual(value.urlResponse.statusCode, predictedResponse.1?.statusCode)
                expect.fulfill()
            }
        }
        waitForLongTimeout()
    }

    func test_onAttemptResult_receives_incrementing_retryCount_for_each_attempt() {
        let expectAttempts = expectation(description: "onAttemptResult is called once per attempt")
        expectAttempts.expectedFulfillmentCount = 3
        let expectCompletion = expectation(description: "Send request completion is called")
        var receivedRetryCounts = [Int]()
        _ = mockSuccess()
        let client = makeClient(interceptors: [MockInterceptor(onAttemptResult: { _, retryCount, _ in
            receivedRetryCounts.append(retryCount)
            expectAttempts.fulfill()
        }, shouldRetry: { _, consecutiveRetryCount, _ in
            consecutiveRetryCount < 2 ? .afterDelay(0) : .doNotRetry
        })])
        _ = client.sendRequest(URLRequest()) { _ in
            expectCompletion.fulfill()
        }
        waitForDefaultTimeout()
        XCTAssertEqual(receivedRetryCounts, [0, 1, 2])
    }

    func test_retryable_errors_are_not_retried_by_default() {
        config = NetworkConfiguration(sessionConfiguration: NetworkConfiguration.defaultUrlSessionConfiguration,
                                      interceptors: NetworkConfiguration.defaultInterceptors,
                                      queue: queue)
        config.sessionConfiguration.protocolClasses = [URLProtocolMock.self]
        URLProtocolMock.reply = .list([
            (Data(), .mock(status: 429), nil),
            (Data(), .successful(), nil)
        ])
        let requests = URLProtocolMock.recordingRequests()
        let requestCompleted = expectation(description: "Request completes with a failure without being retried")
        _ = client.sendRequest(URLRequest()) { result in
            XCTAssertResultIsFailure(result) { error in
                XCTAssertEqual(error.urlResponse?.statusCode, 429)
            }
            requestCompleted.fulfill()
        }
        waitForLongTimeout()
        XCTAssertEqual(requests.dates.count, 1)
    }

    func test_retries_get_cancelled_when_dataTask_is_disposed() {
        let expectRetry = expectation(description: "Request should be retried multiple times before the request is cancelled")
        expectRetry.assertForOverFulfill = false
        let expect = expectation(description: "Request will complete with a cancel error")
        mockFailure()
        let client = makeClient(interceptors: [MockInterceptor(shouldRetry: { _, _, _ in
            expectRetry.fulfill()
            return .afterDelay(1)
        })])
        let task = client.sendRequest(URLRequest()) { result in
            dispatchPrecondition(condition: .onQueue(self.queue.dispatchQueue))
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

    func test_derived_client_shares_session_and_delegate_queue_and_uses_a_new_manager() {
        let derived = client.newClient(withAdditionalInterceptors: [MockInterceptor()])
        XCTAssertIdentical(derived.session, client.session)
        XCTAssertNil(derived.session.delegate)
        XCTAssertIdentical(derived.session.delegateQueue.underlyingQueue, self.config.queue.dispatchQueue)
        XCTAssertNotIdentical(derived.interceptorManager, client.interceptorManager)
    }

    func test_client_with_new_logger_shares_session_and_manager() {
        let derived = client.newClient(withLogger: mockLogger)
        XCTAssertIdentical(derived.session, client.session)
        XCTAssertIdentical(derived.interceptorManager, client.interceptorManager)
    }

    func test_derived_client_with_retrying_interceptor_retries_while_parent_does_not() {
        mockFailure()
        let parentRequestSent = expectation(description: "Parent client sends the request only once")
        let parentCompleted = expectation(description: "Parent request completes with a failure")
        countRequests(parentRequestSent)
        _ = client.sendRequest(URLRequest()) { result in
            XCTAssertResultIsFailure(result)
            parentCompleted.fulfill()
        }
        wait(for: [parentRequestSent, parentCompleted], timeout: Self.longTimeout)

        let derived = client.newClient(withAdditionalInterceptors: [
            MockInterceptor(shouldRetry: { _, retryCount, _ in
                retryCount == 0 ? .afterDelay(0) : .doNotRetry
            })
        ])
        let derivedRequestSent = expectation(description: "Derived client sends the request twice")
        derivedRequestSent.expectedFulfillmentCount = 2
        let derivedCompleted = expectation(description: "Derived request completes with a failure after one retry")
        countRequests(derivedRequestSent)
        _ = derived.sendRequest(URLRequest()) { result in
            XCTAssertResultIsFailure(result)
            derivedCompleted.fulfill()
        }
        wait(for: [derivedRequestSent, derivedCompleted], timeout: Self.longTimeout)
    }

    func test_derived_client_passes_maxRetryCount_to_its_interceptor_manager() {
        let derived = client.newClient(withAdditionalInterceptors: [MockInterceptor()], maxRetryCount: 2)
        XCTAssertEqual(derived.interceptorManager.maxRetryCount, 2)
    }

    private func countRequests(_ requestSent: XCTestExpectation) {
        URLProtocolMock.recordingRequests { _ in requestSent.fulfill() }
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
