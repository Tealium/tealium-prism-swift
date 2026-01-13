//
//  TealiumFileManager.swift
//  tealium-prism
//
//  Created by Tyler Rister on 8/6/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// Utility class to create folders and get the path for a file for each specific account/profile.
public class TealiumFileManager {
    /// Returns the file path under application support/tealium-prism/account.profile/fileName
    public static func getApplicationFilePath(for account: String, profile: String, fileName: String) -> String? {
        return getApplicationFileUrl(for: account, profile: profile, fileName: fileName)?.path
    }

    /// Returns the file url under application support/tealium-prism/account.profile/fileName
    public static func getApplicationFileUrl(for account: String, profile: String, fileName: String) -> URL? {
        do {
            let fullDirectory = try getTealiumApplicationFolder().appendingPathComponent("\(account).\(profile)")
            if !FileManager.default.fileExists(atPath: fullDirectory.absoluteString, isDirectory: nil) {
                try FileManager.default.createDirectory(at: fullDirectory, withIntermediateDirectories: true)
            }
            return fullDirectory.appendingPathComponent(fileName)
        } catch {
            return nil
        }
    }

    /// Returns the tealium-prism folder under the application support directory.
    public static func getTealiumApplicationFolder() throws -> URL {
        let appSupportDir = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return appSupportDir.appendingPathComponent("tealium-prism")
    }

    /// Deletes the file at the provided path
    public static func deleteAtPath(path: String) throws {
        try FileManager.default.removeItem(atPath: path)
    }

    /// Sets the `isExcludedFromBackup` flag.
    public static func setIsExcludedFromBackup(to isExcludedFromBackup: Bool, for url: URL) throws {
        do {
            var resourceUrl = url
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = isExcludedFromBackup
            try resourceUrl.setResourceValues(resourceValues)
        } catch {
            throw error
        }
    }

    public static func fullJSONPath(from bundle: Bundle, relativePath: String) -> String? {
        if !relativePath.lowercased().hasSuffix(".json") {
            // For "name.json" saved, but only "name" passed
            return bundle.path(forResource: relativePath, ofType: "json") ??
            // For "name"/"name.otherExtension" saved, and same is passed
            bundle.path(forResource: relativePath, ofType: nil)
        } else {
            // For "name.json"/"name.JSON" saved, and same is passed
            return bundle.path(forResource: relativePath, ofType: nil)
        }
    }
}
