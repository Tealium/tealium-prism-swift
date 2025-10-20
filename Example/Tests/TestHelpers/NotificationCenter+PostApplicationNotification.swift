//
//  NotificationCenter+PostApplicationNotification.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 10/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation
#if os(iOS) || os(tvOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#elseif os(macOS)
import AppKit
#endif

extension NotificationCenter {
    func postBecomeActiveNotification() {
        #if os(iOS) || os(tvOS)
        let notification = UIApplication.didBecomeActiveNotification
        #elseif os(watchOS)
        let notification = WKExtension.applicationDidBecomeActiveNotification
        #elseif os(macOS)
        let notification = NSApplication.didBecomeActiveNotification
        #endif
        self.post(name: notification, object: nil)
    }

    func postResignActiveNotification() {
        #if os(iOS) || os(tvOS)
        let notification = UIApplication.willResignActiveNotification
        #elseif os(watchOS)
        let notification = WKExtension.applicationWillResignActiveNotification
        #elseif os(macOS)
        let notification = NSApplication.willResignActiveNotification
        #endif
        self.post(name: notification, object: nil)
    }

}
