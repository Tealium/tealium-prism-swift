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
    func track(_ trackable: TealiumDispatch, onTrackResult: TrackResultCompletion?) {
    }
}
