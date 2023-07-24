//
//  MockDatabaseHelper.swift
//  tealium-swift_Tests
//
//  Created by Tyler Rister on 7/12/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import SQLite
@testable import tealium_swift
import Foundation

class MockDatabaseHelper: SQLiteOpenHelper {
    var onUpgradeCallback: (Connection, Int, Int) throws -> Void
    var onDowngradeCallback: (Connection, Int, Int) throws -> Void
    var onCreateCallback: (Connection) throws -> Void
    var onConfigureCallback: (Connection) throws -> Void
    var onOpenCallback: (Connection) -> Void
    
    init(databaseName: String, version: Int, onUpgradeCallback: @escaping (Connection, Int, Int) throws -> Void = {_,_,_ in }, onDowngradeCallback: @escaping (Connection, Int, Int) throws -> Void = {_,_,_ in }, onCreateCallback: @escaping (Connection) throws -> Void = {_ in}, onConfigureCallback: @escaping (Connection) throws -> Void = {_ in}, onOpenCallback: @escaping (Connection) -> Void = {_ in}) throws {
        self.onUpgradeCallback = onUpgradeCallback
        self.onDowngradeCallback = onDowngradeCallback
        self.onCreateCallback = onCreateCallback
        self.onConfigureCallback = onConfigureCallback
        self.onOpenCallback = onOpenCallback
        try super.init(databaseName: databaseName, version: version, coreSettings: CoreSettings(coreDictionary: ["account": "Mock", "profile": "DatabaseHelper"]))
    }
    override func onUpgrade(database: Connection, fromOldVersion oldVersion: Int, toNewVersion newVersion: Int) throws {
        try onUpgradeCallback(database, oldVersion, newVersion)
    }
    override func onDowngrade(database: Connection, fromOldVersion oldVersion: Int, toNewVersion newVersion: Int) throws {
        try onDowngradeCallback(database, oldVersion, newVersion)
    }
    override func onCreate(database: Connection) throws {
        try onCreateCallback(database)
    }
    override func onConfigure(database: Connection) throws {
        try onConfigureCallback(database)
    }
    override func onOpen(database: Connection) {
        onOpenCallback(database)
    }
}
