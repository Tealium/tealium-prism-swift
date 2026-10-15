//
//  CollectModuleTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 15/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class CollectModuleTests: XCTestCase {
    let mockClient = MockNetworkClient(result: .success(.successful()))
    var configuration = CollectModuleConfiguration(configuration: [:])
    lazy var collect = CollectModule(networkClient: mockClient,
                                     configuration: configuration,
                                     logger: nil)

    let stubDispatches = [
        Dispatch(name: "event1", data: [TealiumDataKey.account: "account", TealiumDataKey.profile: "profile"]),
        Dispatch(name: "event2", data: [TealiumDataKey.account: "account", TealiumDataKey.profile: "profile"])
    ]

    override func tearDown() {
        URLProtocolMock.reset()
    }

    private func urlString(of request: URLRequest, file: StaticString = #filePath, line: UInt = #line) -> String? {
        guard let urlString = request.url?.absoluteString else {
            XCTFail("Could not convert to URL", file: file, line: line)
            return nil
        }
        return urlString
    }

    /// Decodes the gzipped JSON body of a Collect request back into a `DataObject`, asserting the body is gzipped.
    private func decodeGzippedBody(_ request: URLRequest,
                                   file: StaticString = #filePath,
                                   line: UInt = #line) -> DataObject? {
        XCTAssertEqual(request.httpBody?.isGzipped, true, "Collect body should be gzipped", file: file, line: line)
        guard let json = request.httpBody?.gunzippedJSON(file: file, line: line),
              let dataObject = try? DataObject(jsonObject: json) else {
            XCTFail("Could not decode gzipped request body", file: file, line: line)
            return nil
        }
        return dataObject
    }

    func test_send_single_dispatch() {
        let postRequestSent = expectation(description: "The POST request is sent")
        mockClient.requestDidSend = { request in
            XCTAssertEqual(request.url, self.collect?.configuration.url)
            XCTAssertEqual(self.decodeGzippedBody(request), self.stubDispatches[0].payload)
            postRequestSent.fulfill()
        }
        _ = collect?.dispatch([stubDispatches[0]], completion: { _ in })
        waitForDefaultTimeout()
    }

    func test_send_multiple_dispatches() {
        let postRequestSent = expectation(description: "The POST request is sent")
        mockClient.requestDidSend = { request in
            XCTAssertEqual(request.url, self.collect?.configuration.batchUrl)
            let expectedEvents: [DataObject] = [
                [
                    TealiumDataKey.event: "event1",
                    TealiumDataKey.eventType: "event",
                    TealiumDataKey.timestampUnixMilliseconds: self.stubDispatches[0].timestamp,
                    TealiumDataKey.requestUUID: self.stubDispatches[0].id
                ],
                [
                    TealiumDataKey.event: "event2",
                    TealiumDataKey.eventType: "event",
                    TealiumDataKey.timestampUnixMilliseconds: self.stubDispatches[1].timestamp,
                    TealiumDataKey.requestUUID: self.stubDispatches[1].id
                ]
            ]
            XCTAssertEqual(self.decodeGzippedBody(request),
                           [
                            "shared": [
                                TealiumDataKey.account: "account",
                                TealiumDataKey.profile: "profile"
                            ],
                            "events": expectedEvents
                           ])
            postRequestSent.fulfill()
        }
        _ = collect?.dispatch(stubDispatches, completion: { _ in })
        waitForDefaultTimeout()
    }

    func test_send_single_dispatch_overrides_profile_when_provided() {
        configuration = CollectModuleConfiguration(configuration: [CollectModuleConfiguration.Keys.overrideProfile: "override"])
        let postRequestSent = expectation(description: "The POST request is sent")
        mockClient.requestDidSend = { request in
            XCTAssertEqual(self.decodeGzippedBody(request)?.get(key: TealiumDataKey.profile), "override")
            postRequestSent.fulfill()
        }
        _ = collect?.dispatch([stubDispatches[0]], completion: { _ in })
        waitForDefaultTimeout()
    }

    func test_send_multiple_dispatches_overrides_profile_when_provided() {
        configuration = CollectModuleConfiguration(configuration: [CollectModuleConfiguration.Keys.overrideProfile: "override"])
        let postRequestSent = expectation(description: "The POST request is sent")
        mockClient.requestDidSend = { request in
            XCTAssertEqual(self.decodeGzippedBody(request)?.getDataDictionary(key: "shared")?.get(key: TealiumDataKey.profile), "override")
            postRequestSent.fulfill()
        }
        _ = collect?.dispatch(stubDispatches, completion: { _ in })
        waitForDefaultTimeout()
    }

    func test_multiple_dispatches_with_all_different_visitorIds_are_sent_in_different_single_requests() {
        let firstVisitorSent = expectation(description: "The POST request for the first visitor is sent")
        let secondVisitorSent = expectation(description: "The POST request for the second visitor is sent")
        mockClient.requestDidSend = { request in
            if let visitorId = self.decodeGzippedBody(request)?.get(key: TealiumDataKey.visitorId, as: String.self) {
                if visitorId == "visitor1" {
                    firstVisitorSent.fulfill()
                } else if visitorId == "visitor2" {
                    secondVisitorSent.fulfill()
                }
            }
        }
        _ = collect?.dispatch([
            Dispatch(name: "event1", data: [TealiumDataKey.visitorId: "visitor1"]),
            Dispatch(name: "event2", data: [TealiumDataKey.visitorId: "visitor2"])
        ], completion: { _ in })
        waitForDefaultTimeout()
    }

    func test_multiple_dispatches_with_same_visitorIds_are_sent_in_the_same_batch() {
        let firstVisitorSent = expectation(description: "The POST request for the first visitor is sent")
        let secondVisitorSent = expectation(description: "The POST request for the second visitor is sent")
        mockClient.requestDidSend = { request in
            if let shared = self.decodeGzippedBody(request)?.getDataDictionary(key: "shared"),
               let visitorId = shared.get(key: TealiumDataKey.visitorId, as: String.self) {
                if visitorId == "visitor1" {
                    firstVisitorSent.fulfill()
                } else if visitorId == "visitor2" {
                    secondVisitorSent.fulfill()
                }
            }
        }
        _ = collect?.dispatch([
            Dispatch(name: "event1", data: [TealiumDataKey.visitorId: "visitor1"]),
            Dispatch(name: "event2", data: [TealiumDataKey.visitorId: "visitor1"]),
            Dispatch(name: "event3", data: [TealiumDataKey.visitorId: "visitor2"]),
            Dispatch(name: "event4", data: [TealiumDataKey.visitorId: "visitor2"])
        ], completion: { _ in })
        waitForDefaultTimeout()
    }

    func test_multiple_dispatches_with_same_visitorIds_only_complete_with_the_batched_events() {
        let firstVisitorSent = expectation(description: "The POST request for the first visitor is sent")
        let secondVisitorSent = expectation(description: "The POST request for the second visitor is sent")
        _ = collect?.dispatch([
            Dispatch(name: "event1", data: [TealiumDataKey.visitorId: "visitor1"]),
            Dispatch(name: "event2", data: [TealiumDataKey.visitorId: "visitor1"]),
            Dispatch(name: "event3", data: [TealiumDataKey.visitorId: "visitor2"])
        ], completion: { events in
            let visitorIdsArray = events.map { $0.payload.get(key: TealiumDataKey.visitorId) ?? "" }
            XCTAssertEqual(Set(visitorIdsArray).count, 1, "All visitorIds should be the same in this batch")
            if visitorIdsArray[0] == "visitor1" {
                firstVisitorSent.fulfill()
            } else if visitorIdsArray[0] == "visitor2" {
                secondVisitorSent.fulfill()
            }
        })
        waitForDefaultTimeout()
    }

    func test_disposed_dispatch_are_not_completed() {
        let postRequestCancelled = expectation(description: "The POST request is cancelled")
        mockClient.delayBlock = { block in DispatchQueue.main.async(execute: block) }
        let subscription = collect?.dispatch([stubDispatches[0]], completion: { dispatches in
            XCTAssertEqual(dispatches.count, 0)
            postRequestCancelled.fulfill()
        })
        subscription?.dispose()
        waitForDefaultTimeout()
    }

    func test_disposed_dispatches_batch_is_not_completed() {
        let postRequestCancelled = expectation(description: "The POST request is cancelled")
        mockClient.delayBlock = { block in DispatchQueue.main.async(execute: block) }
        let subscription = collect?.dispatch(stubDispatches, completion: { dispatches in
            XCTAssertEqual(dispatches.count, 0)
            postRequestCancelled.fulfill()
        })
        subscription?.dispose()
        waitForDefaultTimeout()
    }

    func test_sendBatchDispatches_doesnt_send_when_events_array_is_empty() {
        let postRequestSent = expectation(description: "The POST request is sent")
        postRequestSent.isInverted = true
        _ = collect?.sendBatchDispatches([], completion: { _ in
            postRequestSent.fulfill()
        })
        waitForDefaultTimeout()
    }

    func test_collect_is_not_initialized_when_settings_are_nil() {
        configuration = nil
        XCTAssertNil(collect)
    }

    func test_context_init_derives_the_client_with_uncapped_retries_and_connectivity_retries() throws {
        let context = MockContext(moduleManager: ModuleManager(), networkClient: mockClient)
        let collectFromContext = CollectModule(moduleId: Modules.Types.collect, context: context, moduleConfiguration: [:])
        XCTAssertNotNil(collectFromContext)
        XCTAssertEqual(mockClient.additionalInterceptors.count, 1, "The client should be derived exactly once")
        let interceptors = try XCTUnwrap(mockClient.additionalInterceptors.first)
        XCTAssertEqual(interceptors.count, 2)
        let retryInterceptor = try XCTUnwrap(interceptors.first as? RetryableErrorInterceptor)
        XCTAssertNil(retryInterceptor.maxAttempts)
        XCTAssertEqual(retryInterceptor.maxDelay, 150)
        XCTAssertEqual(retryInterceptor.longRetryAfter, .wait)
        XCTAssertEqual(mockClient.additionalMaxRetryCounts, [nil], "Collect should not limit the total retries")
        let connectivityInterceptor = try XCTUnwrap(interceptors.last as? ConnectivityRetryInterceptor)
        XCTAssertIdentical(connectivityInterceptor.connectivityManager as AnyObject,
                           context.network.connectivityManager as AnyObject)
    }

    /// The first interceptor of the network stack Collect derives its client with.
    private func collectRetryInterceptor() throws -> RetryableErrorInterceptor {
        let interceptors = CollectModule.networkInterceptors(connectivityManager: MockConnectivityManager(queue: .worker))
        return try XCTUnwrap(interceptors.first as? RetryableErrorInterceptor)
    }

    private func throttledFailure(retryAfter: String) -> NetworkResult {
        .failure(NetworkError(type: .non200Status(429, nil),
                              urlResponse: .mock(status: 429, headers: ["Retry-After": retryAfter])))
    }

    func test_retry_interceptor_honors_a_retry_after_within_the_max_delay() throws {
        let interceptor = try collectRetryInterceptor()
        let policy = interceptor.shouldRetry(URLRequest(), consecutiveRetryCount: 0, with: throttledFailure(retryAfter: "1"))
        XCTAssertEqual(delay(of: policy), 1)
    }

    func test_retry_interceptor_waits_for_a_retry_after_above_the_max_delay() throws {
        let interceptor = try collectRetryInterceptor()
        let policy = interceptor.shouldRetry(URLRequest(), consecutiveRetryCount: 0, with: throttledFailure(retryAfter: "500"))
        XCTAssertEqual(delay(of: policy), 500)
    }

