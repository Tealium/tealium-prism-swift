//
//  HTTPClientTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 12/05/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class HTTPClientTests: XCTestCase {
    private let queue = TealiumQueue(label: "testQueue", qos: .userInteractive)
    lazy var config: NetworkConfiguration = NetworkConfiguration(sessionConfiguration: NetworkConfiguration.defaultUrlSessionConfiguration,
                                                                 interceptors: [],
                                                                 interceptorManagerFactory: MockInterceptorManager.self,
                                                                 queue: queue)
    var interceptorManager: MockInterceptorManager {
        // swiftlint:disable force_cast
        client.interceptorManager as! MockInterceptorManager
        // swiftlint:enable force_cast
    }
    lazy var client: HTTPClient = {
        config.sessionConfiguration.protocolClasses = [URLProtocolMock.self]
        return HTTPClient(configuration: config, logger: nil)
    }()

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
                XCTAssertEqual(error, .cancelled)
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
        interceptorManager.interceptResponseBlock = { retryCount, _, shouldRetry in
            defer { expectRetry.fulfill() }
            XCTAssertEqual(currentRetryCount + 1, retryCount)
            currentRetryCount = retryCount
            shouldRetry(retryCount < numberOfRetriesAllowed)
        }
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

    func test_retries_get_cancelled_when_dataTask_is_disposed() {
        let expectRetry = expectation(description: "Request should be retried multiple times before the request is cancelled")
        expectRetry.assertForOverFulfill = false
        let expect = expectation(description: "Request will complete with a cancel error")
        mockFailure()
        interceptorManager.interceptResponseBlock = { _, _, shouldRetry in
            expectRetry.fulfill()
            self.queue.dispatchQueue.asyncAfter(deadline: .now() + 1) {
                shouldRetry(true)
            }
        }
        let task = client.sendRequest(URLRequest()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue.dispatchQueue))
            XCTAssertResultIsFailure(result) { error in
                XCTAssertEqual(error, .cancelled)
                expect.fulfill()
            }
        }
        wait(for: [expectRetry], timeout: Self.longTimeout)
        task.dispose()
        waitOnQueue(queue: queue)
    }

    func test_retries_get_cancelled_and_subsequent_request_completes_after_the_cancelled_one() {
        let expectCancelled = expectation(description: "Request will complete with a cancel error immediately")
        let expectsucceeded = expectation(description: "Request will complete with success and will happen after the first task completed with the cancel")
        mockSuccess(delay: 10)
        let queue = TealiumQueue.worker
        XCTAssertFalse(queue.isOnQueue())
        let task = client.sendRequest(URLRequest()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue.dispatchQueue))
            XCTAssertResultIsFailure(result) { error in
                XCTAssertEqual(error, .cancelled)
                expectCancelled.fulfill()
            }
        }
        task.dispose()
        mockSuccess()
        _ = client.sendRequest(URLRequest()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue.dispatchQueue))
            XCTAssertResultIsSuccess(result) { _ in
                expectsucceeded.fulfill()
            }
        }
        wait(for: [expectCancelled, expectsucceeded], timeout: Self.longTimeout, enforceOrder: true)
    }

    @discardableResult
    private func mockSuccess(delay: Int? = nil) -> MockReply.Response {
        URLProtocolMock.succeedingWith(data: Data(), response: .successful())
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

    private func mockWithList(_ list: [MockReply.Response]) {
        URLProtocolMock.replyingWith(.list(list))
    }
}
