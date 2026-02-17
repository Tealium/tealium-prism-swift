//
//  MomentsAPIServiceBaseTests.swift
//  MomentsAPITests_iOS
//
//  Created by Sebastian Krajna on 6/11/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

class MomentsAPIServiceBaseTests: XCTestCase {
    let mockNetworkHelper = MockNetworkHelper()
    lazy var service = createService()
    let account = "testAccount"
    let profile = "testProfile"
    let environment = "dev"

    func createService(region: MomentsAPIRegion = .usEast, referrer: String? = nil) -> MomentsAPIService {
        MomentsAPIService(
            networkHelper: mockNetworkHelper,
            account: account,
            profile: profile,
            environment: environment,
            configuration: MomentsAPIConfiguration(region: region, referrer: referrer)
        )
    }

}
