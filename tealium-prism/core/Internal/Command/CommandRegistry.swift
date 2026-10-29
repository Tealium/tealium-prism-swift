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
class CommandRegistry {

    private var commands: [String: Command]

    init(commands: [Command]) {
        var dict: [String: Command] = [:]
        for command in commands {
            dict[CommandRegistry.normalize(command.name)] = command
        }
        self.commands = dict
    }

    /// Execute a command by name.
    ///
    /// - Parameters:
    ///   - commandName: The name of the command to execute. It must already be normalized, as returned by `Dispatch.getCommands()`.
    ///   - payload: The data to pass to the command.
    ///   - completion: Called with `nil` on success or a `CommandError` on failure.
    /// - Returns: A `Disposable` that cancels the command's in-progress work when disposed.
    func execute(commandName: String, payload: DataObject, completion: @escaping (CommandError?) -> Void) -> any Disposable {
        guard let command = commands[commandName] else {
            completion(.commandNotFound(commandName))
            return Disposables.disposed()
        }

        return command.execute(payload: payload, completion: completion)
    }

    /// The form of a command name used to match command names: trimmed of whitespace and lowercased.
    /// Applied to `Command.name` at registration and by `Dispatch.getCommands()`.
    static func normalize(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
