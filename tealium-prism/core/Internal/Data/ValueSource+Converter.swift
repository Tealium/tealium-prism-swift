//
//  ValueSource+Converter.swift
//  tealium-prism
//
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

extension ValueSource {
    struct Converter: DataItemConverter {
        typealias Convertible = ValueSource
        func convert(dataItem: DataItem) -> Convertible? {
            if let reference = dataItem.getConvertible(converter: ReferenceContainer.converter) {
                return .reference(reference)
            } else if let value = dataItem.getConvertible(converter: ValueContainer.converter) {
                return .constant(value)
            }
            return nil
        }
    }

    public static let converter: any DataItemConverter<ValueSource> = Converter()
}
