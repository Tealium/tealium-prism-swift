//
//  CommandMappingsBuilder.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 18/03/2026.
//  Copyright © 2026 Tealium. All rights reserved.
//

import Foundation

/// Generic reusable base class for building vendor-specific mappings.
///
/// Subclasses `Mappings` and adds overloaded methods that accept type-safe
/// `Command` and `Destination` enums instead of raw strings.
///
/// Base `Mappings` methods (accepting `String` and `JSONObjectPath`) remain
/// available for cases not covered by the enums.
open class CommandMappingsBuilder<
    Command: CommandNamed,
    Destination: JSONObjectPathConvertible
>: Mappings {

    /// Maps a command to the command name destination.
    @discardableResult
    public func mapCommand(_ command: Command) -> CommandOptions {
        mapCommand(command.commandName)
    }

    /// Maps a source key to a typed destination.
    @discardableResult
    public func mapFrom(_ key: String, to destination: Destination) -> VariableOptions {
        mapFrom(key, to: destination.path)
    }

    /// Maps a source path to a typed destination.
    @discardableResult
    public func mapFrom(_ path: JSONObjectPath, to destination: Destination) -> VariableOptions {
        mapFrom(path, to: destination.path)
    }

    /// Maps a constant value to a typed destination.
    @discardableResult
    public func mapConstant(_ value: DataInput, to destination: Destination) -> ConstantOptions {
        mapConstant(value, to: destination.path)
    }

    /// Keeps a typed destination (source and destination are the same).
    @discardableResult
    public func keep(_ destination: Destination) -> VariableOptions {
        keep(destination.path)
    }
}
