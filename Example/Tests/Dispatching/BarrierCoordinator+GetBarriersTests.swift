//
//  BarrierCoordinator+GetBarriersTests.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 20/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

@testable import TealiumSwift
import XCTest

final class BarrierCoordinatorGetBarriersTests: XCTestCase {
    let registeredBarriers = [MockBarrier(id: "mock1"), MockBarrier(id: "mock2"), MockBarrier(id: "mock3")]
    @TealiumVariableSubject([])
    var onScopedBarriers: TealiumStatefulObservable<[ScopedBarrier]>
    lazy var barrierCoordinator = BarrierCoordinator(registeredBarriers: registeredBarriers, onScopedBarriers: onScopedBarriers)

    func test_getBarriers_with_allScope_returns_barriers_with_allScope() {
        _onScopedBarriers.value = [
            ScopedBarrier(barrierId: "mock1", scopes: [.all]),
            ScopedBarrier(barrierId: "mock2", scopes: [.all]),
            ScopedBarrier(barrierId: "mock3", scopes: [.all])
        ]
        let barriers = barrierCoordinator.getBarriers(scopedBarriers: onScopedBarriers.value, for: .all)
        XCTAssertEqual(barriers.map { $0.id }, registeredBarriers.map { $0.id })
    }

    func test_getBarriers_with_allScope_doesnt_return_barriers_without_allScope() {
        _onScopedBarriers.value = [
            ScopedBarrier(barrierId: "mock1", scopes: [.all]),
            ScopedBarrier(barrierId: "mock2", scopes: [.all]),
            ScopedBarrier(barrierId: "mock3", scopes: [.dispatcher("dispatcher1")])
        ]
        let barriers = barrierCoordinator.getBarriers(scopedBarriers: onScopedBarriers.value, for: .all)
        XCTAssertEqual(barriers.map { $0.id }, ["mock1", "mock2"])
    }

    func test_getBarriers_with_allScope_doesnt_return_barriers_that_are_not_registered() {
        _onScopedBarriers.value = [
            ScopedBarrier(barrierId: "mock_unregistered", scopes: [.all])
        ]
        let barriers = barrierCoordinator.getBarriers(scopedBarriers: onScopedBarriers.value, for: .all)
        XCTAssertEqual(barriers.count, 0)
    }

    func test_getBarriers_with_perDispatcherScope_returns_dispatcher_specific_barriers() {
        _onScopedBarriers.value = [
            ScopedBarrier(barrierId: "mock1", scopes: [.dispatcher("dispatcher1")]),
            ScopedBarrier(barrierId: "mock2", scopes: [.dispatcher("dispatcher2")]),
            ScopedBarrier(barrierId: "mock3", scopes: [.all])
        ]
        let barriers = barrierCoordinator.getBarriers(scopedBarriers: onScopedBarriers.value, for: .dispatcher("dispatcher1"))
        XCTAssertEqual(barriers.map { $0.id }, ["mock1"])
    }

    func test_getBarriers_with_perDispatcherScope_doesnt_return_barriers_that_are_not_registered() {
        _onScopedBarriers.value = [
            ScopedBarrier(barrierId: "mock_unregistered", scopes: [.dispatcher("dispatcher1")])
        ]
        let barriers = barrierCoordinator.getBarriers(scopedBarriers: onScopedBarriers.value, for: .dispatcher("dispatcher1"))
        XCTAssertEqual(barriers.count, 0)
    }

    func test_getAllBarriers_returns_allScoped_barriers_and_dispatcher_specific_barriers() {
        _onScopedBarriers.value = [
            ScopedBarrier(barrierId: "mock1", scopes: [.dispatcher("dispatcher1")]),
            ScopedBarrier(barrierId: "mock2", scopes: [.dispatcher("dispatcher2")]),
            ScopedBarrier(barrierId: "mock3", scopes: [.all])
        ]
        let barriers = barrierCoordinator.getAllBarriers(scopedBarriers: onScopedBarriers.value, for: "dispatcher1")
        XCTAssertTrue(barriers.contains { $0.id == "mock1" })
        XCTAssertFalse(barriers.contains { $0.id == "mock2" })
        XCTAssertTrue(barriers.contains { $0.id == "mock3" })
    }
}
