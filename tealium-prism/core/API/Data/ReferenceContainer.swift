//
//  ReferenceContainer.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 30/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A container for a reference to a variable in the data layer.
 */
public struct ReferenceContainer: Equatable {
    enum Keys {
        static let key = "key"
        static let path = "path"
    }
    enum ReferenceType: Equatable {
        /// The key to a variable in the root of the data layer.
        case key(_ key: String)
        /// The path to a variable in the data layer, potentially nested in JSON objects or JSON arrays.
        case path(_ path: JSONObjectPath)
    }
    let ref: ReferenceType

    /// Creates a ReferenceContainer to a variable in the root of a JSON object.
    public static func key(_ key: String) -> Self {
        ReferenceContainer(ref: .key(key))
    }

    /// Creates a ReferenceContainer to a variable nested in a JSON object.
    public static func path(_ path: JSONObjectPath) -> Self {
        ReferenceContainer(ref: .path(path))
    }

    init(ref: ReferenceType) {
        self.ref = ref
    }

    /// The path to a potentially nested variable in a JSON object.
    public var path: JSONObjectPath {
        switch ref {
        case let .key(key):
            JSONPath[key]
        case let .path(path):
            path
        }
    }
}

extension ReferenceContainer: DataObjectConvertible {
    public func toDataObject() -> DataObject {
        switch ref {
        case let .key(key):
            [
                Keys.key: key
            ]
        case let .path(path):
            [
                Keys.path: path.render()
            ]
        }
    }
}
