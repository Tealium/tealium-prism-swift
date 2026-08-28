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
    /// The name used to match and route this command during dispatch.
    var commandName: String { get }
}

public extension CommandName where Self: RawRepresentable, RawValue == String {
    /// Returns `rawValue` as the command name for `String`-backed `RawRepresentable` conformances.
    var commandName: String { rawValue }
}
