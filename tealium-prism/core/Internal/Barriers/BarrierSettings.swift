//
//  BarrierSettings.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 24/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// A model that defines which scope a specific barrier, identified by its `barrierId`, should be applied to.
struct BarrierSettings {
    /// The ID of the barrier, used to lookup and connect a `ConfigurableBarrier` to its settings.
    let barrierId: String
    /// The scope onto which the `Barrier` should be applied, or `nil` to use the factory default.
    let scope: BarrierScope?
    /// A generic configuration object that can be used by the `ConfigurableBarrier` to affect its behavior.
    let configuration: DataObject

    init(barrierId: String, scope: BarrierScope? = nil, configuration: DataObject = [:]) {
        self.barrierId = barrierId
        self.scope = scope
        self.configuration = configuration
    }

    enum Keys {
        static let barrierId = "barrier_id"
        static let scope = "scope"
        static let configuration = "configuration"
    }
}

extension BarrierSettings: DataObjectConvertible {
    func toDataObject() -> DataObject {
        var result: DataObject = [
            Keys.barrierId: barrierId,
            Keys.configuration: configuration
        ]
        if let scope {
            result.set(converting: scope, key: Keys.scope)
        }
        return result
    }
}

extension BarrierSettings {
    struct Converter: DataItemConverter {
        typealias Convertible = BarrierSettings
        func convert(dataItem: DataItem) -> Convertible? {
            guard let dictionary = dataItem.getDataDictionary(),
                  let barrierId: String = dictionary.get(key: Keys.barrierId)
            else {
                return nil
            }
            // if scope is nil, default scope fallback will be used in BarrierManager.scopedConfigBarriers()
            let scope = dictionary[Keys.scope].flatMap(BarrierScope.converter.convert)
            let configuration = dictionary.getDataDictionary(key: Keys.configuration)?.toDataObject() ?? [:]
            return BarrierSettings(barrierId: barrierId, scope: scope, configuration: configuration)
        }
    }
    static let converter: any DataItemConverter<BarrierSettings> = Converter()
}
