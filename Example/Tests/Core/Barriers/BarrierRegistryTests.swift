//
//  BarrierRegistryTests.swift
//  tealium-prism_Tests
//
//  Created by Den Guzov on 12/01/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

final class BarrierRegistryTests: XCTestCase {
    let registry = BarrierRegistry.shared

    // When creating new barriers, make sure to add them here
    let installedBarriers = [
        "ConnectivityBarrier",
        "BatchingBarrier"
    ]

    override func tearDown() {
        registry.clearAdditionalBarriers()
        super.tearDown()
    }

    func test_defaultBarriers_contain_all_installed_barriers() {
        let defaultBarriers = registry.defaultBarriers
        let defaultBarriersIds: [String] = defaultBarriers.map(\.id)
        XCTAssertTrue(Set(installedBarriers).isSubset(of: defaultBarriersIds))
    }

    func test_default_scopes_of_installed_barriers() {
        let defaultBarriers = registry.defaultBarriers
        let connectivityFactory = defaultBarriers.first { $0.id == installedBarriers[0] }
        let batchingFactory = defaultBarriers.first { $0.id == installedBarriers[1] }
        XCTAssertEqual(connectivityFactory?.defaultScopes(), [.dispatcher(id: Modules.Types.collect)])
        XCTAssertEqual(batchingFactory?.defaultScopes(), [])
    }

    func test_addDefaultBarrier_adds_barrier_to_additional_barriers() {
        let mockBarrier = MockBarrierFactory<MockConfigurableBarrier>(defaultScopes: [.all])
        XCTAssertEqual(registry.additionalBarriers.count, 0)
        registry.addDefaultBarrier(mockBarrier)
        XCTAssertEqual(registry.additionalBarriers.count, 1)
        XCTAssertTrue(registry.additionalBarriers.contains { $0.id == mockBarrier.id })
    }

    func test_addDefaultBarrier_increases_defaultBarriers_count() {
        let mockBarrier = MockBarrierFactory<MockConfigurableBarrier>(defaultScopes: [.all])
        registry.addDefaultBarrier(mockBarrier)
        XCTAssertEqual(registry.defaultBarriers.count, installedBarriers.count + 1)
        XCTAssertTrue(registry.defaultBarriers.contains { $0.id == mockBarrier.id })
    }

    func test_defaultBarriers_includes_both_core_and_additional_barriers() {
        let mockBarrier = MockBarrierFactory<MockConfigurableBarrier>(defaultScopes: [.all])
        registry.addDefaultBarrier(mockBarrier)
        let defaultBarriers = registry.defaultBarriers
        let coreBarrierIds = Set(installedBarriers)
        let additionalBarrierIds = Set(registry.additionalBarriers.map { $0.id })
        let defaultBarrierIds = Set(defaultBarriers.map { $0.id })
        XCTAssertTrue(coreBarrierIds.isSubset(of: defaultBarrierIds))
        XCTAssertTrue(additionalBarrierIds.isSubset(of: defaultBarrierIds))
        XCTAssertEqual(defaultBarrierIds.count, coreBarrierIds.count + additionalBarrierIds.count)
    }
}
