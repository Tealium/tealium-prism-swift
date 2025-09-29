//
//  DataObjectConvertible.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 07/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/**
 * Use this protocol to convert custom types to their `DataObject` representation.
 */
public protocol DataObjectConvertible: DataInputConvertible {
    /// Converts an object to its `DataObject` representation.
    func toDataObject() -> DataObject
}

public extension DataInputConvertible where Self: DataObjectConvertible {
    func toDataInput() -> any DataInput {
        toDataObject().toDataInput()
    }
}

extension [String: DataItem]: DataObjectConvertible {
    public func toDataObject() -> DataObject {
        DataObject(dictionary: self)
    }
}
