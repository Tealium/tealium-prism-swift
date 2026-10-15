//
//  ResourceRefresherTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 13/06/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

class ResourceRefresherBaseTests: ResourceCacherBaseTests {
    func createResourceRefresher(urlString: String = "someUrl", refreshInterval: TimeFrame = 1.seconds, errorCooldown: ErrorCooldown? = nil) throws -> ResourceRefresher<TestResourceObject> {
        let url = try urlString.asUrl()
        let cacher = try createResourceCacher()
        let parameters = RefreshParameters(id: "refresher_id",
                                           url: url,
                                           refreshInterval: refreshInterval)
        return ResourceRefresher<TestResourceObject>(networkHelper: networkHelper,
                                                     resourceCacher: cacher,
                                                     parameters: parameters,
                                                     errorCooldown: errorCooldown,
                                                     logger: MockLogger())
    }
}

class ResourceRefresherTests: ResourceRefresherBaseTests {

    func test_lastEtag_is_set_at_launch_when_previously_stored() throws {
        networkHelper.setError(.cancelled)
        let refresher = try createResourceRefresher()
        let inputResource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        try refresher.resourceCacher.saveResource(inputResource, etag: "some_etag")
        let secondRefresher = try createResourceRefresher()
        XCTAssertNotNil(secondRefresher.lastEtag)
    }

    func test_shouldRefresh_is_true_when_resource_is_not_cached() throws {
        networkHelper.setError(.cancelled)
        let refresher = try createResourceRefresher()
        XCTAssertTrue(refresher.shouldRefresh)
    }

    func test_shouldRefresh_is_false_after_successful_refresh() throws {
        let inputResource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        try networkHelper.encodeResult(inputResource)
        let resourceLoaded = expectation(description: "Resource is loaded")
        let refresher = try createResourceRefresher()
        refresher.onLatestResource.subscribeOnce { loadedObj in
            resourceLoaded.fulfill()
            XCTAssertEqual(loadedObj, inputResource)
        }
        XCTAssertTrue(refresher.shouldRefresh)
        refresher.requestRefresh()
        waitForDefaultTimeout()
        XCTAssertFalse(refresher.shouldRefresh)
    }

    func test_shouldRefresh_is_true_when_lastFetch_is_older_than_refreshInterval() throws {
        let inputResource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        try networkHelper.encodeResult(inputResource)
        let resourceLoaded = expectation(description: "Resource is loaded")
        let refresher = try createResourceRefresher(refreshInterval: 0.seconds)
        refresher.onLatestResource.subscribeOnce { loadedObj in
            resourceLoaded.fulfill()
            XCTAssertEqual(loadedObj, inputResource)
        }
        XCTAssertTrue(refresher.shouldRefresh)
        refresher.requestRefresh()
        waitForDefaultTimeout()
        XCTAssertTrue(refresher.shouldRefresh)
    }

    func test_shouldRefresh_is_false_during_errorCooldown() throws {
        networkHelper.setError(.non200Status(400, nil))
        let refreshError = expectation(description: "Refresh error happened")
        let refresher = try createResourceRefresher(refreshInterval: 0.seconds, errorCooldown: ErrorCooldown(baseInterval: 5.seconds, maxInterval: 10.seconds))
        refresher.onRefreshError.subscribeOnce { _ in
            refreshError.fulfill()
        }
        XCTAssertTrue(refresher.shouldRefresh)
        refresher.requestRefresh()
        waitForDefaultTimeout()
        XCTAssertFalse(refresher.shouldRefresh)
    }

    func test_shouldRefresh_is_true_after_error_if_errorCooldown_is_nil() throws {
        networkHelper.setError(.non200Status(400, nil))
        let refreshError = expectation(description: "Refresh error happened")
        let refresher = try createResourceRefresher(refreshInterval: 0.seconds)
        refresher.onRefreshError.subscribeOnce { _ in
            refreshError.fulfill()
        }
        XCTAssertTrue(refresher.shouldRefresh)
        refresher.requestRefresh()
        waitForDefaultTimeout()
        XCTAssertTrue(refresher.shouldRefresh)
    }

    func test_shouldRefresh_is_false_during_another_fetch() throws {
        let inputResource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        try networkHelper.encodeResult(inputResource)
        networkHelper.delay = 0
        let resourceLoaded = expectation(description: "Resource is loaded")
        let refresher = try createResourceRefresher(refreshInterval: 0.seconds)
        refresher.onLatestResource.subscribeOnce { loadedObj in
            resourceLoaded.fulfill()
            XCTAssertEqual(loadedObj, inputResource)
        }
        XCTAssertTrue(refresher.shouldRefresh)
        refresher.requestRefresh()
        XCTAssertFalse(refresher.shouldRefresh)
        waitForDefaultTimeout()
        XCTAssertTrue(refresher.shouldRefresh)
    }

