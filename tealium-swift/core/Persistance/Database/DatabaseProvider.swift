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

    init(settings: CoreSettings) throws {
        database = try Self.getPersistentDatabase(settings: settings) ?? Self.getInMemoryDatabase(settings: settings)
    }

    static func getPersistentDatabase(settings: CoreSettings) -> Connection? {
        let helper = DatabaseHelper(databaseName: "tealium", coreSettings: settings)
        do {
            return try helper.getDatabase()
        } catch DatabaseErrors.unsupportedDowgrade {
            helper.deleteDatabase()
            return try? helper.getDatabase()
        } catch {
            return nil
        }
    }

    static func getInMemoryDatabase(settings: CoreSettings) throws -> Connection {
        let helper = DatabaseHelper(databaseName: nil, coreSettings: settings)
        return try helper.getDatabase()
    }
}
