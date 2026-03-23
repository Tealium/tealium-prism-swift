//
//  RemoteCommandProtocol.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 18/03/2026.
//  Copyright © 2026 Tealium. All rights reserved.
//

import Foundation

/// Protocol for remote commands executed via command pattern.
/// Registered in `RemoteCommandRegistry` with O(1) lookup by name.
public protocol RemoteCommandProtocol {
    /// Command name used for routing by `RemoteCommandRegistry`.
    /// The registry normalizes names by trimming whitespace and lowercasing before lookup,
    /// so implementations should provide a logical, case-insensitive name without leading/trailing whitespace.
    var name: String { get }

    /// Executes the command with payload.
    /// - Throws: `RemoteCommandError` if validation fails or required parameters are missing.
    func execute(payload: DataObject) throws(RemoteCommandError)
}
