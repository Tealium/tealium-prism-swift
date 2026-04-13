//
//  CommandRegistry.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 18/03/2026.
//  Copyright © 2026 Tealium. All rights reserved.
//

import Foundation

/// Registry for commands providing O(1) lookup by name.
///
/// Implements the command pattern to register and execute vendor-specific commands.
/// Commands are registered by name and routed to their respective implementations
/// when executed with payload data.
public class CommandRegistry {

    private var commands: [String: CommandProtocol]

    public init(commands: [CommandProtocol]) {
        var dict: [String: CommandProtocol] = [:]
        for command in commands {
            dict[Self.normalize(command.name)] = command
        }
        self.commands = dict
    }

    /// Execute a command by name.
    ///
    /// - Parameters:
    ///   - commandName: The name of the command to execute (normalized internally).
    ///   - payload: The data to pass to the command.
    ///   - completion: Called with `nil` on success or a `CommandError` on failure.
    /// - Returns: A `Disposable` that cancels the command's in-progress work when disposed.
    public func execute(commandName: String, payload: DataObject, completion: @escaping (CommandError?) -> Void) -> Disposable {
        let normalizedName = Self.normalize(commandName)

        guard let command = commands[normalizedName] else {
            completion(.commandNotFound(commandName))
            return Disposables.disposed()
        }

        return command.execute(payload: payload, completion: completion)
    }

    private static func normalize(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespaces).lowercased()
    }
}
