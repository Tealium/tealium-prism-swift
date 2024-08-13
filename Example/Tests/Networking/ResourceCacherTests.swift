//
//  ResourceCacherTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 17/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

class ResourceCacherBaseTests: XCTestCase {
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

    func createResourceCacher() throws -> ResourceCacher<TestResourceObject> {
        ResourceCacher<TestResourceObject>(dataStore: try dataStoreProvider.getModuleStore(name: "test"), fileName: "file_name")
    }
}

final class ResourceCacherTests: ResourceCacherBaseTests {

    func test_saveResource_stores_the_object() throws {
        let cacher = try createResourceCacher()
        let inputResource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        try cacher.saveResource(inputResource, etag: nil)
        let outputResource = cacher.readResource()
        XCTAssertEqual(inputResource, outputResource)
    }

    func test_saveResource_stores_the_etag() throws {
        let cacher = try createResourceCacher()
        let inputResource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        try cacher.saveResource(inputResource, etag: "some_etag")
        let etag = cacher.readEtag()
        XCTAssertEqual(etag, "some_etag")
    }

    func test_saveResource_without_etag_deletes_previous_etag() throws {
        let cacher = try createResourceCacher()
        let inputResource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        try cacher.saveResource(inputResource, etag: "some_etag")
        XCTAssertEqual(cacher.readEtag(), "some_etag")
        try cacher.saveResource(inputResource, etag: nil)
        XCTAssertNil(cacher.readEtag())
    }

    func test_readResource_returns_nil_at_launch() throws {
        let cacher = try createResourceCacher()
        XCTAssertNil(cacher.readResource())
    }

    func test_readResource_returns_object_at_launch_when_previously_stored() throws {
        let cacher = try createResourceCacher()
        let inputResource = TestResourceObject(propertyString: "abc", propertyInt: 123)
        try cacher.saveResource(inputResource, etag: "some_etag")
        let secondCacher = try createResourceCacher()
        XCTAssertEqual(secondCacher.readResource(), inputResource)
    }

}
