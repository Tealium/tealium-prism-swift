//
//  SetDataValuesConfiguration.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation
#if extensions
import TealiumPrismCore
#endif

struct SetDataValuesOperation: DataObjectConvertible {
    enum Keys {
        static let input = "input"
        static let destination = "destination"
    }
    let input: ValueSource
    let destination: ReferenceContainer

    init(input: ValueSource, destination: ReferenceContainer) {
        self.input = input
        self.destination = destination
    }

    init?(dataObject: DataObject) {
        let dict = DataItem(converting: dataObject).getDataDictionary()
        guard let input = dict?.getConvertible(key: Keys.input, converter: ValueSource.converter),
              let destination = dict?.getConvertible(key: Keys.destination, converter: ReferenceContainer.converter) else {
            return nil
        }
        self.init(input: input, destination: destination)
    }

    func toDataObject() -> DataObject {
        [
            Keys.input: input,
            Keys.destination: destination
        ]
    }
}

struct SetDataValuesConfiguration: DataObjectConvertible {
    enum Keys {
        static let operations = "operations"
    }
    let operations: [SetDataValuesOperation]

    init(operations: [SetDataValuesOperation]) {
        self.operations = operations
    }

    init?(dataObject: DataObject) {
        guard let operations = dataObject.getDataArray(key: Keys.operations) else {
            return nil
        }
        self.init(operations: operations.compactMap { item in
            item.getDataDictionary().flatMap({
                SetDataValuesOperation(dataObject: $0.toDataObject())
            })
        })
    }

    func toDataObject() -> DataObject {
        [Keys.operations: operations.map { $0.toDataObject() }]
    }
}
