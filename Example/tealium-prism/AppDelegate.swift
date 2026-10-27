//
//  AppDelegate.swift
//  tealium-prism
//
//  Created by Tyler Rister on 5/12/2022.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import SwiftUI
import TealiumPrism

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@main
struct iOSTealiumTestApp: App {
    #if os(iOS) || os(tvOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #elseif os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif

    init() {
        TealiumSignposter.enabled = true
        TealiumHelper.shared.startTealium()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

#if os(iOS) || os(tvOS)
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return true
    }
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
    // For AppDelegateProxyTests
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return true
    }
    func application(_ application: UIApplication, didUpdate userActivity: NSUserActivity) {}
}
#elseif os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {}
    // For AppDelegateProxyTests
    func application(_ application: NSApplication, open urls: [URL]) {}
}
#endif
