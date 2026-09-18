//
//  ContextAPIServiceBaseTests.swift
//  ContextAPITests_iOS
//
//  Created by Sebastian Krajna on 6/11/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

class ContextAPIServiceBaseTests: XCTestCase {
    let mockNetworkHelper = MockNetworkHelper()
    lazy var service = createService()
    let account = "testAccount"
    let profile = "testProfile"
    let environment = "dev"

    func createService(region: ContextAPIRegion = .usEast, referrer: String? = nil) -> ContextAPIService {
        ContextAPIService(
            networkHelper: mockNetworkHelper,
            account: account,
            profile: profile,
            environment: environment,
            configuration: ContextAPIConfiguration(region: region, referrer: referrer)
        )
    }

}
