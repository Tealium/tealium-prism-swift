//
//  AppDataCollector.swift
//  tealium-swift
//
//  Created by Tyler Rister on 12/7/22.
//

import Foundation

public protocol AppDataCollection {
    /// Retrieves app name from Bundle￼￼￼￼￼￼.
    ///
    /// - Parameter bundle: `Bundle`
    /// - Returns: `String?` containing the app name
    func name(bundle: Bundle) -> String?

    /// Retrieves the rdns package identifier from Bundle￼￼￼￼￼￼.
    ///
    /// - Parameter bundle: `Bundle`
    /// - Returns: `String?` containing the rdns package identifier
    func rdns(bundle: Bundle) -> String?

    /// Retrieves app version from Bundle￼￼￼￼￼￼.
    ///
    /// - Parameter bundle: `Bundle`
    /// - Returns: `String?` containing the app version
    func version(bundle: Bundle) -> String?

    /// Retrieves app build number from Bundle￼￼￼￼￼￼.
    ///
    /// - Parameter bundle: `Bundle`
    /// - Returns: `String?` containing the app build number
    func build(bundle: Bundle) -> String?
}

public extension AppDataCollection {

    /// Retrieves app name from Bundle￼￼￼￼￼￼.
    ///
    /// - Parameter bundle: `Bundle`
    /// - Returns: `String?` containing the app name
    func name(bundle: Bundle) -> String? {
        return bundle.infoDictionary?[kCFBundleNameKey as String] as? String
    }

    /// Retrieves the rdns package identifier from Bundle￼￼￼￼￼￼.
    ///
    /// - Parameter bundle: `Bundle`
    /// - Returns: `String?` containing the rdns package identifier
    func rdns(bundle: Bundle) -> String? {
        return bundle.bundleIdentifier
    }

    /// Retrieves app version from Bundle￼￼￼￼￼￼.
    ///
    /// - Parameter bundle: `Bundle`
    /// - Returns: `String?` containing the app version
    func version(bundle: Bundle) -> String? {
        return bundle.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    /// Retrieves app build number from Bundle￼￼￼￼￼￼.
    ///
    /// - Parameter bundle: `Bundle`
    /// - Returns: `String?` containing the app build number
    func build(bundle: Bundle) -> String? {
        return bundle.infoDictionary?[kCFBundleVersionKey as String] as? String
    }
}

public class AppDataCollector: AppDataCollection, Collector {
    public var enabled: Bool = true
    
    var data: [String : TealiumDataValue?]
    
    public static var id: String = "appdata"
    
    public required init(context: TealiumContext, moduleSettings: [String : Any]) {
        data = [:]
        data = [
            TealiumDataKey.appBuild: self.build(bundle: Bundle.main),
            TealiumDataKey.appName: self.name(bundle: Bundle.main),
            TealiumDataKey.appRDNS: self.rdns(bundle: Bundle.main),
            TealiumDataKey.appVersion: self.version(bundle: Bundle.main)
        ]
    }
    
    public func updateSettings(settings: [String : Any]) {
        
    }
}

    public extension TealiumDataKey {
        static let appBuild = "app_build"
        static let appName = "app_name"
        static let appRDNS = "app_rdns"
        static let appVersion = "app_version"
    }
