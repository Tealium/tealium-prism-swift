//
//  MockTracker.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 07/12/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumSwift

class MockTracker: Tracker {
    @ToAnyObservable<BasePublisher<TealiumDispatch>>(BasePublisher<TealiumDispatch>())
    var onTrack: Observable<TealiumDispatch>
    var acceptTrack: Bool = true
    func trackResultBuilder(dispatch: TealiumDispatch) -> TrackResult {
        if self.acceptTrack {
            .accepted(dispatch)
        } else {
            .dropped(dispatch)
        }
    }
    func track(_ trackable: TealiumDispatch, source: DispatchContext.Source, onTrackResult: TrackResultCompletion?) {
        _onTrack.publish(trackable)
        onTrackResult?(trackResultBuilder(dispatch: trackable))
    }
}
