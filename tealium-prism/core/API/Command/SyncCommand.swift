//
//  SyncCommand.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 26/03/2026.
//  Copyright © 2026 Tealium. All rights reserved.
//

import Foundation

/// Base class for synchronous commands.
///
/// Subclass this and override `execute(payload:)` for commands that complete their work
/// synchronously (e.g. setting a user property, logging an event).
/// The override can call the `DataItemExtractor` helpers directly and throw `CommandError`s.
/// A thrown error is passed to the completion and reported as described on `Command`.
///
/// The override is untyped so that commands can mix helpers throwing `ExtractionError`
/// with their own `CommandError`s without converting at each call site.
///
/// The protocol requirement is handled by a `final` wrapper — subclasses cannot
/// accidentally override the wrong overload.
open class SyncCommand: Command {

    public let name: String

    /// Creates a synchronous command with the given name.
    /// - Parameter name: The name used to identify and route this command in a `CommandRegistry`.
    public init(name: String) {
        self.name = name
    }

    /// Protocol requirement — delegates to the synchronous overload. Do not override.
    public final func execute(payload: DataObject, completion: @escaping (Error?) -> Void) -> any Disposable {
        do {
            try execute(payload: payload)
            completion(nil)
        } catch {
            completion(error)
        }
        return Disposables.disposed()
    }

    /// Override this for synchronous command logic.
    /// - Throws: A `CommandError` if validation fails, an `ExtractionError` if a required parameter can't be read,
    /// or any other error. It is passed to the completion and reported as described on `Command`.
    open func execute(payload: DataObject) throws {}
}