// URLProtocolMock seems not to be working on watchos
#if !os(watchOS)
    func test_collect_from_context_retries_a_transient_failure_once_and_completes() {
        let queue = TealiumQueue(label: "collectTestQueue")
        let networkConfiguration = NetworkConfiguration(sessionConfiguration: NetworkConfiguration.defaultUrlSessionConfiguration,
                                                        interceptors: NetworkConfiguration.defaultInterceptors,
                                                        queue: queue)
        networkConfiguration.sessionConfiguration.protocolClasses = [URLProtocolMock.self]
        URLProtocolMock.reply = .list([
            (Data(), .mock(status: 503), nil),
            (Data(), .successful(), nil)
        ])
        let requestSent = expectation(description: "The request is sent twice")
        requestSent.expectedFulfillmentCount = 2
        URLProtocolMock.recordingRequests { _ in requestSent.fulfill() }
        let context = MockContext(moduleManager: ModuleManager(),
                                  networkClient: HTTPClient(configuration: networkConfiguration, logger: nil))
        let collectFromContext = CollectModule(moduleId: Modules.Types.collect, context: context, moduleConfiguration: [:])
        let dispatchCompleted = expectation(description: "The dispatch completes after the retry")
        _ = collectFromContext?.dispatch([stubDispatches[0]], completion: { dispatches in
            XCTAssertEqual(dispatches.map { $0.id }, [self.stubDispatches[0].id])
            dispatchCompleted.fulfill()
        })
        // The jittered retry can wait up to 0.1s on top of two URLSession round trips, more than the default timeout
        wait(for: [requestSent, dispatchCompleted], timeout: Self.longTimeout)
    }
