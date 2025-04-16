//
//  JsonTransformationConfiguration.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 07/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/// The operations supported by the JsonTransformer
public enum JsonOperationType: String {
    /// An operation used to map some data layer keys to the ones used within a `Dispatcher`.
    case map
    // TODO: add other operation types
}

private enum ConfigurationKeys {
    static let operationsType = "operations_type"
    static let operations = "operations"
}
/**
 * The Configuration object that contains a specific operations type and array of operations.
 */
public struct JsonTransformationConfiguration<Parameters: DataInputConvertible> {
    /// The type of operation defined in this Transformation Configuration
    let operationsType: JsonOperationType
    /// The list of operations to be performed with the `Parameters` relative to the specified `operationsType`.
    let operations: [TransformationOperation<Parameters>]

    public init(operationsType: JsonOperationType, operations: [TransformationOperation<Parameters>]) {
        self.operationsType = operationsType
        self.operations = operations
    }
}

extension JsonTransformationConfiguration: DataObjectConvertible {
    public func toDataObject() -> DataObject {
        [
            ConfigurationKeys.operationsType: operationsType.rawValue,
            ConfigurationKeys.operations: operations
        ]
    }
}
