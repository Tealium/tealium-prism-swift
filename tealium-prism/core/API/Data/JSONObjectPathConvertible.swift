//
//  JSONObjectPathConvertible.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 23/03/2026.
//  Copyright © 2026 Tealium. All rights reserved.
//

import Foundation

/// Protocol for types that can be expressed as a `JSONObjectPath`.
public protocol JSONObjectPathConvertible {
    /// The `JSONObjectPath` representation of this value.
    var path: JSONObjectPath { get }
}

/// A `JSONObjectPath` is trivially convertible to itself.
///
/// This allows passing a path built at runtime, like a child of a known path (`X.path[key]`),
/// directly to the failable extraction helpers such as `require(_:converter:)` or `requireOneOf(_:values:)`.
extension JSONPath: JSONObjectPathConvertible where Root == ObjectRoot {
    public var path: JSONObjectPath { self }
}
