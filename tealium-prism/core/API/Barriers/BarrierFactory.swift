//
//  BarrierFactory.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation
/**
 * The [BarrierFactory] is responsible for creating new [ConfigurableBarrier] instances.
 */
public protocol BarrierFactory<BarrierType> {
    /// The specific `ConfigurableBarrier` that this factory can create.
    associatedtype BarrierType: ConfigurableBarrier

    /**
     * An optional set of default `BarrierScope` to use in the event that these are not configured
     * in any settings sources.
     *
     * In the case that no settings are found, and no default is available, then `BarrierScope.all`
     * will be used. Therefore applying badly configured `Barrier` implementations to all `Dispatcher`s
     */
    func defaultScopes() -> [BarrierScope]

    /**
     * Creates a `ConfigurableBarrier` instance using the given `context` and `configuration`.
     */
    func create(context: TealiumContext, configuration: DataObject) -> BarrierType

    /**
     * Returns some optional settings for this barrier that override any other Local or Remote settings fields.
     *
     * Only the values at the specific keys returned in this Dictionary will be enforced and remain constant during the life of this `Barrier`.
     * Other values at other keys that are not present in this Dictionary can be set by Local or Remote settings
     * and be updated by future Remote settings refreshes during the life of this `Barrier`.
     *
     * - Returns: A `DataObject` representing the `BarrierSettings`, containing some of the settings used by the `Barrier`
     * that will be enforced and remain constant during the life of this `Barrier`.
     */
    func getEnforcedSettings() -> DataObject
}

extension BarrierFactory {
    /**
     * The unique identifier of this barrier.
     * This String will be used to match up barriers scoped in the configuration JSON.
     */
    var id: String { BarrierType.id }

    public func getEnforcedSettings() -> DataObject {
        [:]
    }
}
