//
//  CommandName.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 23/03/2026.
//  Copyright © 2026 Tealium. All rights reserved.
//

import Foundation

/// Protocol for types that carry a command name used for dispatch routing.
///
/// Used as the `Command` generic constraint in `CommandMappingsBuilder`
/// to allow type-safe command mapping without requiring `RawRepresentable`.
public protocol CommandName {
    var commandName: String { get }
}

public extension CommandName where Self: RawRepresentable, RawValue == String {
    var commandName: String { rawValue }
}
