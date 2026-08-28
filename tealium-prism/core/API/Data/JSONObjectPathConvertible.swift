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
