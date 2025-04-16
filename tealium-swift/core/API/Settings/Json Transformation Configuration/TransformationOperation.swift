//
//  TransformationOperation.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 07/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

private enum OperationKeys {
    static let output = "output"
    static let parameters = "parameters"
}

/// An object representing an operation to be performed during a transformation.
public struct TransformationOperation<Parameters: DataInputConvertible> {
    /// The variable onto which this transformation will put the result to.
    let output: VariableAccessor
    /// The parameters necessary for this operation to be performed.
    let parameters: Parameters

    public init(output: VariableAccessor, parameters: Parameters) {
        self.output = output
        self.parameters = parameters
    }
}

extension TransformationOperation: DataObjectConvertible {
    public func toDataObject() -> DataObject {
        [
            OperationKeys.output: output,
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
                  let output = object.getConvertible(key: OperationKeys.output,
                                                     converter: VariableAccessor.converter),
                  let parameters = object.getConvertible(key: OperationKeys.parameters,
                                                         converter: parametersConverter) else {
                return nil
            }
            return TransformationOperation<Parameters>(output: output,
                                                       parameters: parameters)
        }
    }

    static func converter(parametersConverter converter: any DataItemConverter<Parameters>) -> any DataItemConverter<Self> {
        Converter(parametersConverter: converter)
    }
}
