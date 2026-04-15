//
//  Command.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 18/03/2026.
//  Copyright © 2026 Tealium. All rights reserved.
//

import Foundation

/// Protocol for remote commands executed via command pattern.
/// Registered in `CommandRegistry` with O(1) lookup by name.
public protocol Command {
    /// Command name used for routing by `CommandRegistry`.
    /// The registry normalizes names by trimming whitespace and lowercasing before lookup,
    /// so implementations should provide a logical, case-insensitive name without leading/trailing whitespace.
    var name: String { get }

    /// Executes the command with the given payload.
    ///
    /// - Parameters:
    ///   - payload: The data to process.
    ///   - completion: Called exactly once with `nil` on success or a `CommandError` on failure.
    /// - Returns: A `Disposable` that cancels in-progress async work when disposed.
    func execute(payload: DataObject, completion: @escaping (CommandError?) -> Void) -> Disposable
}
