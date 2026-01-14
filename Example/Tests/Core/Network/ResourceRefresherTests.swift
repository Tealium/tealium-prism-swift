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
        networkHelper.result = .failure(.cancelled)
        let refresher = try createResourceRefresher()
        let inputResource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        try refresher.resourceCacher.saveResource(inputResource, etag: "some_etag")
        let secondRefresher = try createResourceRefresher()
        XCTAssertNotNil(secondRefresher.lastEtag)
    }

    func test_shouldRefresh_is_true_when_resource_is_not_cached() throws {
        networkHelper.result = .failure(.cancelled)
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
        networkHelper.result = .failure(.non200Status(400))
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
        networkHelper.result = .failure(.non200Status(400))
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

    func test_onLatestResource_publishes_an_event_when_a_resource_is_cached() throws {
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

    func test_onResourceLoaded_doesnt_publish_an_event_when_a_resource_is_cached() throws {
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

    func test_onLatestResource_doesnt_publish_an_event_when_a_resource_is_not_cached_and_not_refreshed() throws {
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
