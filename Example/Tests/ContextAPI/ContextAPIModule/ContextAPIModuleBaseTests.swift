//
//  ContextAPIModuleBaseTests.swift
//  ContextAPITests_iOS
//
//  Created by Sebastian Krajna on 6/11/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

/// A minimal stub of a `VisitorIdProvider`, standing in for the `VisitorIdModule`.
private final class StubVisitorIdProvider: VisitorIdProvider {
    @StateSubject var visitorId: ObservableState<String>
    init(visitorId: String) {
        _visitorId = StateSubject(visitorId)
    }
}

class ContextAPIModuleBaseTests: XCTestCase {
    let account = "testAccount"
    let profile = "testProfile"
    let environment = "dev"
    let mockNetworkHelper = MockNetworkHelper()
    var configuration = ContextAPIConfiguration(region: .usEast, referrer: nil)
    /// Set to `nil` to simulate visitor ID handling being disabled.
    var visitorIdProvider: VisitorIdProvider? = StubVisitorIdProvider(visitorId: "testVisitorId")
    var logger: LoggerProtocol?
    lazy var service = ContextAPIService(networkHelper: mockNetworkHelper,
                                         account: account,
                                         profile: profile,
                                         environment: environment,
                                         configuration: configuration)
    lazy var getVisitorIdProvider: ContextAPIModule.VisitorIdProviderLookup = { [weak self] completion in
        completion(self?.visitorIdProvider)
        return Disposables.disposed()
    }
    lazy var module = ContextAPIModule(service: service,
                                       getVisitorIdProvider: getVisitorIdProvider,
                                       logger: logger,
                                       configuration: configuration)
}
