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
    var onDispatch: Observable<TealiumDispatch>
    func track(_ dispatch: TealiumDispatch, onTrackResult: TrackResultCompletion?) {
        _onDispatch.publish(dispatch)
        onTrackResult?(dispatch, .accepted)
    }
}