    func test_onLatestResource_emits_an_event_when_a_resource_is_cached() throws {
        let inputResource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        try networkHelper.encodeResult(inputResource)
        let resourceLoaded = expectation(description: "Resource is loaded")
        let refresher = try createResourceRefresher()
        try refresher.resourceCacher.saveResource(inputResource, etag: nil)
        refresher.onLatestResource.subscribeOnce { loadedObj in
            resourceLoaded.fulfill()
            XCTAssertEqual(loadedObj, inputResource)
        }
        waitForDefaultTimeout()
    }

    func test_onResourceLoaded_doesnt_emit_an_event_when_a_resource_is_cached() throws {
        let inputResource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        try networkHelper.encodeResult(inputResource)
        let resourceLoaded = expectation(description: "Resource is not loaded")
        resourceLoaded.isInverted = true
        let refresher = try createResourceRefresher()
        try refresher.resourceCacher.saveResource(inputResource, etag: nil)
        refresher.onResourceLoaded.subscribeOnce { _ in
            resourceLoaded.fulfill()
        }
        waitForDefaultTimeout()
      }

    func test_onLatestResource_doesnt_emit_an_event_when_a_resource_is_not_cached_and_not_refreshed() throws {
        let inputResource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        try networkHelper.encodeResult(inputResource)
        let resourceLoaded = expectation(description: "Resource should not be loaded")
        resourceLoaded.isInverted = true
        let refresher = try createResourceRefresher()
        XCTAssertNil(refresher.resourceCacher.readResource())
        let subscription = refresher.onLatestResource.subscribeOnce { loadedObj in
            resourceLoaded.fulfill()
            XCTAssertEqual(loadedObj, inputResource)
        }
        waitForDefaultTimeout()
        subscription.dispose()
    }

    func test_shouldRefresh_is_false_after_refresh_completes_synchronously_with_0_refreshInterval() throws {
        networkHelper.delay = nil
        let refresher = try createResourceRefresher(refreshInterval: 0.seconds)
        XCTAssertTrue(refresher.shouldRefresh)
        refresher.requestRefresh()
        XCTAssertTrue(refresher.shouldRefresh)
    }
}

// URLProtocolMock seems not to be working on watchos
#if !os(watchOS)
/// Drives a `ResourceRefresher` through a real `HTTPClient` on `URLProtocolMock`, using the same interceptors used for the settings.
final class ResourceRefresherSettingsRetryTests: ResourceRefresherBaseTests {
    /// The SDK runs on the main queue: test bodies run on the main thread and `wait(for:)` keeps that queue running.
    /// An expectation fulfilled in a main queue block lets `wait(for:)` return only after that block has finished.
    let queue = TealiumQueue.main
    lazy var connectivityManager = MockConnectivityManager(queue: queue)
    lazy var httpClient: HTTPClient = {
        // Only observes: `onAttemptResult` is called on `queue` right before the retry decision, in the same queue block.
        let completionObserver = MockInterceptor(onAttemptResult: { [weak self] _, _, result in
            self?.onAttemptResult?(result)
        })
        var configuration = NetworkConfiguration(sessionConfiguration: NetworkConfiguration.defaultUrlSessionConfiguration,
                                                 interceptors: [connectivityManager, completionObserver],
                                                 queue: queue)
        configuration.sessionConfiguration.protocolClasses = [URLProtocolMock.self]
        return HTTPClient(configuration: configuration, logger: nil)
    }()
    /// Same cooldown the `SettingsManager` builds for the settings refresher.
    let errorCooldown = ErrorCooldown(baseInterval: 20.seconds, maxInterval: 15.minutes)
    /// Called on `queue` with the result of every request, right before the retry decision is made in the same queue block.
    var onAttemptResult: ((NetworkResult) -> Void)?

    override func tearDown() {
        URLProtocolMock.reset()
        super.tearDown()
    }

    func createSettingsRefresher() throws -> ResourceRefresher<TestResourceObject> {
        let networkHelper = SettingsManager.makeNetworkHelper(client: httpClient, connectivityManager: connectivityManager)
        let parameters = RefreshParameters(id: "settings",
                                           url: try "https://www.tealium.com/settings.json".asUrl(),
                                           refreshInterval: 15.minutes)
        let refresher = ResourceRefresher<TestResourceObject>(networkHelper: networkHelper,
                                                              resourceCacher: try createResourceCacher(),
                                                              parameters: parameters,
                                                              errorCooldown: errorCooldown,
                                                              logger: MockLogger())
        return refresher
    }

