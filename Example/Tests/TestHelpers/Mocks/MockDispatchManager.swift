//
//  MockDispatchManager.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 26/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift

class MockDispatchManager: DispatchManagerProtocol {
    @ToAnyObservable(BasePublisher())
    var onDispatch: Observable<Dispatch>
    var tealiumPurposeExplicitlyBlocked: Bool = false
    func track(_ dispatch: Dispatch, onTrackResult: TrackResultCompletion?) {
        _onDispatch.publish(dispatch)
        onTrackResult?(.accepted(dispatch, info: "Mock Accepted"))
    }
}
