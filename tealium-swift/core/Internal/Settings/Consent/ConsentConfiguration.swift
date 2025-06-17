//
//  ConsentConfiguration.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 04/06/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/// An object containing the data used to understand and utilize consent purposes received by the `CMPAdapter`.
public struct ConsentConfiguration {
    /// The purpose that needs to be accepted to allow `Tealium` to perform any action.
    let tealiumPurposeId: String
    /// The IDs of the Dispatchers that are allowed to refire `Dispatch`es, previously sent with implicit consent, after a user explicitly gives consent.
    let refireDispatchersIds: [String]
    /// A list of purposes, as provided by the `CMPAdapter`, and the list of `Dispatcher`s that need that purpose to be accepted to fire.
    let purposes: [ConsentPurpose]

    public init(tealiumPurposeId: String, refireDispatchersIds: [String]?, purposes: [ConsentPurpose]) {
        self.tealiumPurposeId = tealiumPurposeId
        self.refireDispatchersIds = refireDispatchersIds ?? []
        self.purposes = purposes
    }
    enum Keys {
        static let tealiumPurposeId = "tealium_purpose_id"
        static let refireDispatchersIds = "refire_dispatcher_ids"
        static let purposes = "purposes"
    }
}

extension ConsentConfiguration {
    struct Converter: DataItemConverter {
        typealias Convertible = ConsentConfiguration
        func convert(dataItem: DataItem) -> Convertible? {
            guard let dictionary = dataItem.getDataDictionary(),
                  let tealiumPurposeId = dictionary.get(key: Keys.tealiumPurposeId, as: String.self),
                  let purposes = dictionary.getDataArray(key: Keys.purposes) else {
                return nil
            }
            return ConsentConfiguration(
                tealiumPurposeId: tealiumPurposeId,
                refireDispatchersIds: dictionary.getArray(key: Keys.refireDispatchersIds, of: String.self)?.compactMap { $0 },
                purposes: purposes.compactMap { $0.getConvertible(converter: ConsentPurpose.converter) }
            )
        }
    }
    static let converter: any DataItemConverter<Self> = Converter()
}
