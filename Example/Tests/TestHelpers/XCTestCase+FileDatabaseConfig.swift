//
//  XCTestCase+FileDatabaseConfig.swift
//  tealium-prism_Tests
//
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

extension XCTestCase {
    /// A config whose database is a file named "tealium" in the folder of `account`, with `MockDispatcher` as its only module and a mock
    /// network client. The folder is not cleaned: see `removeAccountFolderNowAndAtTeardown(account:)`.
    func fileDatabaseConfig(account: String = "fileDatabaseAccount", profile: String = "mock_profile", settingsUrl: String? = nil,
                            minLogLevel: LogLevel.Minimum = .silent) -> TealiumConfig {
        var config = TealiumConfig(account: account, profile: profile, environment: "mockEnv",
                                   modules: [MockDispatcher.factory()], settingsFile: nil, settingsUrl: settingsUrl) { builder in
            builder.setMinLogLevel(minLogLevel)
        }
        config.databaseName = "tealium"
        config.networkClient = MockNetworkClient(result: .success(.successful()))
        return config
    }

    /// Deletes the folder of `account` now and at teardown, so that a test starts and leaves without a database file.
    func removeAccountFolderNowAndAtTeardown(account: String) throws {
        let accountPath = try TealiumFileManager.getTealiumApplicationFolder().appendingPathComponent(account).path
        try? TealiumFileManager.deleteAtPath(path: accountPath)
        addTeardownBlock { try? TealiumFileManager.deleteAtPath(path: accountPath) }
    }

    /// Puts a regular file where `account`'s folder goes, so that creating the folder fails, and removes it at teardown.
    func blockAccountFolder(_ account: String) throws {
        let tealiumFolder = try TealiumFileManager.getTealiumApplicationFolder()
        let accountPath = tealiumFolder.appendingPathComponent(account).path
        try FileManager.default.createDirectory(at: tealiumFolder, withIntermediateDirectories: true)
        try? FileManager.default.removeItem(atPath: accountPath)
        guard FileManager.default.createFile(atPath: accountPath, contents: Data()) else {
            throw StagingError("Could not create a file at \(accountPath) to block the account folder")
        }
        addTeardownBlock { try? FileManager.default.removeItem(atPath: accountPath) }
    }
}
