//
//  MomentsAPIModuleBaseTests.swift
//  MomentsAPITests_iOS
//
//  Created by Sebastian Krajna on 6/11/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

class MomentsAPIModuleBaseTests: XCTestCase {
    let account = "testAccount"
    let profile = "testProfile"
    let environment = "dev"
    let mockNetworkHelper = MockNetworkHelper()
    var configuration = MomentsAPIConfiguration(region: .usEast, referrer: nil)
    let visitorId = StateSubject("testVisitorId")
    lazy var service = MomentsAPIService(networkHelper: mockNetworkHelper,
                                         account: account,
                                         profile: profile,
                                         environment: environment,
                                         configuration: configuration)
    lazy var module = MomentsAPIModule(service: service,
                                       visitorId: visitorId.asObservableState(),
                                       logger: nil,
                                       configuration: configuration)
}
