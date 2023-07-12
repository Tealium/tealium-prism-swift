//
//  NetworkClientTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 12/05/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import XCTest
@testable import tealium_swift

final class NetworkClientTests: XCTestCase {
    var config: NetworkConfiguration = NetworkConfiguration(sessionConfiguration: NetworkConfiguration.defaultUrlSessionConfiguration,
                                                            interceptors: [],
                                                            interceptorManagerFacory: MockInterceptorManager.self)
    var interceptorManager: MockInterceptorManager {
        client.interceptorManager as! MockInterceptorManager
    }
    lazy var client: NetworkClient = {
        config.sessionConfiguration.protocolClasses = [URLProtocolMock.self]
        return NetworkClient(configuration: config)
    }()
    
    func test_url_session_has_interceptor_as_delegate() {
        XCTAssertIdentical(client.session.delegate, client.interceptorManager)
    }
    
    func test_url_session_has_queue_as_delegate_queue() {
        XCTAssertIdentical(client.session.delegateQueue.underlyingQueue, self.config.queue)
    }

    func test_send_request_succeeds_with_data_and_response() {
        let expect = expectation(description: "Request will complete with a successful Result")
        let predictedResponse = mockSuccess()
        _ = client.sendRequest(URLRequest()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue))
            XCTAssertResultIsSuccess(result) { value in
                XCTAssertEqual(value.data, predictedResponse.0!)
                XCTAssertEqual(value.urlResponse.statusCode, predictedResponse.1?.statusCode)
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 1.0)
    }
    
    func test_send_request_fails_with_error() {
        let expect = expectation(description: "Request will complete with a failed Result")
        let predictedResponse = mockFailure()
        _ = client.sendRequest(URLRequest()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue))
            XCTAssertResultIsFailure(result) { error in
                XCTAssertEqual(error, .urlError(predictedResponse.2 as! URLError))
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 1.0)
    }
    
    func test_send_request_gets_cancelled_when_dataTask_is_disposed() {
        let expect = expectation(description: "Request will complete with a cancel error")
        mockFailure(withDelay: 0)
        let task = client.sendRequest(URLRequest()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue))
            XCTAssertResultIsFailure(result) { error in
                XCTAssertEqual(error, .cancelled)
                expect.fulfill()
            }
        }
        task.dispose()
        waitForExpectations(timeout: 3.0)
    }
    
    func test_succeded_request_is_sent_to_intercept_response() {
        let expect = expectation(description: "Request will be sent to the interceptor")
        let predictedResponse = mockSuccess()
        interceptorManager.onInterceptResponse.subscribeOnce { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue))
            XCTAssertResultIsSuccess(result) { value in
                XCTAssertEqual(value.data, predictedResponse.0!)
                XCTAssertEqual(value.urlResponse.statusCode, predictedResponse.1?.statusCode)
                expect.fulfill()
            }
        }
        _ = client.sendRequest(URLRequest()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue))
        }
        waitForExpectations(timeout: 3.0)
    }
    
    func test_failed_request_is_sent_to_intercept_response() {
        let expect = expectation(description: "Request will be sent to the interceptor")
        let predictedResponse = mockFailure()
        interceptorManager.onInterceptResponse.subscribeOnce { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue))
            XCTAssertResultIsFailure(result) { error in
                XCTAssertEqual(error, .urlError(predictedResponse.2 as! URLError))
                expect.fulfill()
            }
        }
        _ = client.sendRequest(URLRequest()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue))
        }
        waitForExpectations(timeout: 3.0)
    }
    
    func test_retry_count_is_increased_by_1() {
        let numberOfRetriesAllowed = 5
        let expectRetry = expectation(description: "Retry interceptor should be called the number of retries +1 (\(numberOfRetriesAllowed+1)")
        expectRetry.expectedFulfillmentCount = numberOfRetriesAllowed+1
        let expect = expectation(description: "Send request completion is called in the end only once")
        var currentRetryCount = -1
        let predictedResponse = mockSuccess()
        interceptorManager.interceptResponseBlock = { retryCount, _, shouldRetry in
            defer { expectRetry.fulfill() }
            XCTAssertEqual(currentRetryCount+1, retryCount)
            currentRetryCount = retryCount
            shouldRetry(retryCount < numberOfRetriesAllowed)
        }
        _ = client.sendRequest(URLRequest()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue))
            XCTAssertResultIsSuccess(result) { value in
                XCTAssertEqual(value.data, predictedResponse.0!)
                XCTAssertEqual(value.urlResponse.statusCode, predictedResponse.1?.statusCode)
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 3.0)
    }
    
    func test_retries_get_cancelled_when_dataTask_is_disposed() {
        let expectRetry = expectation(description: "Request should be retried multiple times before the request is cancelled")
        expectRetry.assertForOverFulfill = false
        let expect = expectation(description: "Request will complete with a cancel error")
        mockFailure(withDelay: 0)
        interceptorManager.interceptResponseBlock = { _, _, shouldRetry in
            expectRetry.fulfill()
            self.config.queue.async {
                shouldRetry(true)
            }
        }
        let task = client.sendRequest(URLRequest()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue))
            XCTAssertResultIsFailure(result) { error in
                XCTAssertEqual(error, .cancelled)
                expect.fulfill()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            task.dispose()
        }
        waitForExpectations(timeout: 3.0)
    }
    
    func test_retries_get_cancelled_immediately_when_dataTask_is_disposed() {
        let expectRetry = expectation(description: "Request should be retried multiple times before the request is cancelled")
        expectRetry.assertForOverFulfill = false
        let expect = expectation(description: "Request will complete with a cancel error")
        let timeout: TimeInterval = 3.0
        mockFailure(withDelay: 0)
        interceptorManager.interceptResponseBlock = { _, _, shouldRetry in
            expectRetry.fulfill()
            self.config.queue.asyncAfter(deadline: .now() + 10) {
                shouldRetry(true)
            }
        }
        let task = client.sendRequest(URLRequest()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue))
            XCTAssertResultIsFailure(result) { error in
                XCTAssertEqual(error, .cancelled)
                expect.fulfill()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            task.dispose()
        }
        waitForExpectations(timeout: timeout)
    }
    
    func test_retries_get_cancelled_and_subsequent_request_completes_after_the_cancelled_one() {
        let expectCancelled = expectation(description: "Request will complete with a cancel error immediately")
        let expectSucceded = expectation(description: "Request will complete with success and will happen after the first task completed with the cancel")
        mockSuccess()
        let task = client.sendRequest(URLRequest()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue))
            XCTAssertResultIsFailure(result) { error in
                XCTAssertEqual(error, .cancelled)
                expectCancelled.fulfill()
            }
        }
        task.dispose()
        _ = client.sendRequest(URLRequest()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue))
            XCTAssertResultIsSuccess(result) { _ in
                expectSucceded.fulfill()
            }
        }
        wait(for: [expectCancelled, expectSucceded], timeout: 3.0, enforceOrder: true)
    }
    
    func test_add_and_remove_interceptor() {
        let client = NetworkClient(configuration: config)
        let count = client.interceptorManager.interceptors.count
        let interceptor = MockInterceptor()
        client.addInterceptor(interceptor)
        config.queue.sync {
            XCTAssertEqual(count+1, client.interceptorManager.interceptors.count)
        }
        client.removeInterceptor(interceptor)
        config.queue.sync {
            XCTAssertEqual(count, client.interceptorManager.interceptors.count)
        }
    }
}

@discardableResult
private func mockSuccess() -> MockReply.Response {
    URLProtocolMock.succeedingWith(data: Data(), response: .successful())
    return URLProtocolMock.reply.peak()
}

@discardableResult
private func mockFailure(withDelay delay: TimeInterval? = nil) -> MockReply.Response {
    URLProtocolMock.failingWith(error: URLError(URLError.notConnectedToInternet))
    if let delay = delay {
        URLProtocolMock.delaying { completion in
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: completion)
        }
    }
    return URLProtocolMock.reply.peak()
}

private func mockWithList(_ list: [MockReply.Response]) {
    URLProtocolMock.replyingWith(.list(list))
}
