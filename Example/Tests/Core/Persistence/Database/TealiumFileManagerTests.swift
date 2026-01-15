//
//  TealiumFileManagerTests.swift
//  tealium-prism_Tests
//
//  Created by Tyler Rister on 11/7/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumPrism
import XCTest

class TealiumFileManagerTests: XCTestCase {

    override class func tearDown() {
        try? TealiumFileManager.deleteAtPath(path: TealiumFileManager.getTealiumApplicationFolder().path)
    }

    func test_file_manager_creates_intermediate_directories() throws {
        let appSupportDir = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let fullDirectory = appSupportDir.appendingPathComponent("tealium-prism")
            .appendingPathComponent("test_account")
            .appendingPathComponent("test_profile")
        var isdirectory: ObjCBool = false
        try? FileManager.default.removeItem(at: fullDirectory)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fullDirectory.path, isDirectory: &isdirectory))
        _ = TealiumFileManager.getApplicationFileUrl(for: "test_account", profile: "test_profile", fileName: "test_file.txt")
        XCTAssertTrue(FileManager.default.fileExists(atPath: fullDirectory.path, isDirectory: &isdirectory))
    }

    func test_file_deleting_works() {
        guard let testFile = TealiumFileManager.getApplicationFileUrl(for: "account", profile: "profile", fileName: "test_file.txt")?.path else {
            XCTFail("Failed to get path for test file.")
            return
        }
        FileManager.default.createFile(atPath: testFile, contents: Data("test file contents".utf8))
        XCTAssertTrue(FileManager.default.fileExists(atPath: testFile))
        XCTAssertNoThrow(try TealiumFileManager.deleteAtPath(path: testFile))
        XCTAssertFalse(FileManager.default.fileExists(atPath: testFile))
    }

    func test_file_manager_excluded_from_backup_set() {
        guard let testFile = TealiumFileManager.getApplicationFileUrl(for: "account", profile: "profile", fileName: "excluded_file.json") else {
            XCTFail("Failed to get path for file.")
            return
        }
        FileManager.default.createFile(atPath: testFile.path, contents: Data("{\"test_key\": \"test_value\"}".utf8))
        let isExcludedFromBackup = try? testFile.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup
        XCTAssertFalseOptional(isExcludedFromBackup)
        XCTAssertNoThrow(try TealiumFileManager.setIsExcludedFromBackup(to: true, for: testFile))
        guard let urlAgain = TealiumFileManager.getApplicationFileUrl(for: "account", profile: "profile", fileName: "excluded_file.json") else {
            XCTFail("Failed to get url again.")
            return
        }
        let newIsExcludedFromBackup = try? urlAgain.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup
        XCTAssertTrueOptional(newIsExcludedFromBackup)
    }
}
