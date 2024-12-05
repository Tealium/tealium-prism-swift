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
    func track(_ trackable: TealiumDispatch, onTrackResult: TrackResultCompletion?) {
        _onTrack.publish(trackable)
        onTrackResult?(trackable, .accepted)
    }
}
