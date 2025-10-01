//
//  MockDatabaseHelper.swift
//  tealium-prism_Tests
//
//  Created by Tyler Rister on 12/7/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import SQLite
@testable import TealiumPrism

class MockDatabaseHelper: SQLiteOpenHelper {
    var onUpgradeCallback: (Connection, Int, Int) throws -> Void
    var onDowngradeCallback: (Connection, Int, Int) throws -> Void
    var onCreateCallback: (Connection) throws -> Void
    var onConfigureCallback: (Connection) throws -> Void
    var onOpenCallback: (Connection) -> Void

    init(version: Int,
         onUpgradeCallback: @escaping (Connection, Int, Int) throws -> Void = { _, _, _ in },
         onDowngradeCallback: @escaping (Connection, Int, Int) throws -> Void = { _, _, _ in },
         onCreateCallback: @escaping (Connection) throws -> Void = { _ in },
         onConfigureCallback: @escaping (Connection) throws -> Void = { _ in },
         onOpenCallback: @escaping (Connection) -> Void = { _ in }) {
        self.onUpgradeCallback = onUpgradeCallback
        self.onDowngradeCallback = onDowngradeCallback
        self.onCreateCallback = onCreateCallback
        self.onConfigureCallback = onConfigureCallback
        self.onOpenCallback = onOpenCallback
        super.init(version: version, config: mockConfig)
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
