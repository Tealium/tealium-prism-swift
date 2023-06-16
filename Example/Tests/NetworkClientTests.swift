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
    var config: NetworkConfiguration = NetworkConfiguration(session: URLSession.shared)
    lazy var client: NetworkClient = {
        NetworkClient(configuration: config)
    }()
    
    class override func setUp() {
        URLProtocol.registerClass(URLProtocolMock.self)
    }

    class override func tearDown() {
        URLProtocol.unregisterClass(URLProtocolMock.self)
    }

    func test_send_request_succeeds_with_data_and_response() {
        let expect = expectation(description: "Request will complete with a successful Result")
        let predictedResponse = mockSuccess()
        _ = client.sendRequest(URLRequests.GET()) { result in
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
        _ = client.sendRequest(URLRequests.GET()) { result in
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
        let task = client.sendRequest(URLRequests.GET()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue))
            XCTAssertResultIsFailure(result) { error in
                XCTAssertEqual(error, .cancelled)
                expect.fulfill()
            }
        }
        task.dispose()
        waitForExpectations(timeout: 3.0)
    }
    
    func test_request_is_sent_to_should_delay_interceptors() {
        let expect = expectation(description: "Request will be sent to the interceptor")
        mockSuccess()
        config.interceptors = [
            BlockInterceptor(shouldDelay: { _ in
                expect.fulfill()
                return .doNotDelay
            })]
        _ = client.sendRequest(URLRequests.GET()) { result in }
        waitForExpectations(timeout: 3.0)
    }
    
    func test_request_delayed_after_timeout_is_delayed() {
        let expect = expectation(description: "Request will be completed after the delay")
        let basicTimeoutExpactation = expectation(description: "Dispatch After ends before the interceptor delay completes")
        mockSuccess()
        config.interceptors = [
            BlockInterceptor(shouldDelay: { _ in
                return .afterDelay(1.0)
            })]
        config.queue.asyncAfter(deadline: .now() + 0.9) {
            basicTimeoutExpactation.fulfill()
        }
        _ = client.sendRequest(URLRequests.GET()) { result in
            expect.fulfill()
        }
        wait(for: [basicTimeoutExpactation, expect], timeout: 3.0, enforceOrder: true)
    }
    
    func test_request_delayed_after_event_is_delayed() {
        let expect = expectation(description: "Request will be completed after the delay")
        let basicTimeoutExpactation = expectation(description: "Dispatch After ends before the interceptor delay completes")
        mockSuccess()
        let publisher = TealiumPublisher<Void>()
        config.interceptors = [
            BlockInterceptor(shouldDelay: { _ in
                return .afterEvent(publisher.asObservable())
            })]
        config.queue.asyncAfter(deadline: .now() + 1) {
            basicTimeoutExpactation.fulfill()
            publisher.publish()
        }
        _ = client.sendRequest(URLRequests.GET()) { result in
            expect.fulfill()
        }
        wait(for: [basicTimeoutExpactation, expect], timeout: 3.0, enforceOrder: true)
    }
    
    func test_succeded_request_is_sent_to_completion_interceptors() {
        let expect = expectation(description: "Request will be sent to the interceptor")
        let predictedResponse = mockSuccess()
        config.interceptors = [
            BlockInterceptor(didComplete: { _, response in
            XCTAssertResultIsSuccess(response) { value in
                XCTAssertEqual(value.data, predictedResponse.0!)
                XCTAssertEqual(value.urlResponse.statusCode, predictedResponse.1?.statusCode)
                expect.fulfill()
            }
        })]
        _ = client.sendRequest(URLRequests.GET()) { result in }
        waitForExpectations(timeout: 3.0)
    }
    
    func test_failed_request_is_sent_to_completion_interceptors() {
        let expect = expectation(description: "Request will be sent to the interceptor")
        let predictedResponse = mockFailure()
        config.interceptors = [
            BlockInterceptor(didComplete: { _, response in
                XCTAssertResultIsFailure(response) { error in
                    XCTAssertEqual(error, .urlError(predictedResponse.2 as! URLError))
                    expect.fulfill()
                }
            })]
        _ = client.sendRequest(URLRequests.GET()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue))
        }
        waitForExpectations(timeout: 3.0)
    }
    
    func test_succeded_request_is_sent_to_retry_interceptors() {
        let expect = expectation(description: "Request will be sent to the interceptor")
        let predictedResponse = mockSuccess()
        config.interceptors = [
            BlockInterceptor(shouldRetry: { _, _, response in
                XCTAssertResultIsSuccess(response) { value in
                    XCTAssertEqual(value.data, predictedResponse.0!)
                    XCTAssertEqual(value.urlResponse.statusCode, predictedResponse.1?.statusCode)
                    expect.fulfill()
                }
                return .doNotRetry
            })]
        _ = client.sendRequest(URLRequests.GET()) { result in }
        waitForExpectations(timeout: 3.0)
    }
    
    func test_failed_request_is_sent_to_retry_interceptors() {
        let expect = expectation(description: "Request will be sent to the interceptor")
        let predictedResponse = mockFailure()
        config.interceptors = [
            BlockInterceptor(shouldRetry: { _, _, response in
                XCTAssertResultIsFailure(response) { error in
                    XCTAssertEqual(error, .urlError(predictedResponse.2 as! URLError))
                    expect.fulfill()
                }
                return .doNotRetry
            })]
        _ = client.sendRequest(URLRequests.GET()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue))
        }
        waitForExpectations(timeout: 3.0)
    }
    
    func test_retry_count_is_increased_by_1() {
        let numberOfRetriesAllowed = 5
        let expectRetry = expectation(description: "Retry interceptor should be called the number of retries +1 (\(numberOfRetriesAllowed+1)")
        expectRetry.expectedFulfillmentCount = numberOfRetriesAllowed+1
        let expect = expectation(description: "Send request completion is called in the end only once")
        let predictedResponse = mockSuccess()
        var currentRetryCount = -1
        config.interceptors = [
            BlockInterceptor(shouldRetry: { _, retryCount, _ in
                defer { expectRetry.fulfill() }
                XCTAssertEqual(currentRetryCount+1, retryCount)
                print(retryCount)
                currentRetryCount = retryCount
                if retryCount < numberOfRetriesAllowed {
                    return .afterDelay(0)
                }
                return .doNotRetry
            })
        ]
        _ = client.sendRequest(URLRequests.GET()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue))
            XCTAssertResultIsSuccess(result) { value in
                XCTAssertEqual(value.data, predictedResponse.0!)
                XCTAssertEqual(value.urlResponse.statusCode, predictedResponse.1?.statusCode)
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 3.0)
    }
    
    func test_retry_after_delay_request_is_retried() {
        let expectCompletion = expectation(description: "Completion interceptor should be called twice")
        expectCompletion.expectedFulfillmentCount = 2
        let expectRetry = expectation(description: "Retry interceptor should be called twice")
        expectRetry.expectedFulfillmentCount = 2
        let expect = expectation(description: "Send request completion is called in the end only once")
        let predictedResponse = mockSuccess()
        config.interceptors = [
            BlockInterceptor(didComplete: { _, _ in expectCompletion.fulfill() },
                             shouldRetry: { _, retryCount, _ in
                                 defer { expectRetry.fulfill() }
                                 if retryCount == 0 {
                                     return .afterDelay(0)
                                 }
                                 return .doNotRetry
                             })
        ]
        _ = client.sendRequest(URLRequests.GET()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue))
            XCTAssertResultIsSuccess(result) { value in
                XCTAssertEqual(value.data, predictedResponse.0!)
                XCTAssertEqual(value.urlResponse.statusCode, predictedResponse.1?.statusCode)
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 3.0)
    }
    
    func test_retry_after_event_request_is_retried() {
        let expectCompletion = expectation(description: "Completion interceptor should be called twice")
        expectCompletion.expectedFulfillmentCount = 2
        let expectRetry = expectation(description: "Retry interceptor should be called twice")
        expectRetry.expectedFulfillmentCount = 2
        let expect = expectation(description: "Send request completion is called in the end only once")
        let predictedResponse = mockSuccess()
        config.interceptors = [
            BlockInterceptor(didComplete: { _, _ in expectCompletion.fulfill() },
                             shouldRetry: { _, retryCount, _ in
                                 defer { expectRetry.fulfill() }
                                 if retryCount == 0 {
                                     return .afterEvent(TealiumObservableCreate({ observer in
                                         observer(())
                                         return TealiumSubscription {}
                                     }))
                                 }
                                 return .doNotRetry
                             })
        ]
        _ = client.sendRequest(URLRequests.GET()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue))
            XCTAssertResultIsSuccess(result) { value in
                XCTAssertEqual(value.data, predictedResponse.0!)
                XCTAssertEqual(value.urlResponse.statusCode, predictedResponse.1?.statusCode)
                expect.fulfill()
            }
        }
        waitForExpectations(timeout: 3.0)
    }
    
    func test_completion_interceptors_are_called_in_order() {
        let expectFirstCompletion = expectation(description: "First completion interceptor should be called first")
        let expectSecondCompletion = expectation(description: "Second completion interceptor should be called second")
        let expect = expectation(description: "Send request completion is called in the end only once")
        let predictedResponse = mockSuccess()
        let firstInterceptor = BlockInterceptor(didComplete: { _, _ in expectFirstCompletion.fulfill() })
        let secondInterceptor = BlockInterceptor(didComplete: { _, _ in expectSecondCompletion.fulfill() })
        
        config.interceptors = [ firstInterceptor, secondInterceptor ]
        _ = client.sendRequest(URLRequests.GET()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue))
            XCTAssertResultIsSuccess(result) { value in
                XCTAssertEqual(value.data, predictedResponse.0!)
                XCTAssertEqual(value.urlResponse.statusCode, predictedResponse.1?.statusCode)
                expect.fulfill()
            }
        }
        wait(for: [expectFirstCompletion, expectSecondCompletion, expect], timeout: 3.0, enforceOrder: true)
    }
    
    func test_retry_interceptors_are_called_in_reverse_order() {
        let expectFirstRetry = expectation(description: "First retry interceptor should be called second")
        let expectSecondRetry = expectation(description: "Second retry interceptor should be called first")
        let expect = expectation(description: "Send request completion is called in the end only once")
        let predictedResponse = mockSuccess()
        let firstInterceptor = BlockInterceptor(shouldRetry: { _, _, _ in
            defer { expectFirstRetry.fulfill() }
            return .doNotRetry
        })
        let secondInterceptor = BlockInterceptor(shouldRetry: { _, _, _ in
            defer { expectSecondRetry.fulfill() }
            return .doNotRetry
        })
        
        config.interceptors = [ firstInterceptor, secondInterceptor ]
        _ = client.sendRequest(URLRequests.GET()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue))
            XCTAssertResultIsSuccess(result) { value in
                XCTAssertEqual(value.data, predictedResponse.0!)
                XCTAssertEqual(value.urlResponse.statusCode, predictedResponse.1?.statusCode)
                expect.fulfill()
            }
        }
        wait(for: [expectSecondRetry, expectFirstRetry, expect], timeout: 3.0, enforceOrder: true)
    }
    
    func test_delay_interceptors_are_called_in_reverse_order() {
        let expectFirstDelay = expectation(description: "First delay interceptor should be called second")
        let expectSecondDelay = expectation(description: "Second delay interceptor should be called first")
        let expect = expectation(description: "Send request completion is called in the end only once")
        let predictedResponse = mockSuccess()
        let firstInterceptor = BlockInterceptor(shouldDelay: { _ in
            defer { expectFirstDelay.fulfill() }
            return .doNotDelay
        })
        let secondInterceptor = BlockInterceptor(shouldDelay: { _ in
            defer { expectSecondDelay.fulfill() }
            return .doNotDelay
        })
        
        config.interceptors = [ firstInterceptor, secondInterceptor ]
        _ = client.sendRequest(URLRequests.GET()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue))
            XCTAssertResultIsSuccess(result) { value in
                XCTAssertEqual(value.data, predictedResponse.0!)
                XCTAssertEqual(value.urlResponse.statusCode, predictedResponse.1?.statusCode)
                expect.fulfill()
            }
        }
        wait(for: [expectSecondDelay, expectFirstDelay, expect], timeout: 3.0, enforceOrder: true)
    }
    
    func test_retry_interceptors_are_called_until_one_performs_retry() {
        let expectFirstRetry = expectation(description: "Retry interceptor should be called only once as the first time is preceded by the second")
        let expectSecondRetry = expectation(description: "Retry interceptor should be called twice")
        expectSecondRetry.expectedFulfillmentCount = 2
        let expectThirdRetry = expectation(description: "Retry interceptor should be called twice")
        expectThirdRetry.expectedFulfillmentCount = 2
        let expect = expectation(description: "Send request completion is called in the end only once")
        
        let predictedResponse = mockSuccess()
        let firstInterceptor = BlockInterceptor(shouldRetry: { _, _, _ in
            defer { expectFirstRetry.fulfill() }
            return .doNotRetry
        })
        let secondInterceptor = BlockInterceptor(shouldRetry: { _, retryCount, _ in
            defer { expectSecondRetry.fulfill() }
            if retryCount > 0 {
                return .doNotRetry
            }
            return .afterDelay(0)
        })
        let thirdInterceptor = BlockInterceptor(shouldRetry: { _, _, _ in
            defer { expectThirdRetry.fulfill() }
            return .doNotRetry
        })
        
        config.interceptors = [ firstInterceptor, secondInterceptor, thirdInterceptor ]
        _ = client.sendRequest(URLRequests.GET()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue))
            XCTAssertResultIsSuccess(result) { value in
                XCTAssertEqual(value.data, predictedResponse.0!)
                XCTAssertEqual(value.urlResponse.statusCode, predictedResponse.1?.statusCode)
                expect.fulfill()
            }
        }
        wait(for: [expectThirdRetry, expectSecondRetry, expectFirstRetry, expect], timeout: 3.0, enforceOrder: true)
    }
    
    func test_delay_interceptors_are_called_until_one_performs_delay() {
        let expectFirstDelay = expectation(description: "Delay interceptor should never be called as one delays before this does")
        expectFirstDelay.isInverted = true
        let expectSecondDelay = expectation(description: "Delay interceptor should be called")
        let expectThirdDelay = expectation(description: "Delay interceptor should be called")
        let expect = expectation(description: "Send request completion is called in the end only once")
        
        let predictedResponse = mockSuccess()
        let firstInterceptor = BlockInterceptor(shouldDelay: { _ in
            defer { expectFirstDelay.fulfill() }
            return .doNotDelay
        })
        let secondInterceptor = BlockInterceptor(shouldDelay: { _ in
            defer { expectSecondDelay.fulfill() }
            return .afterDelay(0.1)
        })
        let thirdInterceptor = BlockInterceptor(shouldDelay: { _ in
            defer { expectThirdDelay.fulfill() }
            return .doNotDelay
        })
        config.interceptors = [ firstInterceptor, secondInterceptor, thirdInterceptor ]
        _ = client.sendRequest(URLRequests.GET()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue))
            XCTAssertResultIsSuccess(result) { value in
                XCTAssertEqual(value.data, predictedResponse.0!)
                XCTAssertEqual(value.urlResponse.statusCode, predictedResponse.1?.statusCode)
                expect.fulfill()
            }
        }
        wait(for: [expectThirdDelay, expectSecondDelay, expect, expectFirstDelay], timeout: 3.0, enforceOrder: true)
    }
    
    func test_retries_get_cancelled_when_dataTask_is_disposed() {
        let expectRetry = expectation(description: "Request should be retried multiple times before the request is cancelled")
        expectRetry.assertForOverFulfill = false
        let expect = expectation(description: "Request will complete with a cancel error")
        mockFailure(withDelay: 0)
        config.interceptors = [
            BlockInterceptor(shouldRetry: { _, _, _ in
                expectRetry.fulfill()
                return .afterDelay(0.1)
            })
        ]
        let task = client.sendRequest(URLRequests.GET()) { result in
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
        config.interceptors = [
            BlockInterceptor(shouldRetry: { _, _, _ in
                expectRetry.fulfill()
                return .afterDelay(timeout*100)
            })
        ]
        let task = client.sendRequest(URLRequests.GET()) { result in
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
        let task = client.sendRequest(URLRequests.GET()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue))
            XCTAssertResultIsFailure(result) { error in
                XCTAssertEqual(error, .cancelled)
                expectCancelled.fulfill()
            }
        }
        task.dispose()
        _ = client.sendRequest(URLRequests.GET()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue))
            XCTAssertResultIsSuccess(result) { _ in
                expectSucceded.fulfill()
            }
        }
        wait(for: [expectCancelled, expectSucceded], timeout: 3.0, enforceOrder: true)
    }
    
    func test_interceptors_are_called_on_correct_queue() {
        let expectCompletion = expectation(description: "Completion interceptor should be called twice")
        let expectRetry = expectation(description: "Retry interceptor should be called twice")
        let expect = expectation(description: "Send request completion is called in the end only once")
        mockSuccess()
        let queue = DispatchQueue(label: "test_queue")
        config.queue = queue
        config.interceptors = [
            BlockInterceptor(
                didComplete: { _, _ in
                    dispatchPrecondition(condition: .onQueue(queue))
                    expectCompletion.fulfill()
                },
                shouldRetry: { _, retryCount, _ in
                    dispatchPrecondition(condition: .onQueue(queue))
                    defer { expectRetry.fulfill() }
                    return .doNotRetry
                })
        ]
        _ = client.sendRequest(URLRequests.GET()) { result in
            dispatchPrecondition(condition: .onQueue(self.config.queue))
            expect.fulfill()
        }
        waitForExpectations(timeout: 3.0)
    }
    
    func test_add_and_remove_interceptor() {
        let client = NetworkClient(configuration: config)
        let count = client.interceptors.count
        let interceptor = BlockInterceptor()
        client.addInterceptor(interceptor)
        config.queue.sync {
            XCTAssertEqual(count+1, client.interceptors.count)
        }
        client.removeInterceptor(interceptor)
        config.queue.sync {
            XCTAssertEqual(count, client.interceptors.count)
        }
    }
}

@discardableResult
private func mockSuccess() -> MockReply.Response {
    URLProtocolMock.succeedingWith(data: Data(), response: URLResponses.successful())
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
