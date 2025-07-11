//
//  DatabaseProvider.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 04/08/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite

public protocol DatabaseProviderProtocol {
    var database: Connection { get }
}

public class DatabaseProvider: DatabaseProviderProtocol {
    public let database: Connection

    init(config: TealiumConfig) throws {
        database = try Self.getPersistentDatabase(config: config) ?? Self.getInMemoryDatabase(config: config)
    }

    static func getPersistentDatabase(config: TealiumConfig) -> Connection? {
        let helper = DatabaseHelper(databaseName: "tealium", config: config)
        do {
            return try helper.getDatabase()
        } catch DatabaseErrors.unsupportedDowngrade {
            helper.deleteDatabase()
            return try? helper.getDatabase()
        } catch {
            return nil
        }
    }

    static func getInMemoryDatabase(config: TealiumConfig) throws -> Connection {
        let helper = DatabaseHelper(databaseName: nil, config: config)
        return try helper.getDatabase()
    }
}
