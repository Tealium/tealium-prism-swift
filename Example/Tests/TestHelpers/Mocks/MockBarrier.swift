//
//  MockBarrier.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 21/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumPrism

class MockBarrier: Barrier {
    @ReplaySubject<Bool>(true)
    var isFlushable

    init() {}
    @ReplaySubject<BarrierState>(.open)
    var state

    func onState(for dispatcherId: String) -> Observable<BarrierState> {
        return state
    }

    func setState(_ newState: BarrierState) {
        _state.publish(newState)
    }

    func setFlushable(_ flushable: Bool) {
        _isFlushable.publish(flushable)
    }
}

class MockConfigurableBarrier: MockBarrier, ConfigurableBarrier {
    class var id: String { "MockBarrier" }

    var lastConfiguration: DataObject = [:]

    required override init() {}

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
    let barrier = SomeBarrier()
    init(defaultScope: [BarrierScope]) {
        _defaultScopes = defaultScope
    }

    func create(context: TealiumContext, configuration: DataObject) -> BarrierType {
        barrier.updateConfiguration(configuration)
        return barrier
    }

    func defaultScopes() -> [BarrierScope] {
        _defaultScopes
    }
}
