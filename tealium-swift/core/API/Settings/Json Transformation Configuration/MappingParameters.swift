//
//  MappingParameters.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 07/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/// The parameters necessary to perform a `JsonOperationType.map` operation.
public struct MappingParameters {
    enum Keys {
        static let key = "key"
        static let filter = "filter"
        static let mapTo = "map_to"
    }
    /// The variable in the data layer that needs to be mapped.
    let key: VariableAccessor
    /// The (optional) value that the variable needs to be equal to, if we want to apply the mapping.
    let filter: ValueContainer?
    /// If provided is the (optional) value that needs to be put in the output instead of the value at the key. If the output already contains something, it will insert all the items in a flattened array and put it in the array.
    let mapTo: ValueContainer?

    public init(key: VariableAccessor, filter: ValueContainer?, mapTo: ValueContainer?) {
        self.key = key
        self.filter = filter
        self.mapTo = mapTo
    }
}

extension MappingParameters: DataObjectConvertible {
    public func toDataObject() -> DataObject {
        DataObject(compacting: [
            Keys.key: key,
            Keys.filter: filter,
            Keys.mapTo: mapTo
        ])
    }
}

extension MappingParameters {
    struct Converter: DataItemConverter {
        typealias Convertible = MappingParameters
        func convert(dataItem: DataItem) -> Convertible? {
            guard let object = dataItem.getDataDictionary(),
                  let key = object.getConvertible(key: Keys.key,
                                                  converter: VariableAccessor.converter) else {
                return nil
            }
            return MappingParameters(key: key,
                                     filter: object.getConvertible(key: Keys.filter,
                                                                   converter: ValueContainer.converter),
                                     mapTo: object.getConvertible(key: Keys.mapTo,
                                                                  converter: ValueContainer.converter))
        }
    }

    static let converter: any DataItemConverter<Self> = Converter()
}
