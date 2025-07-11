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
    @ToAnyObservable<BasePublisher<Dispatch>>(BasePublisher<Dispatch>())
    var onTrack: Observable<Dispatch>
    var acceptTrack: Bool = true
    func trackResultBuilder(dispatch: Dispatch) -> TrackResult {
        if self.acceptTrack {
            .accepted(dispatch, info: "Mock Accepted")
        } else {
            .dropped(dispatch, reason: "Mock Dropped")
        }
    }
    func track(_ trackable: Dispatch, source: DispatchContext.Source, onTrackResult: TrackResultCompletion?) {
        _onTrack.publish(trackable)
        onTrackResult?(trackResultBuilder(dispatch: trackable))
    }
}
