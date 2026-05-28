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
    /// Supports both single command (String) and array of commands ([String]).
    /// Commands are mapped to the "command_name" key by Mappings (not tealium_event).
    ///
    /// - Returns: Array of command strings. Returns empty array if no commands found.
    func getCommands() -> [String] {
        payload.getArray(key: TealiumDataKey.commandName, of: String.self)?.compactMap { $0 }
            ?? payload.get(key: TealiumDataKey.commandName, as: String.self).map { [$0] }
            ?? []
    }
}
