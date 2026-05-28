//
//  ReferenceContainerConvertible.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 18/03/2026.
//  Copyright © 2026 Tealium. All rights reserved.
//

import Foundation

/// Protocol for converting type-safe enum values to a `ReferenceContainer`.
///
/// Used by `RemoteCommandMappingsBuilder` to allow vendor-specific enums
/// as mapping destinations.
public protocol ReferenceContainerConvertible {
    func asReferenceContainer() -> ReferenceContainer
}

public extension ReferenceContainerConvertible {
    /// Shorthand for `asReferenceContainer().path`.
    var path: JSONObjectPath {
        asReferenceContainer().path
    }
}
