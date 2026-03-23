//
//  RemoteCommandRegistry.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 18/03/2026.
//  Copyright © 2026 Tealium. All rights reserved.
//

import Foundation

/// Registry for remote commands providing O(1) lookup by name.
///
/// Implements the command pattern to register and execute vendor-specific commands.
/// Commands are registered by name and routed to their respective implementations
/// when executed with payload data.
public class RemoteCommandRegistry {

    private var commands: [String: RemoteCommandProtocol] = [:]

    public init() {}

    /// Register a single command.
    public func register(_ command: RemoteCommandProtocol) {
        commands[normalize(command.name)] = command
    }

    /// Register multiple commands at once.
    public func registerAll(_ commandList: [RemoteCommandProtocol]) {
        commandList.forEach { register($0) }
    }

    /// Execute a command by name.
    /// - Throws: `RemoteCommandError.commandNotFound` if command not found in registry.
    /// - Throws: `RemoteCommandError` if command validation fails.
    public func execute(commandName: String, payload: DataObject) throws(RemoteCommandError) {
        let normalizedName = normalize(commandName)

        guard let command = commands[normalizedName] else {
            throw RemoteCommandError.commandNotFound(commandName)
        }

        try command.execute(payload: payload)
    }

    private func normalize(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespaces).lowercased()
    }
}
