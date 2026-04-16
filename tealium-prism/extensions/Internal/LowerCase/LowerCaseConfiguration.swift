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
        static let inputs = "inputs"
    }

    enum Defaults {
        static let allVariables: Bool = true
    }

    let allVariables: Bool
    let inputs: [ReferenceContainer]

    init(
        allVariables: Bool = Defaults.allVariables,
        inputs: [ReferenceContainer] = []
    ) {
        self.allVariables = allVariables
        self.inputs = inputs
    }

    init?(dataObject: DataObject) {
        let allVariables = dataObject.get(key: Keys.allVariables, as: Bool.self) ?? Defaults.allVariables

        let inputs: [ReferenceContainer]
        if let inputsArray = dataObject.getDataArray(key: Keys.inputs) {
            inputs = inputsArray.compactMap {
                $0.getConvertible(converter: ReferenceContainer.converter)
            }
        } else {
            inputs = []
        }

        guard allVariables || !inputs.isEmpty else {
            return nil
        }

        self.init(allVariables: allVariables, inputs: inputs)
    }

    func toDataObject() -> DataObject {
        [
            Keys.allVariables: allVariables,
            Keys.inputs: inputs.map { $0.toDataObject() },
        ]
    }
}
