//
//  MockTracker.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 07/12/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumPrism

class MockTracker: Tracker {
    @Subject<Dispatch> var onTrack
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
