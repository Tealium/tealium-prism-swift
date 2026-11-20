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
    /// The names are returned normalized (trimmed of whitespace and lowercased),
    /// which is how commands are matched when executed.
    /// Blank commands (empty or whitespace-only) are skipped, and duplicates are removed,
    /// keeping the first occurrence and preserving the order.
    /// The payload's "command_name" is left unchanged,
    /// so commands reading it directly may see the original names, including duplicates.
    ///
    /// - Returns: Array of unique normalized command names. Returns empty array if no commands found.
    func getCommands() -> [String] {
        let commands = payload.getArray(key: TealiumDataKey.commandName, of: String.self)?.compactMap { $0 }
            ?? payload.get(key: TealiumDataKey.commandName, as: String.self).map { [$0] }
            ?? []
        return commands.map(CommandRegistry.normalize)
            .filter { !$0.isEmpty }
            .removingDuplicates(by: \.self)
    }
}
