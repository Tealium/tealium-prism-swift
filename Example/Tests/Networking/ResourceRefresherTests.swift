//
//  ResourceRefresherTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 13/06/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

class ResourceRefresherBaseTests: XCTestCase {
    struct TestResourceObject: Codable, Equatable {
        let propertyString: String
        let propertyInt: Int
    }
    let networkHelper = {
        let networkHelper = MockNetworkHelper()
        networkHelper.delay = 0
        return networkHelper
    }()
    let databaseProvider = MockDatabaseProvider()
    lazy var dataStoreProvider = ModuleStoreProvider(databaseProvider: databaseProvider,
                                                     modulesRepository: SQLModulesRepository(dbProvider: databaseProvider))

    func createResourceRefresher(urlString: String = "someUrl", refreshInterval: Double = 1.0, errorCooldown: ErrorCooldown? = nil) throws -> ResourceRefresher<TestResourceObject> {
        guard let url = URL(string: urlString) else {
            throw ParsingError.invalidUrl(urlString)
        }
        let parameters = RefreshParameters(id: "refresher_id",
                                           url: url,
                                           fileName: "file_name",
                                           refreshInterval: refreshInterval)
        return ResourceRefresher<TestResourceObject>(networkHelper: networkHelper,
                                                     dataStore: try dataStoreProvider.getModuleStore(name: "test"),
                                                     parameters: parameters,
                                                     errorCooldown: errorCooldown)
    }
}

class ResourceRefresherTests: ResourceRefresherBaseTests {
    func test_saveResource_stores_the_object() throws {
        let refresher = try createResourceRefresher()
        let inputResource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        refresher.saveResource(inputResource, etag: nil)
        let outputResource = refresher.readResource()
        XCTAssertEqual(inputResource, outputResource)
    }

    func test_saveResource_stores_the_etag() throws {
        let refresher = try createResourceRefresher()
        let inputResource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        refresher.saveResource(inputResource, etag: "some_etag")
        let etag = refresher.dataStore.get(key: refresher.etagStorageKey)?.getString()
        XCTAssertEqual(etag, "some_etag")
    }

    func test_lastEtag_is_set_at_launch_when_previously_stored() throws {
        networkHelper.result = .failure(.cancelled)
        let refresher = try createResourceRefresher()
        let inputResource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        refresher.saveResource(inputResource, etag: "some_etag")
        let secondRefresher = try createResourceRefresher()
        XCTAssertNotNil(secondRefresher.lastEtag)
    }

    func test_readResource_returns_nil_at_launch() throws {
        networkHelper.result = .failure(.cancelled)
        let refresher = try createResourceRefresher()
        XCTAssertNil(refresher.readResource())
    }

    func test_readResource_returns_object_at_launch_when_previously_stored() throws {
        networkHelper.result = .failure(.cancelled)
        let refresher = try createResourceRefresher()
        let inputResource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        refresher.saveResource(inputResource, etag: "some_etag")
        let secondRefresher = try createResourceRefresher()
        XCTAssertNotNil(secondRefresher.readResource())
    }

    func test_shouldRefresh_is_true_when_resource_is_not_cached() throws {
        networkHelper.result = .failure(.cancelled)
        let refresher = try createResourceRefresher()
        XCTAssertTrue(refresher.shouldRefresh)
    }

    func test_shouldRefresh_is_false_after_successful_refresh() throws {
        let inputResource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        networkHelper.codableResult = .success(.successful(object: inputResource))
        let resourceLoaded = expectation(description: "Resource is loaded")
        let refresher = try createResourceRefresher()
        refresher.onResourceLoaded.subscribeOnce { loadedObj in
            resourceLoaded.fulfill()
            XCTAssertEqual(loadedObj, inputResource)
        }
        XCTAssertTrue(refresher.shouldRefresh)
        refresher.requestRefresh()
        waitForExpectations(timeout: 1.0)
        XCTAssertFalse(refresher.shouldRefresh)
    }

