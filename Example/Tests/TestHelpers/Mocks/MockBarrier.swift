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
    init() {}
    @ToAnyObservable(ReplaySubject<BarrierState>(initialValue: .open))
    var state: Observable<BarrierState>

    func onState(for dispatcherId: String) -> Observable<BarrierState> {
        return state
    }

    func setState(_ newState: BarrierState) {
        _state.publisher.publish(newState)
    }
}

class MockConfigurableBarrier: MockBarrier, ConfigurableBarrier {
    class var id: String { "MockBarrier" }

    var lastConfiguration: DataObject = [:]

    required override init() {}

    func shouldQueue(dispatch: Dispatch) -> Bool {
        return false
    }

    func updateConfiguration(_ configuration: DataObject) {
        lastConfiguration = configuration
    }
}

class MockBarrier1: MockConfigurableBarrier {
    override class var id: String { "barrier1" }
}

class MockBarrier2: MockConfigurableBarrier {
    override class var id: String { "barrier2" }
}

class MockBarrierFactory<SomeBarrier: MockConfigurableBarrier>: BarrierFactory {
    typealias BarrierType = SomeBarrier
    let _defaultScopes: [BarrierScope]

    init(defaultScope: [BarrierScope]) {
        _defaultScopes = defaultScope
    }

    func create(context: TealiumContext, configuration: DataObject) -> BarrierType {
        let barrier = SomeBarrier()
        barrier.updateConfiguration(configuration)
        return barrier
    }

    func defaultScopes() -> [BarrierScope] {
        _defaultScopes
    }
}
