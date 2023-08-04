//
//  DatabaseHelper.swift
//  tealium-swift
//
//  Created by Tyler Rister on 12/5/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite

class DatabaseUpgrade {
    let version: Int
    let upgrade: (Connection) throws -> Void

    init (version: Int, upgrade: @escaping (Connection) throws -> Void) {
        self.version = version
        self.upgrade = upgrade
    }
}

public class DatabaseHelper: SQLiteOpenHelper {

    static var databaseUpgrades: [DatabaseUpgrade] = [
    ]

    static var DATABASE_VERSION = 1

    init(databaseName: String?, coreSettings: CoreSettings) throws {
        try super.init(databaseName: databaseName, version: DatabaseHelper.DATABASE_VERSION, coreSettings: coreSettings)
    }

    public override func onCreate(database: Connection) throws {
        // Create Queue Tables
        try DispatchSchema.createtable(database: database)
        try DispatcherSchema.createTable(database: database)
        try QueueSchema.createTable(database: database)

        // Create Module Tables
        try ModuleSchema.createTable(database: database)
        try ModuleStorageSchema.createTable(database: database)

        // Create Triggers
        _ = try database.run(DispatchSchema.getTriggerForAddToQueue())
        _ = try database.run(QueueSchema.getTriggerToRemoveProcessedDispatches())
    }

    public override func onUpgrade(database: Connection, fromOldVersion oldVersion: Int, toNewVersion newVersion: Int) throws {
        try getDatabaseUpgrades(oldVersion: oldVersion).forEach {
            try $0.upgrade(database)
        }
        database.userVersion = UserVersion(newVersion)
    }

    func getDatabaseUpgrades(oldVersion: Int, upgrades: [DatabaseUpgrade] = DatabaseHelper.databaseUpgrades) -> [DatabaseUpgrade] {
        return upgrades.filter { oldVersion < $0.version }
            .sorted(by: { $0.version < $1.version })
    }
}
