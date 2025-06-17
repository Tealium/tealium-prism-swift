//
//  ResourceRefresherTests+RequestRefresh.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 17/06/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class ResourceRefresherRequestRefreshTests: ResourceRefresherBaseTests {

    func test_requestRefresh_refreshes_resource() throws {
        let inputResource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        networkHelper.codableResult = .success(.successful(object: inputResource))
        let requestSent = expectation(description: "Request is sent")
        networkHelper.requests.subscribeOnce { _ in
            requestSent.fulfill()
        }
        let refresher = try createResourceRefresher()
        refresher.requestRefresh()
        waitForDefaultTimeout()
    }

    func test_requestRefresh_causes_resource_to_be_cached_when_successful() throws {
        let inputResource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        networkHelper.codableResult = .success(.successful(object: inputResource))
        let resourceLoaded = expectation(description: "Resource is loaded")
        let refresher = try createResourceRefresher()
        refresher.onLatestResource.subscribeOnce { _ in
            resourceLoaded.fulfill()
        }
        XCTAssertNil(refresher.resourceCacher.readResource())
        refresher.requestRefresh()
        waitForDefaultTimeout()
        XCTAssertEqual(refresher.resourceCacher.readResource(), inputResource)
    }

    func test_requestRefresh_when_cache_is_empty_causes_onResourceLoaded_to_publish_the_resource_as_an_event() throws {
        let inputResource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        networkHelper.codableResult = .success(.successful(object: inputResource))
        let resourceLoaded = expectation(description: "Resource is loaded")
        let refresher = try createResourceRefresher()
        refresher.onLatestResource.subscribeOnce { loadedObj in
            resourceLoaded.fulfill()
            XCTAssertEqual(loadedObj, inputResource)
        }
        XCTAssertNil(refresher.resourceCacher.readResource())
        refresher.requestRefresh()
        waitForDefaultTimeout()
    }

    func test_requestRefresh_when_cache_is_full_causes_onResourceLoaded_to_publish_two_subsequent_resources() throws {
        let inputResource1 = TestResourceObject(propertyString: "abc", propertyInt: 123)
        let inputResource2 = TestResourceObject(propertyString: "def", propertyInt: 456)
        networkHelper.codableResult = .success(.successful(object: inputResource2))
        let resourceLoaded = expectation(description: "Resource is loaded")
        resourceLoaded.expectedFulfillmentCount = 2
        let refresher = try createResourceRefresher()
        try refresher.resourceCacher.saveResource(inputResource1, etag: nil)
        XCTAssertNotNil(refresher.resourceCacher.readResource())
        var count = 0
        let subscription = refresher.onLatestResource.subscribe { loadedObj in
            resourceLoaded.fulfill()
            if count == 0 {
                XCTAssertEqual(loadedObj, inputResource1)
            } else {
                XCTAssertEqual(loadedObj, inputResource2)
            }
            count += 1
        }
        refresher.requestRefresh()
        waitForDefaultTimeout()
        subscription.dispose()
    }

    func test_requestRefresh_ignores_notModified_resources() throws {
        networkHelper.codableResult = .failure(.non200Status(304))
        let resourceLoaded = expectation(description: "Resource should not be loaded")
        resourceLoaded.isInverted = true
        let refresherError = expectation(description: "No Error should be reported")
        refresherError.isInverted = true
        let refresher = try createResourceRefresher()
        let automaticDisposer = AutomaticDisposer()
        refresher.onLatestResource.subscribe { _ in
            resourceLoaded.fulfill()
        }.addTo(automaticDisposer)
        refresher.onRefreshError.subscribe { _ in
            refresherError.fulfill()
        }.addTo(automaticDisposer)
        refresher.requestRefresh()
        waitForDefaultTimeout()
    }

    func test_requestRefresh_failure_is_reported_to_onRefreshError() throws {
        networkHelper.codableResult = .failure(.non200Status(400))
        let refresherError = expectation(description: "Error should be reported")
        let refresher = try createResourceRefresher()
        refresher.onRefreshError.subscribeOnce { error in
            refresherError.fulfill()
            XCTAssertEqual(error as? NetworkError, .non200Status(400))
        }
        refresher.requestRefresh()
        waitForDefaultTimeout()
    }

    func test_requestRefresh_ignores_invalid_objects() throws {
        let inputResource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        networkHelper.codableResult = .success(.successful(object: inputResource))
        let resourceNotLoaded = expectation(description: "Resource should not be loaded")
        resourceNotLoaded.isInverted = true
        let refresher = try createResourceRefresher()
        refresher.onLatestResource.subscribeOnce { _ in
            resourceNotLoaded.fulfill()
        }
        refresher.requestRefresh { _ in
            return false
        }
        waitForDefaultTimeout()
    }

    func test_requestRefresh_causes_onLoadCompleted_after_onLatestResources_when_success() throws {
        let inputResource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        networkHelper.codableResult = .success(.successful(object: inputResource))
        let resourceLoaded = expectation(description: "Resource should be loaded")
        let loadCompleted = expectation(description: "Load Completed")
        let refresher = try createResourceRefresher()
        refresher.onLatestResource.subscribeOnce { _ in
            resourceLoaded.fulfill()
        }
        refresher.onLoadCompleted.subscribeOnce {
            loadCompleted.fulfill()
        }
        refresher.requestRefresh()
        wait(for: [resourceLoaded, loadCompleted], timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_requestRefresh_causes_onLoadCompleted_after_onError_when_failure() throws {
        networkHelper.codableResult = .failure(.non200Status(404))
        let errorEmitted = expectation(description: "Error should be emitted")
        let loadCompleted = expectation(description: "Load Completed")
        let refresher = try createResourceRefresher()
        refresher.onRefreshError.subscribeOnce { _ in
            errorEmitted.fulfill()
        }
        refresher.onLoadCompleted.subscribeOnce {
            loadCompleted.fulfill()
        }
        refresher.requestRefresh()
        wait(for: [errorEmitted, loadCompleted], timeout: Self.defaultTimeout, enforceOrder: true)
    }

    func test_requestRefresh_causes_onLoadCompleted_when_notModified() throws {
        networkHelper.codableResult = .failure(.non200Status(304))
        let errorNotEmitted = expectation(description: "Error should not be emitted")
        errorNotEmitted.isInverted = true
        let loadCompleted = expectation(description: "Load Completed")
        let refresher = try createResourceRefresher()
        refresher.onRefreshError.subscribeOnce { _ in
            errorNotEmitted.fulfill()
        }
        refresher.onLoadCompleted.subscribeOnce {
            loadCompleted.fulfill()
        }
        refresher.requestRefresh()
        waitForDefaultTimeout()
    }

}
