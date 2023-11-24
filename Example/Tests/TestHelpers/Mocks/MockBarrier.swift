//
//  MockBarrier.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 21/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumSwift

class MockBarrier: Barrier {
    let id: String

    init(id: String = "mock") {
        self.id = id
    }

    @ToAnyObservable(TealiumReplaySubject<BarrierState>(initialValue: .open))
    var onState: TealiumObservable<BarrierState>

    func setState(_ newState: BarrierState) {
        _onState.publisher.publishIfChanged(newState)
    }
}
