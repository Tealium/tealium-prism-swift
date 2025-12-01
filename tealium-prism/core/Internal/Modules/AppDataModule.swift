//
//  AppDataModule.swift
//  tealium-prism
//
//  Created by Tyler Rister on 7/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

/// Protocol for app data collection.
protocol AppDataCollection {
}

extension AppDataCollection {

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

/// Collector responsible for collecting app data: app UUID, build number, app name, app version and reverse DNS package name.
///
/// - App UUID: Typically a string like "4AB81234-C2A8-46DE-9AED-7ACE555521E0", persistent through the lifetime of the app installation. Resets if app is uninstalled.
/// - Build number: Typically a numeric string like "42", retrieved from the `CFBundleVersion` key in the app's Info.plist.
/// - App name: Typically a string like "MyApp", retrieved from the `CFBundleName` key in the app's Info.plist.
/// - App rDNS: Typically a string like "com.example.myapp", retrieved from the `CFBundleIdentifier` key in the app's Info.plist.
/// - App version: Typically a string like "1.0.0", retrieved from the `CFBundleShortVersionString` key in the app's Info.plist.
class AppDataModule: AppDataCollection, BasicModule, Collector {
    let version: String = TealiumConstants.libraryVersion
    static let moduleType: String = Modules.Types.appData
    var id: String { Self.moduleType }
    let dataStore: any DataStore
    private let bundle: Bundle
    private let logger: LoggerProtocol?

    required convenience init?(context: TealiumContext, moduleConfiguration: DataObject) {
        guard let dataStore = try? context.moduleStoreProvider.getModuleStore(name: Modules.Types.appData) else {
            return nil
        }
        self.init(dataStore: dataStore, bundle: .main, logger: context.logger)
    }

    init(dataStore: any DataStore, bundle: Bundle, logger: LoggerProtocol? = nil) {
        self.dataStore = dataStore
        self.bundle = bundle
        self.logger = logger
    }

    private var appUUID: String {
        guard let uuid: String = dataStore.get(key: TealiumDataKey.appUUID) else {
            let newUUID = UUID().uuidString
            do {
                try dataStore.edit()
                    .put(key: TealiumDataKey.appUUID, value: newUUID, expiry: .forever)
                    .commit()
            } catch {
                logger?.error(category: id, "Error writing app UUID to data store: \(error)")
            }
            return newUUID
        }
        return uuid
    }

    func collect(_ dispatchContext: DispatchContext) -> DataObject {
        [
            TealiumDataKey.appUUID: appUUID,
            TealiumDataKey.appBuild: Self.build(bundle: self.bundle),
            TealiumDataKey.appName: Self.name(bundle: self.bundle),
            TealiumDataKey.appRDNS: Self.rdns(bundle: self.bundle),
            TealiumDataKey.appVersion: Self.version(bundle: self.bundle)
        ]
    }
}

public extension TealiumDataKey {
    /// Key for random identifier persistent through the lifetime of the app installation. Value is reset if app is uninstalled.
    static let appUUID = "app_uuid"

    /// Key for the app build number, representing the build version of the app.
    static let appBuild = "app_build"

    /// Key for the app name, representing the display name of the app.
    static let appName = "app_name"

    /// Key for the reverse DNS package identifier, representing the app's unique bundle identifier.
    static let appRDNS = "app_rdns"

    /// Key for the app version, representing the user-facing version of the app.
    static let appVersion = "app_version"
}
