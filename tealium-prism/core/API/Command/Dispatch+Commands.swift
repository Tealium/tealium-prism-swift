//
//  Dispatch+Commands.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 18/03/2026.
//  Copyright © 2026 Tealium. All rights reserved.
//

import Foundation

public extension Dispatch {
    /// Extracts command(s) from the dispatch payload.
    ///
    /// Supports both single command (String) and array of commands ([String]).
    /// Commands are mapped to the "command_name" key by Mappings (not tealium_event).
    /// Duplicate commands are removed, keeping the first occurrence and preserving the order.
    /// Two commands are duplicates if they are equal once trimmed of whitespace and lowercased,
    /// which is how commands are matched when executed.
    /// Duplicates are removed only from the returned list: the payload's "command_name" is left unchanged,
    /// so commands reading it directly may see duplicates.
    ///
    /// - Returns: Array of unique command strings. Returns empty array if no commands found.
    func getCommands() -> [String] {
        let commands = payload.getArray(key: TealiumDataKey.commandName, of: String.self)?.compactMap { $0 }
            ?? payload.get(key: TealiumDataKey.commandName, as: String.self).map { [$0] }
            ?? []
        var seen = Set<String>()
        return commands.filter { seen.insert(CommandRegistry.normalize($0)).inserted }
    }
}
