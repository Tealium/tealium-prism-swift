//
//  Tealium+BarriersTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 09/01/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

public extension Barriers {
    // used in some Tealium+... tests
    static func batching(defaultScope: BarrierScope) -> some BarrierFactory {
        BatchingBarrier.Factory(defaultScope: defaultScope)
    }
}

final class TealiumBarriersTests: TealiumBaseTests {
    func test_batching_barrier_with_enforced_settings_uses_them() {
        config.addModule(MockDispatcher3.factory())
        config.addBarrier(Barriers.batching(forcingSettings: { enforcedSettings in
            enforcedSettings.setBatchSize(5).setScope(.dispatchers(["MockDispatcher3"]))
        }))
        let eventsDispatchedInBatch = expectation(description: "Events dispatched in batch of 2")
        let teal = createTealium()
        MockDispatcher3.onDispatch.subscribeOnce { dispatches in
            XCTAssertEqual(dispatches.count, 5)
            XCTAssertEqual(dispatches.map { $0.name }, ["Event1", "Event2", "Event3", "Event4", "Event5"])
            eventsDispatchedInBatch.fulfill()
        }
        teal.track("Event1")
        teal.track("Event2")
        teal.track("Event3")
        teal.track("Event4")
        teal.track("Event5")
        waitForLongTimeout()
    }

    func test_barrier_with_empty_dispatchers_scope_is_inactive() {
        config.addModule(MockDispatcher3.factory())
        config.addBarrier(Barriers.batching(forcingSettings: { enforcedSettings in
            enforcedSettings.setScope(.dispatchers([]))
        }))
        let eventDispatchedImmediately = expectation(description: "Event dispatched immediately")
        eventDispatchedImmediately.expectedFulfillmentCount = 2
        let teal = createTealium()
        MockDispatcher3.onDispatch.subscribe { dispatches in
            XCTAssertEqual(dispatches.count, 1)
            eventDispatchedImmediately.fulfill()
        }.addTo(disposer)
        teal.track("Event1")
        teal.track("Event2")
        waitForLongTimeout()
    }
}