    /// Subscribes to the failure and completion of the refresh of `refresher`.
    ///
    /// - Returns: the expectations fulfilled when the refresh fails and when it completes.
    func expectRefreshToFail(_ refresher: ResourceRefresher<TestResourceObject>) -> [XCTestExpectation] {
        let refreshFailed = expectation(description: "The refresh fails")
        let loadCompleted = expectation(description: "The refresh completes")
        refresher.onRefreshError.subscribeOnce { _ in
            refreshFailed.fulfill()
        }
        refresher.onLoadCompleted.subscribeOnce {
            loadCompleted.fulfill()
        }
        return [refreshFailed, loadCompleted]
    }

    func test_fetch_failing_on_every_attempt_completes_after_three_requests_and_enters_the_error_cooldown() throws {
        URLProtocolMock.reply = .always((Data(), .mock(status: 503), nil))
        let recorder = URLProtocolMock.recordingRequests()
        let refresher = try createSettingsRefresher()
        let refreshFinished = expectRefreshToFail(refresher)
        refresher.requestRefresh()
        wait(for: refreshFinished, timeout: Self.longTimeout)
        XCTAssertEqual(recorder.dates.count, 3)
        XCTAssertTrue(errorCooldown.isInCooldown(lastFetch: Date()), "The failed refresh should start the error cooldown")
        XCTAssertFalse(refresher.shouldRefresh, "A new refresh should not start during the error cooldown")
        errorCooldown.newCooldownEvent(error: nil)
        XCTAssertTrue(refresher.shouldRefresh, "Without the cooldown a new refresh can start, so no fetch is in progress")
    }

    /// Returns an expectation fulfilled once the retry decision for the first request has been made:
    /// `onAttemptResult` runs in the same queue block as the decision.
    func expectFirstRetryDecision() -> XCTestExpectation {
        let firstRequestCompleted = expectation(description: "The first request completes and its retry decision is made")
        onAttemptResult = { [weak self] _ in
            self?.onAttemptResult = nil
            firstRequestCompleted.fulfill()
        }
        return firstRequestCompleted
    }

    /// Waits for the first request to be sent and its retry decision to be made, then checks that
    /// `retriedWhileOffline` (an inverted expectation) has not been fulfilled.
    ///
    /// The retry decision is made in the same queue block as `onAttemptResult`: once this returns, the retry is waiting for connectivity.
    func waitUntilRetryIsWaitingForConnectivity(firstRequestSent: XCTestExpectation,
                                                retryDecided: XCTestExpectation,
                                                retriedWhileOffline: XCTestExpectation) {
        wait(for: [firstRequestSent, retryDecided], timeout: Self.longTimeout)
        wait(for: [retriedWhileOffline], timeout: 0)
    }

    func test_fetch_retries_at_most_ten_times_while_offline() throws {
        let offlineFailure: MockReply.Response = (nil, nil, URLError(.notConnectedToInternet))
        // 11 offline failures, then a success that only a 12th request would receive.
        URLProtocolMock.reply = .list(Array(repeating: offlineFailure, count: 11) + [(Data(), .successful(), nil)])
        let recorder = URLProtocolMock.recordingRequests()
        let refresher = try createSettingsRefresher()
        let refreshFinished = expectRefreshToFail(refresher)
        let monitor = connectivityManager.mockConnectivityMonitor
        // Every request fails while offline, so the `ConnectivityRetryInterceptor` proposes each retry
        // and waits for connectivity (no backoff delay), which is restored once it started waiting.
        // Only `settingsMaxRetryCount` stops the retries.
        onAttemptResult = { result in
            guard case let .failure(error) = result, case .urlError = error.type else {
                return
            }
            monitor.changeConnection(.notConnected)
            // Runs after the current queue block, in which the connectivity interceptor started waiting.
            DispatchQueue.main.async {
                monitor.changeConnection(.connected(.wifi))
            }
        }
        refresher.requestRefresh()
        wait(for: refreshFinished, timeout: Self.longTimeout)
        XCTAssertEqual(recorder.dates.count, 1 + SettingsManager.settingsMaxRetryCount)
    }