#endif

    func test_updateSettings_changes_collectSettings() {
        let updatedCollect = collect?.updateConfiguration(["url": "customUrl"])
        XCTAssertNotNil(updatedCollect)
        XCTAssertEqual(updatedCollect?.configuration.url.absoluteString, "customUrl")
    }

    func test_updateSettings_with_invalid_urls_returns_nil() {
        let updatedCollect = collect?.updateConfiguration(["url": ""])
        XCTAssertNil(updatedCollect)
    }

    func test_sendSingleDispatch_with_trace_id_adds_query_param() {
        let postRequestSent = expectation(description: "The POST request is sent with trace ID")
        let traceId = "test-trace-123"
        let dispatchWithTrace = Dispatch(name: "event1", data: [
            TealiumDataKey.account: "account",
            TealiumDataKey.profile: "profile",
            TealiumDataKey.tealiumTraceId: traceId
        ])

        mockClient.requestDidSend = { request in
            guard let urlString = self.urlString(of: request) else { return }
            XCTAssertTrue(urlString.contains("tealium_trace_id=\(traceId)"), "URL should contain trace ID query parameter")
            postRequestSent.fulfill()
        }
        _ = collect?.dispatch([dispatchWithTrace], completion: { _ in })
        waitForDefaultTimeout()
    }

    func test_sendSingleDispatch_without_trace_id_does_not_add_query_param() {
        let postRequestSent = expectation(description: "The POST request is sent without trace ID")

        mockClient.requestDidSend = { request in
            guard let urlString = self.urlString(of: request) else { return }
            XCTAssertFalse(urlString.contains("tealium_trace_id"), "URL should not contain trace ID query parameter")
            postRequestSent.fulfill()
        }
        _ = collect?.dispatch([stubDispatches[0]], completion: { _ in })
        waitForDefaultTimeout()
    }

    func test_sendBatchDispatches_with_trace_id_adds_query_param() {
        let postRequestSent = expectation(description: "The batch POST request is sent with trace ID")
        let traceId = "batch-trace-456"
        let dispatchesWithTrace = [
            Dispatch(name: "event1", data: [
                TealiumDataKey.account: "account",
                TealiumDataKey.profile: "profile",
                TealiumDataKey.tealiumTraceId: traceId
            ]),
            Dispatch(name: "event2", data: [
                TealiumDataKey.account: "account",
                TealiumDataKey.profile: "profile",
                TealiumDataKey.tealiumTraceId: traceId
            ])
        ]

        mockClient.requestDidSend = { request in
            guard let urlString = self.urlString(of: request) else { return }
            XCTAssertTrue(urlString.contains("tealium_trace_id=\(traceId)"), "Batch URL should contain trace ID query parameter")
            postRequestSent.fulfill()
        }
        _ = collect?.dispatch(dispatchesWithTrace, completion: { _ in })
        waitForDefaultTimeout()
    }

    func test_sendBatchDispatches_without_trace_id_does_not_add_query_param() {
        let postRequestSent = expectation(description: "The batch POST request is sent without trace ID")

        mockClient.requestDidSend = { request in
            guard let urlString = self.urlString(of: request) else { return }
            XCTAssertFalse(urlString.contains("tealium_trace_id"), "Batch URL should not contain trace ID query parameter")
            postRequestSent.fulfill()
        }
        _ = collect?.dispatch(stubDispatches, completion: { _ in })
        waitForDefaultTimeout()
    }

    func test_sendSingleDispatch_with_empty_trace_id_does_not_add_query_param() {
        let postRequestSent = expectation(description: "The POST request is sent without empty trace ID")
        let dispatchWithEmptyTrace = Dispatch(name: "event1", data: [
            TealiumDataKey.account: "account",
            TealiumDataKey.profile: "profile",
            TealiumDataKey.tealiumTraceId: ""
        ])

        mockClient.requestDidSend = { request in
            guard let urlString = self.urlString(of: request) else { return }
            XCTAssertFalse(urlString.contains("tealium_trace_id"),
                           "URL should not contain trace ID query parameter for empty trace ID")
            postRequestSent.fulfill()
        }
        _ = collect?.dispatch([dispatchWithEmptyTrace], completion: { _ in })
        waitForDefaultTimeout()
    }

    func test_sendBatchDispatches_with_empty_trace_id_does_not_add_query_param() {
        let postRequestSent = expectation(description: "The POST request is sent without empty trace ID")
        let dispatchesWithEmptyTrace = [
            Dispatch(name: "event1", data: [
                TealiumDataKey.account: "account",
                TealiumDataKey.profile: "profile",
                TealiumDataKey.tealiumTraceId: ""
            ]),
            Dispatch(name: "event2", data: [
                TealiumDataKey.account: "account",
                TealiumDataKey.profile: "profile",
                TealiumDataKey.tealiumTraceId: ""
            ])
        ]

        mockClient.requestDidSend = { request in
            guard let urlString = self.urlString(of: request) else { return }
            XCTAssertFalse(urlString.contains("tealium_trace_id"),
                           "URL should not contain trace ID query parameter for empty trace ID")
            postRequestSent.fulfill()
        }
        _ = collect?.dispatch(dispatchesWithEmptyTrace, completion: { _ in })
        waitForDefaultTimeout()
    }

    func test_sendBatchDispatches_with_mixed_trace_ids_uses_first_available() {
        let postRequestSent = expectation(description: "The batch POST request uses first available trace ID")
        let traceId = "first-trace-123"
        let dispatchesWithMixedTrace = [
            Dispatch(name: "event1", data: [
                TealiumDataKey.account: "account",
                TealiumDataKey.profile: "profile"
                // No trace ID
            ]),
            Dispatch(name: "event2", data: [
                TealiumDataKey.account: "account",
                TealiumDataKey.profile: "profile",
                TealiumDataKey.tealiumTraceId: traceId
            ]),
            Dispatch(name: "event3", data: [
                TealiumDataKey.account: "account",
                TealiumDataKey.profile: "profile",
                TealiumDataKey.tealiumTraceId: "second-trace-456"
            ])
        ]

        mockClient.requestDidSend = { request in
            guard let urlString = self.urlString(of: request) else { return }
            XCTAssertTrue(urlString.contains("tealium_trace_id=\(traceId)"),
                          "Batch URL should contain the first available trace ID")
            XCTAssertFalse(urlString.contains("second-trace-999"),
                           "Batch URL should not contain the second trace ID")
            postRequestSent.fulfill()
        }
        _ = collect?.dispatch(dispatchesWithMixedTrace, completion: { _ in })
        waitForDefaultTimeout()
    }

    func test_urlWithTraceId_preserves_existing_query_parameters() {
        // Test the urlWithTraceId method indirectly by using a custom configuration with existing query params
        guard let customUrl = URL(string: "https://collect.tealiumiq.com/event?existing=param") else {
            XCTFail("Could not create URL")
            return
        }
        let customConfig = CollectModuleConfiguration(configuration: ["url": customUrl.absoluteString])
        let customCollect = CollectModule(networkClient: mockClient,
                                          configuration: customConfig,
                                          logger: nil)

        let postRequestSent = expectation(description: "The POST request preserves existing query params")
        let traceId = "preserve-test-123"
        let dispatchWithTrace = Dispatch(name: "event1", data: [
            TealiumDataKey.account: "account",
            TealiumDataKey.profile: "profile",
            TealiumDataKey.tealiumTraceId: traceId
        ])

        mockClient.requestDidSend = { request in
            guard let urlString = self.urlString(of: request) else { return }
            XCTAssertTrue(urlString.contains("existing=param"),
                          "URL should preserve existing query parameters")
            XCTAssertTrue(urlString.contains("tealium_trace_id=\(traceId)"),
                          "URL should contain trace ID query parameter")
            postRequestSent.fulfill()
        }
        _ = customCollect?.dispatch([dispatchWithTrace], completion: { _ in })
        waitForDefaultTimeout()
    }
}
