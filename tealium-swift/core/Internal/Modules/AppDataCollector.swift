//
//  AppDataCollector.swift
//  tealium-swift
//
//  Created by Tyler Rister on 7/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol AppDataCollection {
}

public extension AppDataCollection {

    /// Retrieves app name from Bundle￼￼￼￼￼￼.
    ///
    /// - Parameter bundle: `Bundle`
    /// - Returns: `String?` containing the app name
    static func name(bundle: Bundle) -> String? {
        return bundle.infoDictionary?[kCFBundleNameKey as String] as? String
    }

    /// Retrieves the rdns package identifier from Bundle￼￼￼￼￼￼.
    ///
    /// - Parameter bundle: `Bundle`
    /// - Returns: `String?` containing the rdns package identifier
    static func rdns(bundle: Bundle) -> String? {
        return bundle.bundleIdentifier
    }

    /// Retrieves app version from Bundle￼￼￼￼￼￼.
    ///
    /// - Parameter bundle: `Bundle`
    /// - Returns: `String?` containing the app version
    static func version(bundle: Bundle) -> String? {
        return bundle.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    /// Retrieves app build number from Bundle￼￼￼￼￼￼.
    ///
    /// - Parameter bundle: `Bundle`
    /// - Returns: `String?` containing the app build number
    static func build(bundle: Bundle) -> String? {
        return bundle.infoDictionary?[kCFBundleVersionKey as String] as? String
    }
}

class AppDataCollector: AppDataCollection, TealiumBasicModule, Collector {

    static let id: String = "AppData"

    required init?(context: TealiumContext, moduleSettings: DataObject) {}

    func collect(_ dispatchContext: DispatchContext) -> DataObject {
        [
            TealiumDataKey.appBuild: Self.build(bundle: Bundle.main) ?? NSNull(),
            TealiumDataKey.appName: Self.name(bundle: Bundle.main) ?? NSNull(),
            TealiumDataKey.appRDNS: Self.rdns(bundle: Bundle.main) ?? NSNull(),
            TealiumDataKey.appVersion: Self.version(bundle: Bundle.main) ?? NSNull()
        ]
    }
}

public extension TealiumDataKey {
    static let appBuild = "app_build"
    static let appName = "app_name"
    static let appRDNS = "app_rdns"
    static let appVersion = "app_version"
}
