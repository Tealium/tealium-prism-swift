//
//  TransformationOperation.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 07/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

private enum OperationKeys {
    static let destination = "destination"
    static let parameters = "parameters"
}

/// An object representing an operation to be performed during a transformation.
public struct TransformationOperation<Parameters: DataInputConvertible> {
    /// The variable onto which this transformation will put the result to.
    let destination: ReferenceContainer
    /// The parameters necessary for this operation to be performed.
    let parameters: Parameters

    /**
     * Creates a transformation operation with the specified destination and parameters.
     *
     * - Parameters:
     *   - destination: The reference container specifying where to store the result.
     *   - parameters: The parameters needed for the operation.
     */
    init(destination: ReferenceContainer, parameters: Parameters) {
        self.destination = destination
        self.parameters = parameters
    }

    /**
     * Creates a transformation operation with a string destination key.
     *
     * - Parameters:
     *   - destination: The key name where the result will be stored.
     *   - parameters: The parameters needed for the operation.
     */
    public init(destination: String, parameters: Parameters) {
        self.init(destination: ReferenceContainer(key: destination), parameters: parameters)
    }

    /**
     * Creates a transformation operation with a JSON object path destination.
     *
     * - Parameters:
     *   - destination: The JSON path where the result will be stored.
     *   - parameters: The parameters needed for the operation.
     */
    public init(destination: JSONObjectPath, parameters: Parameters) {
        self.init(destination: ReferenceContainer(path: destination), parameters: parameters)
    }
}

extension TransformationOperation: DataObjectConvertible {
    public func toDataObject() -> DataObject {
        [
            OperationKeys.destination: destination,
            OperationKeys.parameters: parameters
        ]
    }
}

extension TransformationOperation {
    struct Converter: DataItemConverter {
        typealias Convertible = TransformationOperation<Parameters>
        let parametersConverter: any DataItemConverter<Parameters>
        func convert(dataItem: DataItem) -> Convertible? {
            guard let object = dataItem.getDataDictionary(),
                  let destination = object.getConvertible(key: OperationKeys.destination,
                                                          converter: ReferenceContainer.converter),
                  let parameters = object.getConvertible(key: OperationKeys.parameters,
                                                         converter: parametersConverter) else {
                return nil
            }
            return TransformationOperation<Parameters>(destination: destination,
                                                       parameters: parameters)
        }
    }

    static func converter(parametersConverter converter: any DataItemConverter<Parameters>) -> any DataItemConverter<Self> {
        Converter(parametersConverter: converter)
    }
}