    func test_throttled_fetch_with_retry_after_above_max_delay_fails_after_one_request() throws {
        URLProtocolMock.reply = .always((Data(), .mock(status: 429, headers: ["Retry-After": "30"]), nil))
        let recorder = URLProtocolMock.recordingRequests()
        let refresher = try createSettingsRefresher()
        let refreshFailed = expectation(description: "The refresh fails")
        refresher.onRefreshError.subscribeOnce { _ in
            refreshFailed.fulfill()
        }
        refresher.requestRefresh()
        wait(for: [refreshFailed], timeout: Self.longTimeout)
        XCTAssertEqual(recorder.dates.count, 1)
    }

    func test_fetch_failing_while_offline_waits_for_connectivity_and_then_retries_once() throws {
        let resource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        URLProtocolMock.reply = .list([
            (nil, nil, URLError(.notConnectedToInternet)),
            (try Tealium.jsonEncoder.encode(resource), .successful(), nil)
        ])
        let firstRequestSent = expectation(description: "The first request is sent")
        let retriedWhileOffline = expectation(description: "No request is sent while offline")
        retriedWhileOffline.isInverted = true
        let retriedWhenOnline = expectation(description: "The request is retried once connectivity returns")
        let resourceLoaded = expectation(description: "The resource is loaded after the retry")
        // The second request is the first one sent after the connectivity returned: the offline check is done before it.
        let recorder = URLProtocolMock.recordingRequests { count in
            switch count {
            case 1:
                firstRequestSent.fulfill()
            case 2:
                retriedWhileOffline.fulfill()
                retriedWhenOnline.fulfill()
            default:
                XCTFail("Unexpected request number \(count)")
            }
        }
        let refresher = try createSettingsRefresher()
        let retryDecided = expectFirstRetryDecision()
        refresher.onResourceLoaded.subscribeOnce { loadedResource in
            XCTAssertEqual(loadedResource, resource)
            resourceLoaded.fulfill()
        }
        connectivityManager.mockConnectivityMonitor.changeConnection(.notConnected)
        XCTAssertFalse(connectivityManager.connectionAssumedAvailable.value)
        refresher.requestRefresh()
        waitUntilRetryIsWaitingForConnectivity(firstRequestSent: firstRequestSent, retryDecided: retryDecided, retriedWhileOffline: retriedWhileOffline)
        XCTAssertEqual(recorder.dates.count, 1)
        connectivityManager.mockConnectivityMonitor.changeConnection(.connected(.wifi))
        wait(for: [retriedWhenOnline, resourceLoaded], timeout: Self.longTimeout)
        XCTAssertEqual(recorder.dates.count, 2)
    }

    /// Offline first attempt, then 3 attempts in a row while online (the `RetryableErrorInterceptor` restarts its
    /// budget once `ConnectivityRetryInterceptor` proposed the retry that waited for connectivity).
    func test_fetch_failing_offline_then_failing_on_every_online_attempt_completes_after_four_requests() throws {
        let failure503: MockReply.Response = (Data(), .mock(status: 503), nil)
        URLProtocolMock.reply = .list([
            (nil, nil, URLError(.notConnectedToInternet)),
            failure503,
            failure503,
            failure503
        ])
        let firstRequestSent = expectation(description: "The first (offline) request is sent")
        let retriedWhileOffline = expectation(description: "No request is sent while still offline")
        retriedWhileOffline.isInverted = true
        // Only the second request, the first one sent after the connectivity returned, fulfills the offline-only expectation.
        let recorder = URLProtocolMock.recordingRequests { count in
            switch count {
            case 1:
                firstRequestSent.fulfill()
            case 2:
                retriedWhileOffline.fulfill()
            default:
                break
            }
        }
        let refresher = try createSettingsRefresher()
        let refreshFinished = expectRefreshToFail(refresher)
        // Connectivity must return only after the offline retry decision (the `afterEvent` subscription) is set up,
        // otherwise the connectivity change below could race ahead of it.
        let retryDecided = expectFirstRetryDecision()
        connectivityManager.mockConnectivityMonitor.changeConnection(.notConnected)
        XCTAssertFalse(connectivityManager.connectionAssumedAvailable.value)
        refresher.requestRefresh()
        waitUntilRetryIsWaitingForConnectivity(firstRequestSent: firstRequestSent, retryDecided: retryDecided, retriedWhileOffline: retriedWhileOffline)
        XCTAssertEqual(recorder.dates.count, 1)
        connectivityManager.mockConnectivityMonitor.changeConnection(.connected(.wifi))
        wait(for: refreshFinished, timeout: Self.longTimeout)
        XCTAssertEqual(recorder.dates.count, 4)
    }
}
#endif
