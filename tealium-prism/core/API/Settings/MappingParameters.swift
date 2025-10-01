//
//  MappingParameters.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/25.
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
    public let key: VariableAccessor?
    /// The (optional) value that the variable needs to be equal to, if we want to apply the mapping.
    public let filter: ValueContainer?
    /// If provided, it is the (optional) value that needs to be put in the destination instead of the value at the key. If the destination already contains something, it will insert all the items in a flattened array and put it in the array.
    public let mapTo: ValueContainer?
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
