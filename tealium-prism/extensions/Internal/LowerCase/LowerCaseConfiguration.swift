//
//  LowerCaseConfiguration.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 17/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

#if extensions
    import TealiumPrismCore
#endif

struct LowerCaseConfiguration: DataObjectConvertible {
    enum Keys {
        static let allVariables = "all_variables"
        static let operations = "operations"
    }

    let allVariables: Bool
    let operations: [TransformationOperation<LowerCaseInput>]

    init(
        allVariables: Bool,
        operations: [TransformationOperation<LowerCaseInput>]
    ) {
        self.allVariables = allVariables
        self.operations = operations
    }

    init(dataObject: DataObject) {
        let allVariables = dataObject.get(key: Keys.allVariables, as: Bool.self) ?? false

        let operations: [TransformationOperation<LowerCaseInput>]
        if let opsArray = dataObject.getDataArray(key: Keys.operations) {
            let converter = TransformationOperation.converter(
                parametersConverter: LowerCaseInput.converter
            )
            operations = opsArray.compactMap {
                $0.getConvertible(converter: converter)
            }
        } else {
            operations = []
        }

        self.init(allVariables: allVariables, operations: operations)
    }

    func toDataObject() -> DataObject {
        [
            Keys.allVariables: allVariables,
            Keys.operations: operations.map { $0.toDataObject() },
        ]
    }
}
