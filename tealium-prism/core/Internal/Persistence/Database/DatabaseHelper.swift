//
//  DatabaseHelper.swift
//  tealium-prism
//
//  Created by Tyler Rister on 12/5/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite

/**
 * Concrete implementation of the `SQLiteOpenHelper` which implements the onCreate/onConfigure/onUpgrade/onDowngrade methods.
 */
class DatabaseHelper: SQLiteOpenHelper {

    /// The list of all upgrades since version 1
    static var databaseUpgrades: [DatabaseUpgrade] = [
    ]

    /// The current version of the DB implemented in the codebase
    static var DATABASE_VERSION = 1

    init(config: TealiumConfig?) {
        super.init(version: DatabaseHelper.DATABASE_VERSION,
                   config: config)
    }

    override func onConfigure(database: Connection) throws {
        database.foreignKeys = true
    }

    override func onCreate(database: Connection) throws {
        // Create Queue Tables
        try DispatchSchema.createTable(database: database)
        try QueueSchema.createTable(database: database)

        // Create Module Tables
        try ModuleSchema.createTable(database: database)
        try ModuleStorageSchema.createTable(database: database)

        // Create Triggers
        _ = try database.run(QueueSchema.getTriggerToRemoveProcessedDispatches())
    }

    override func onUpgrade(database: Connection, fromOldVersion oldVersion: Int, toNewVersion newVersion: Int) throws {
        try getDatabaseUpgrades(oldVersion: oldVersion).forEach {
            try $0.upgrade(database)
        }
        database.userVersion = UserVersion(newVersion)
    }

    override func onDowngrade(database: Connection, fromOldVersion oldVersion: Int, toNewVersion newVersion: Int) throws {
        throw DatabaseError.unsupportedDowngrade
    }

    func getDatabaseUpgrades(oldVersion: Int, upgrades: [DatabaseUpgrade] = DatabaseHelper.databaseUpgrades) -> [DatabaseUpgrade] {
        return upgrades.filter { oldVersion < $0.version }
            .sorted(by: { $0.version < $1.version })
    }
}
