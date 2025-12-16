//
//  SetDataValuesInput.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

struct SetDataValuesInput: DataInputConvertible {
    let input: ValueSource
    func toDataInput() -> any DataInput {
        input.toDataInput()
    }

    struct Converter: DataItemConverter {
        typealias Convertible = SetDataValuesInput
        func convert(dataItem: DataItem) -> Convertible? {
            if let reference = dataItem.getConvertible(converter: ReferenceContainer.converter) {
                return SetDataValuesInput(input: .reference(reference))
            } else if let value = dataItem.getConvertible(converter: ValueContainer.converter) {
                return SetDataValuesInput(input: .constant(value))
            }
            return nil
        }
    }
    static let converter = Converter()
}
