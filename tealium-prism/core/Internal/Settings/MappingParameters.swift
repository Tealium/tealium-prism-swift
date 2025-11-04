//
//  MappingParameters.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/// The parameters necessary to perform a `JsonOperationType.map` operation.
struct MappingParameters {
    enum Keys {
        static let reference = "reference"
        static let filter = "filter"
        static let mapTo = "map_to"
    }
    /// The variable in the data layer that needs to be mapped.
    let reference: ReferenceContainer?
    /// The (optional) value that the variable needs to be equal to, if we want to apply the mapping.
    let filter: ValueContainer?
    /// If provided, it is the (optional) value that needs to be put in the destination instead of the value at the key.
    /// If the destination already contains something, it will insert all the items in a flattened array and put it in the array.
    let mapTo: ValueContainer?

    init(reference: ReferenceContainer?, filter: ValueContainer?, mapTo: ValueContainer?) {
        self.reference = reference
        self.filter = filter
        self.mapTo = mapTo
    }

    init(reference: String, filter: ValueContainer?, mapTo: ValueContainer?) {
        self.init(reference: ReferenceContainer(key: reference), filter: filter, mapTo: mapTo)
    }

    init(reference: JSONObjectPath, filter: ValueContainer?, mapTo: ValueContainer?) {
        self.init(reference: ReferenceContainer(path: reference), filter: filter, mapTo: mapTo)
    }
}

extension MappingParameters: DataObjectConvertible {
    func toDataObject() -> DataObject {
        DataObject(compacting: [
            Keys.reference: reference,
            Keys.filter: filter,
            Keys.mapTo: mapTo
        ])
    }
}
