//
//  NetworkConfigurationTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 19/06/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import XCTest
@testable import tealium_swift

final class NetworkConfigurationTests: XCTestCase {

    func test_default_session_configuration_cache_is_disable() {
        let sessionConfig = NetworkConfiguration.defaultUrlSessionConfiguration
        XCTAssertNil(sessionConfig.urlCache)
        XCTAssertEqual(sessionConfig.requestCachePolicy, .reloadIgnoringLocalCacheData)
    }
    
    func test_default_interceptors_include_connectivity() {
        let defaultInterceptors = NetworkConfiguration.defaultInterceptors
        XCTAssertTrue(defaultInterceptors.contains(where: { $0 is ConnectivityManager }), "ConnectivityManager should be one of the default interceptors")
    }
    
    func test_DefaultInterceptor_should_be_the_first_intercetor() {
        let defaultInterceptors = NetworkConfiguration.defaultInterceptors
        XCTAssertTrue(defaultInterceptors.first is DefaultInterceptor, "DefaultInterceptor should be the first default interceptor")
    }
    
    
}
