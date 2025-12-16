//
//  LowerCaseInput.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 17/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

#if extensions
    import TealiumPrismCore
#endif

struct LowerCaseInput: DataInputConvertible {
    let input: ReferenceContainer

    func toDataInput() -> any DataInput {
        input.toDataInput()
    }

    struct Converter: DataItemConverter {
        typealias Convertible = LowerCaseInput
        func convert(dataItem: DataItem) -> Convertible? {
            if let reference = dataItem.getConvertible(
                converter: ReferenceContainer.converter
            ) {
                return LowerCaseInput(input: reference)
            }
            return nil
        }
    }
    static let converter = Converter()
}
