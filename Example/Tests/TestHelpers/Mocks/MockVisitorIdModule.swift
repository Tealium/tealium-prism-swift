//
//  MockVisitorIdModule.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 14/10/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism

/// A minimal `VisitorIdProvider` module, standing in for the `VisitorIdModule` the Context API reads the visitor ID from.
final class MockVisitorIdModule: Module, VisitorIdProvider {
    let id = Modules.Types.visitorId
    let version = TealiumConstants.libraryVersion
    @StateSubject var visitorId: ObservableState<String>
    init(visitorId: String) {
        _visitorId = StateSubject(visitorId)
    }
}
