//
//  ConsentPurpose.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 26/05/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/// An object containing the mapping between a `purposeId` (as provided by the `CMPAdapter`)
/// and the `dispatcherIds` for the `Dispatcher`s that need that purpose to be accepted in order to fire.
struct ConsentPurpose {
    /// The purpose as provided by the `CMPAdapter`.
    let purposeId: String
    /// The IDs of the dispatchers that need the `purposeId` to be accepted in order to fire.
    let dispatcherIds: [String]

    enum Keys {
        static let purposeId = "purpose_id"
        static let dispatcherIds = "dispatcher_ids"
    }
}

extension ConsentPurpose: DataObjectConvertible {
    func toDataObject() -> DataObject {
        [
            Keys.purposeId: purposeId,
            Keys.dispatcherIds: dispatcherIds
        ]
    }
}

extension ConsentPurpose {
    struct Converter: DataItemConverter {
        typealias Convertible = ConsentPurpose
        func convert(dataItem: DataItem) -> Convertible? {
            guard let dictionary = dataItem.getDataDictionary(),
                  let purposeId = dictionary.get(key: Keys.purposeId, as: String.self),
                  let dispatcherIds = dictionary.getArray(key: Keys.dispatcherIds, of: String.self) else {
                return nil
            }
            return ConsentPurpose(purposeId: purposeId, dispatcherIds: dispatcherIds.compactMap { $0 })
        }
    }
    static let converter: any DataItemConverter<Self> = Converter()
}
