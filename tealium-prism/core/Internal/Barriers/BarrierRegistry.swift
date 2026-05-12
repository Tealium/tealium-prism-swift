//
//  BarrierRegistry.swift
//  tealium-prism
//
//  Created by Den Guzov on 08/01/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * Internal singleton available to hold all default barriers and add any additional ones that may be registered at init time.
 */
class BarrierRegistry {
    /// The barriers created within the Core library.
    private var _defaultBarriers: [any BarrierFactory] = [
        ConnectivityBarrier.Factory(defaultScope: .dispatchers([Modules.Types.collect])),
        BatchingBarrier.Factory(defaultScope: .dispatchers([]))
    ]

    /// The optional barriers that need to be installed alongside the Core library.
    private(set) var additionalBarriers: [any BarrierFactory] = []

    /// A list of default barriers that will be added to the provided barriers.
    var defaultBarriers: [any BarrierFactory] {
        _defaultBarriers + additionalBarriers
    }

    static let shared = BarrierRegistry()
    private init() { }

    func addDefaultBarrier<SpecificFactory: BarrierFactory>(_ barrier: SpecificFactory) {
        additionalBarriers.append(barrier)
    }

    func clearAdditionalBarriers() {
        additionalBarriers = []
    }
}