    func test_shouldRefresh_is_true_when_lastFetch_is_older_than_refreshInterval() throws {
        let inputResource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        networkHelper.codableResult = .success(.successful(object: inputResource))
        let resourceLoaded = expectation(description: "Resource is loaded")
        let refresher = try createResourceRefresher(refreshInterval: 0.0)
        refresher.onResourceLoaded.subscribeOnce { loadedObj in
            resourceLoaded.fulfill()
            XCTAssertEqual(loadedObj, inputResource)
        }
        XCTAssertTrue(refresher.shouldRefresh)
        refresher.requestRefresh()
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(refresher.shouldRefresh)
    }

    func test_shouldRefresh_is_false_during_errorCooldown() throws {
        networkHelper.codableResult = .failure(.non200Status(400))
        let refreshError = expectation(description: "Refresh error happened")
        let refresher = try createResourceRefresher(refreshInterval: 0.0, errorCooldown: ErrorCooldown(baseInterval: 5, maxInterval: 10))
        refresher.onRefreshError.subscribeOnce { _ in
            refreshError.fulfill()
        }
        XCTAssertTrue(refresher.shouldRefresh)
        refresher.requestRefresh()
        waitForExpectations(timeout: 1.0)
        XCTAssertFalse(refresher.shouldRefresh)
    }

    func test_shouldRefresh_is_true_after_error_if_errorCooldown_is_nil() throws {
        networkHelper.codableResult = .failure(.non200Status(400))
        let refreshError = expectation(description: "Refresh error happened")
        let refresher = try createResourceRefresher(refreshInterval: 0.0)
        refresher.onRefreshError.subscribeOnce { _ in
            refreshError.fulfill()
        }
        XCTAssertTrue(refresher.shouldRefresh)
        refresher.requestRefresh()
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(refresher.shouldRefresh)
    }

    func test_shouldRefresh_is_false_during_another_fetch() throws {
        let inputResource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        networkHelper.codableResult = .success(.successful(object: inputResource))
        networkHelper.delay = 500
        let resourceLoaded = expectation(description: "Resource is loaded")
        let refresher = try createResourceRefresher(refreshInterval: 0.0)
        refresher.onResourceLoaded.subscribeOnce { loadedObj in
            resourceLoaded.fulfill()
            XCTAssertEqual(loadedObj, inputResource)
        }
        XCTAssertTrue(refresher.shouldRefresh)
        refresher.requestRefresh()
        XCTAssertFalse(refresher.shouldRefresh)
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(refresher.shouldRefresh)
    }

  func test_onResourceLoaded_publishes_an_event_when_a_resource_is_cached() throws {
        let inputResource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        networkHelper.codableResult = .success(.successful(object: inputResource))
        let resourceLoaded = expectation(description: "Resource is loaded")
        let refresher = try createResourceRefresher()
        refresher.saveResource(inputResource, etag: nil)
        refresher.onResourceLoaded.subscribeOnce { loadedObj in
            resourceLoaded.fulfill()
            XCTAssertEqual(loadedObj, inputResource)
        }
        waitForExpectations(timeout: 1.0)
    }

    func test_onResourceLoaded_doesnt_publish_an_event_when_a_resource_is_not_cached_and_not_refreshed() throws {
        let inputResource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        networkHelper.codableResult = .success(.successful(object: inputResource))
        let resourceLoaded = expectation(description: "Resource should not be loaded")
        resourceLoaded.isInverted = true
        let refresher = try createResourceRefresher()
        XCTAssertNil(refresher.readResource())
        let subscription = refresher.onResourceLoaded.subscribeOnce { loadedObj in
            resourceLoaded.fulfill()
            XCTAssertEqual(loadedObj, inputResource)
        }
        waitForExpectations(timeout: 1.0)
        subscription.dispose()
    }
}
