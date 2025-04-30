//
//  BarrierSettings.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// A model that defines which scopes a specific barrier, identified by its `barrierId`, should be applied to.
struct BarrierSettings {
    /// The ID of the barrier, used to lookup and connect a `ConfigurableBarrier` to its settings.
    let barrierId: String
    /// The scopes onto which the `Barrier` should be applied.
    let scopes: [BarrierScope]
    /// A generic configuration object that can be used by the `ConfigurableBarrier` to affect it's behavior.
    let configuration: DataObject

    func matchesScope(_ scope: BarrierScope) -> Bool {
        self.scopes.contains { $0 == scope }
    }

    init(barrierId: String, scopes: [BarrierScope], configuration: DataObject = [:]) {
        self.barrierId = barrierId
        self.scopes = scopes
        self.configuration = configuration
    }

    enum Keys {
        static let barrierId = "barrier_id"
        static let scopes = "scopes"
        static let configuration = "configuration"
    }
}

extension BarrierSettings: DataObjectConvertible {
    func toDataObject() -> DataObject {
        [
            Keys.barrierId: barrierId,
            Keys.scopes: scopes,
            Keys.configuration: configuration
        ]
    }
}
extension BarrierSettings {
    struct Converter: DataItemConverter {
        typealias Convertible = BarrierSettings
        func convert(dataItem: DataItem) -> Convertible? {
            guard let dictionary = dataItem.getDataDictionary(),
                  let barrierId = dictionary.get(key: Keys.barrierId, as: String.self),
                  let scopes = dictionary.getArray(key: Keys.scopes, of: String.self)?
                .compactMap({ $0 }) else {
                return nil
            }
            let configuration = dictionary.getDataDictionary(key: Keys.configuration)?.toDataObject() ?? [:]
            return BarrierSettings(barrierId: barrierId,
                                   scopes: scopes.map { BarrierScope(rawValue: $0) },
                                   configuration: configuration)
        }
    }
    static let converter: any DataItemConverter<Self> = Converter()
}
