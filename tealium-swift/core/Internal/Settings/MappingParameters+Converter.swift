//
//  MappingParameters+Converter.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 07/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

extension MappingParameters {
    struct Converter: DataItemConverter {
        typealias Convertible = MappingParameters
        func convert(dataItem: DataItem) -> Convertible? {
            guard let object = dataItem.getDataDictionary() else {
                return nil
            }
            return MappingParameters(key: object.getConvertible(key: Keys.key,
                                                                converter: VariableAccessor.converter),
                                     filter: object.getConvertible(key: Keys.filter,
                                                                   converter: ValueContainer.converter),
                                     mapTo: object.getConvertible(key: Keys.mapTo,
                                                                  converter: ValueContainer.converter))
        }
    }

    static let converter: any DataItemConverter<Self> = Converter()
}
