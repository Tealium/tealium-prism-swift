//
//  NetworkConfigurationTests.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 19/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class NetworkConfigurationTests: XCTestCase {

    func test_default_session_configuration_cache_is_disabled() {
        let sessionConfig = NetworkConfiguration.defaultUrlSessionConfiguration
        XCTAssertNil(sessionConfig.urlCache)
        XCTAssertEqual(sessionConfig.requestCachePolicy, .reloadIgnoringLocalCacheData)
    }

    func test_default_session_configuration_does_not_wait_for_connectivity() {
        let sessionConfig = NetworkConfiguration.defaultUrlSessionConfiguration
        XCTAssertFalse(sessionConfig.waitsForConnectivity)
    }

    func test_default_session_configuration_request_timeout_is_30_seconds() {
        let sessionConfig = NetworkConfiguration.defaultUrlSessionConfiguration
        XCTAssertEqual(sessionConfig.timeoutIntervalForRequest, 30)
    }

    func test_default_session_configuration_resource_timeout_is_unchanged() {
        let sessionConfig = NetworkConfiguration.defaultUrlSessionConfiguration
        let ephemeralConfig = URLSessionConfiguration.ephemeral
        XCTAssertEqual(sessionConfig.timeoutIntervalForResource, ephemeralConfig.timeoutIntervalForResource)
    }

    func test_default_interceptors_only_contain_the_connectivity_manager() {
        let defaultInterceptors = NetworkConfiguration.defaultInterceptors
        XCTAssertEqual(defaultInterceptors.count, 1)
        XCTAssertTrue(defaultInterceptors.first is ConnectivityManager, "ConnectivityManager should be the only default interceptor")
    }

    func test_interceptorManager_has_configuration_queue() {
        let testQueue = TealiumQueue(label: "com.tealium.test_queue")
        let config = NetworkConfiguration(sessionConfiguration: NetworkConfiguration.defaultUrlSessionConfiguration,
                                          interceptors: NetworkConfiguration.defaultInterceptors,
                                          queue: testQueue)
        XCTAssertIdentical(config.interceptorManager.queue, testQueue)
    }
}
