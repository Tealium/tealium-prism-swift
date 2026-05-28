//
//  PersistDataValueConfiguration.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 17/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation
#if extensions
import TealiumPrismCore
#endif

struct PersistDataValueConfiguration: DataObjectConvertible {
    enum Keys {
        static let input = "input"
        static let destination = "destination"
        static let duration = "duration"
        static let updatePolicy = "update_policy"
    }

    enum Defaults {
        static let expiryPolicy: ExpiryPolicy = .session
        static let updatePolicy: UpdatePolicy = .allowUpdate
    }

    let input: ValueSource
    let destination: ReferenceContainer
    let expiryPolicy: ExpiryPolicy
    let updatePolicy: UpdatePolicy

    init(
        destination: ReferenceContainer,
        input: ValueSource,
        expiryPolicy: ExpiryPolicy? = nil,
        updatePolicy: UpdatePolicy? = nil
    ) {
        self.input = input
        self.destination = destination
        self.expiryPolicy = expiryPolicy ?? Defaults.expiryPolicy
        self.updatePolicy = updatePolicy ?? Defaults.updatePolicy
    }

    init?(dataObject: DataObject) {
        let dict = DataItem(converting: dataObject).getDataDictionary()
        guard let input = dict?.getConvertible(key: Keys.input, converter: ValueSource.converter),
              let destination = dict?.getConvertible(key: Keys.destination, converter: ReferenceContainer.converter) else {
            return nil
        }
        self.init(
            destination: destination,
            input: input,
            expiryPolicy: dict?.getConvertible(key: Keys.duration, converter: ExpiryPolicy.converter),
            updatePolicy: dict?.get(key: Keys.updatePolicy, as: String.self).flatMap({ UpdatePolicy(rawValue: $0) })
        )
    }

    func toDataObject() -> DataObject {
        [
            Keys.input: input,
            Keys.destination: destination,
            Keys.duration: expiryPolicy,
            Keys.updatePolicy: updatePolicy.rawValue
        ]
    }
}
