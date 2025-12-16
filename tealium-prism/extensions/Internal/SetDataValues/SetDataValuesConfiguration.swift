//
//  SetDataValuesConfiguration.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

struct SetDataValuesConfiguration: DataObjectConvertible {
    enum Keys {
        static let operations = "operations"
    }
    let operations: [TransformationOperation<SetDataValuesParameters>]

    init(operations: [TransformationOperation<SetDataValuesParameters>]) {
        self.operations = operations
    }

    init?(dataObject: DataObject) {
        guard let operations = dataObject.getDataArray(key: Keys.operations) else {
            return nil
        }
        let converter = TransformationOperation.converter(parametersConverter: SetDataValuesParameters.converter)
        self.init(operations: operations.compactMap { item in
            item.getConvertible(converter: converter)
        })
    }

    func toDataObject() -> DataObject {
        [Keys.operations: operations.map { $0.toDataObject() }]
    }
}
