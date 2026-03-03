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

/// Defines how a persisted value should behave when a value already exists at the destination.
/// Use this to control whether a new value can overwrite an existing one.
public enum UpdateBehavior: String, Equatable {
    /// Subsequent persist operations are allowed to overwrite any existing value
    /// at the destination with the latest value.
    case allowUpdate = "allow_update"
    /// The first successfully persisted value is kept; any later attempts to
    /// persist a new value to the same destination are ignored.
    case keepFirstValue = "keep_first_value"
}

struct PersistDataValueConfiguration: DataObjectConvertible {
    enum Keys {
        static let input = "input"
        static let duration = "duration"
        static let updateBehavior = "update_behavior"
    }

    let destination: ReferenceContainer
    let input: ValueSource
    let expiryPolicy: ExpiryPolicy
    let updateBehavior: UpdateBehavior

    init(destination: ReferenceContainer, input: ValueSource, expiryPolicy: ExpiryPolicy, updateBehavior: UpdateBehavior) {
        self.destination = destination
        self.input = input
        self.expiryPolicy = expiryPolicy
        self.updateBehavior = updateBehavior
    }

    init?(dataObject: DataObject) {
        guard let destination = dataObject.getConvertible(key: OperationKeys.destination, converter: ReferenceContainer.converter),
              let parameters = dataObject.getDataDictionary(key: OperationKeys.parameters),
              let updateBehaviorString = parameters.get(key: Keys.updateBehavior, as: String.self),
              let updateBehavior = UpdateBehavior(rawValue: updateBehaviorString),
              let expiryPolicy = parameters.getConvertible(key: Keys.duration, converter: ExpiryPolicy.converter) else {
            return nil
        }

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
            updateBehavior: updateBehavior
        )
    }

    func toDataObject() -> DataObject {
        var dataObject: DataObject = [:]
        dataObject.set(converting: destination, key: OperationKeys.destination)
        var parameters: DataObject = [
            Keys.updateBehavior: updateBehavior.rawValue
        ]
        parameters.set(converting: expiryPolicy, key: Keys.duration)
        switch input {
        case .reference(let reference):
            parameters.set(converting: reference, key: Keys.input)
        case .constant(let value):
            parameters.set(converting: value, key: Keys.input)
        }
        dataObject.set(converting: parameters, key: OperationKeys.parameters)
        return dataObject
    }
}
