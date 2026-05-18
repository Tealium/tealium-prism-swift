//
//  MockDispatchManager.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 26/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism

class MockDispatchManager: DispatchManagerProtocol {
    @Subject<Dispatch> var onDispatch
    var tealiumPurposeExplicitlyBlocked: Bool = false
    func track(_ dispatch: Dispatch, onTrackResult: TrackResultCompletion?) {
        _onDispatch.onNext(dispatch)
        onTrackResult?(.accepted(dispatch, info: "Mock Accepted"))
    }
}
