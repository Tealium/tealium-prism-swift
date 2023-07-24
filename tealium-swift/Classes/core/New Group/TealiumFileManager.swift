//
//  TealiumFileManager.swift
//  tealium-swift
//
//  Created by Tyler Rister on 6/8/23.
//

import Foundation

public class TealiumFileManager {
    public static func getApplicationFilePath(for account: String, profile: String, fileName: String, backup: Bool = false) -> String? {
        return getApplicationFileUrl(for: account, profile: profile, fileName: fileName, backup: backup)?.path
    }
    
    public static func getApplicationFileUrl(for account: String, profile: String, fileName: String, backup: Bool = false) -> URL? {
        do {
            let appSupportDir = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let fullDirectory = appSupportDir.appendingPathComponent("Tealium").appendingPathComponent("\(account).\(profile)")
            if !FileManager.default.fileExists(atPath: fullDirectory.absoluteString, isDirectory: nil) {
                try FileManager.default.createDirectory(at: fullDirectory, withIntermediateDirectories: true)
            }
            return fullDirectory.appendingPathComponent(fileName)
        } catch {
            return nil
        }
    }
    
    public static func getTealiumApplicationFolder() -> URL? {
        do {
            let appSupportDir = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            return appSupportDir.appendingPathComponent("Tealium")
        } catch {
            return nil
        }
    }
    
    public static func deleteAtPath(path: String) throws {
        try FileManager.default.removeItem(atPath: path)
    }
    
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
}
