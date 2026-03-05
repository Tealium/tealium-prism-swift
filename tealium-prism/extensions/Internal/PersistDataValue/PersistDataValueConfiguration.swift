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
        static let duration = "duration"
        static let updatePolicy = "update_policy"
    }

    enum Defaults {
        static let expiryPolicy: ExpiryPolicy = .session
        static let updatePolicy: UpdatePolicy = .allowUpdate
    }

    let destination: ReferenceContainer
    let input: ValueSource
    let expiryPolicy: ExpiryPolicy
    let updatePolicy: UpdatePolicy

    init(destination: ReferenceContainer, input: ValueSource, expiryPolicy: ExpiryPolicy? = nil, updatePolicy: UpdatePolicy? = nil) {
        self.destination = destination
        self.input = input
        self.expiryPolicy = expiryPolicy ?? Defaults.expiryPolicy
        self.updatePolicy = updatePolicy ?? Defaults.updatePolicy
    }

    init?(dataObject: DataObject) {
        guard let destination = dataObject.getConvertible(key: OperationKeys.destination, converter: ReferenceContainer.converter),
              let parameters = dataObject.getDataDictionary(key: OperationKeys.parameters) else {
            return nil
        }

        let updatePolicy = UpdatePolicy(rawValue: parameters.get(key: Keys.updatePolicy, as: String.self) ?? "") ?? Defaults.updatePolicy
        let expiryPolicy = parameters.getConvertible(key: Keys.duration, converter: ExpiryPolicy.converter) ?? Defaults.expiryPolicy

        let input: ValueSource
        if let reference = parameters.getConvertible(key: Keys.input, converter: ReferenceContainer.converter) {
            input = .reference(reference)
        } else if let value = parameters.getConvertible(key: Keys.input, converter: ValueContainer.converter) {
            input = .constant(value)
        } else {
            return nil
        }

        self.init(
            destination: destination,
            input: input,
            expiryPolicy: expiryPolicy,
            updatePolicy: updatePolicy
        )
    }

    func toDataObject() -> DataObject {
        [
            OperationKeys.destination: destination,
            OperationKeys.parameters: [
                Keys.updatePolicy: updatePolicy.rawValue,
                Keys.duration: expiryPolicy,
                Keys.input: input
            ] as DataObject
        ]
    }
}
