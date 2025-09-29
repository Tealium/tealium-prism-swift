//
//  ConsentConfiguration.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 04/06/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/// An object containing the data used to understand and utilize consent purposes received by the `CMPAdapter`.
struct ConsentConfiguration {
    /// The purpose that needs to be accepted to allow `Tealium` to perform any action.
    let tealiumPurposeId: String
    /// The IDs of the Dispatchers that are allowed to refire `Dispatch`es, previously sent with implicit consent, after a user explicitly gives consent.
    let refireDispatchersIds: [String]
    /// A map of purpose ID, as provided by the `CMPAdapter`, to purposes which contain the list of `Dispatcher`s that need that purpose to be accepted to fire.
    let purposes: [String: ConsentPurpose]

    init(tealiumPurposeId: String, refireDispatchersIds: [String]?, purposes: [String: ConsentPurpose]) {
        self.tealiumPurposeId = tealiumPurposeId
        self.refireDispatchersIds = refireDispatchersIds ?? []
        self.purposes = purposes
    }
    enum Keys {
        static let tealiumPurposeId = "tealium_purpose_id"
        static let refireDispatchersIds = "refire_dispatcher_ids"
        static let purposes = "purposes"
    }

    func hasAtLeastOneRequiredPurposeForDispatcher(_ dispatcherId: String) -> Bool {
        purposes.values.contains {
            $0.dispatcherIds.contains(dispatcherId)
        }
    }
}

extension ConsentConfiguration {
    struct Converter: DataItemConverter {
        typealias Convertible = ConsentConfiguration
        func convert(dataItem: DataItem) -> Convertible? {
            guard let dictionary = dataItem.getDataDictionary(),
                  let tealiumPurposeId = dictionary.get(key: Keys.tealiumPurposeId, as: String.self),
                  let purposes = dictionary.getDataDictionary(key: Keys.purposes) else {
                return nil
            }
            return ConsentConfiguration(
                tealiumPurposeId: tealiumPurposeId,
                refireDispatchersIds: dictionary.getArray(key: Keys.refireDispatchersIds, of: String.self)?.compactMap { $0 },
                purposes: purposes.compactMapValues { $0.getConvertible(converter: ConsentPurpose.converter) }
            )
        }
    }
    static let converter: any DataItemConverter<Self> = Converter()
}
