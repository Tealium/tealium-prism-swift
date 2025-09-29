//
//  AppDataModule.swift
//  tealium-prism
//
//  Created by Tyler Rister on 7/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

/// Protocol for app data collection.
public protocol AppDataCollection {
}

public extension AppDataCollection {

    /// Retrieves app name from `Bundle`.
    ///
    /// - Parameter bundle: `Bundle`
    /// - Returns: `String?` containing the app name
    static func name(bundle: Bundle) -> String? {
        return bundle.infoDictionary?[kCFBundleNameKey as String] as? String
    }

    /// Retrieves the reverse DNS package identifier from `Bundle`.
    ///
    /// - Parameter bundle: `Bundle`
    /// - Returns: `String?` containing the reverse DNS package identifier
    static func rdns(bundle: Bundle) -> String? {
        return bundle.bundleIdentifier
    }

    /// Retrieves app version from `Bundle`.
    ///
    /// - Parameter bundle: `Bundle`
    /// - Returns: `String?` containing the app version
    static func version(bundle: Bundle) -> String? {
        return bundle.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    /// Retrieves app build number from `Bundle`.
    ///
    /// - Parameter bundle: `Bundle`
    /// - Returns: `String?` containing the app build number
    static func build(bundle: Bundle) -> String? {
        return bundle.infoDictionary?[kCFBundleVersionKey as String] as? String
    }
}

/// Collector responsible for collecting app data: build number, app name, app version and reverse DNS package name.
///
/// - Build number: Typically a numeric string like "42", retrieved from the `CFBundleVersion` key in the app's Info.plist.
/// - App name: Typically a string like "MyApp", retrieved from the `CFBundleName` key in the app's Info.plist.
/// - App rDNS: Typically a string like "com.example.myapp", retrieved from the `CFBundleIdentifier` key in the app's Info.plist.
/// - App version: Typically a string like "1.0.0", retrieved from the `CFBundleShortVersionString` key in the app's Info.plist.
class AppDataModule: AppDataCollection, BasicModule, Collector {
    let version: String = TealiumConstants.libraryVersion
    private let bundle: Bundle
    let id: String = Modules.Types.appData

    required convenience init?(context: TealiumContext, moduleConfiguration: DataObject) {
        self.init(bundle: .main)
    }

    init(bundle: Bundle) {
        self.bundle = bundle
    }

    func collect(_ dispatchContext: DispatchContext) -> DataObject {
        [
            TealiumDataKey.appBuild: Self.build(bundle: self.bundle),
            TealiumDataKey.appName: Self.name(bundle: self.bundle),
            TealiumDataKey.appRDNS: Self.rdns(bundle: self.bundle),
            TealiumDataKey.appVersion: Self.version(bundle: self.bundle)
        ]
    }
}

public extension TealiumDataKey {
    /// Key for the app build number, representing the build version of the app.
    static let appBuild = "app_build"

    /// Key for the app name, representing the display name of the app.
    static let appName = "app_name"

    /// Key for the reverse DNS package identifier, representing the app's unique bundle identifier.
    static let appRDNS = "app_rdns"

    /// Key for the app version, representing the user-facing version of the app.
    static let appVersion = "app_version"
}
