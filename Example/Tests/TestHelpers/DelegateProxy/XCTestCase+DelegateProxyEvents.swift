//
//  XCTestCase+DelegateProxyEvents.swift
//  tealium-prism_Tests
//
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

#if os(iOS)
@testable import TealiumPrism
import UIKit
import XCTest

enum SceneDelegateProxyError: Error {
    case sceneDelegateNotFound
    case appDelegateNotFound
}

/**
 * Delivers deep links the way the OS does, through whichever delegate `TealiumDelegateProxy` swizzled.
 *
 * Shared, because both the delegate proxy tests and the end-to-end tests need to start from a real
 * delegate callback: only the swizzled delegate exercises the path a launching deep link takes.
 * A target using these needs a host application, or there is no delegate to deliver anything to.
 */
extension XCTestCase {
    func sendOpenUrlEvent(urlString: String) throws {
        let url = try urlString.asUrl()
        if TealiumDelegateProxy.sceneEnabled {
            guard let scene = UIApplication.shared.connectedScenes.first,
                  let sceneDelegate = scene.delegate else {
                throw SceneDelegateProxyError.sceneDelegateNotFound
            }
            sceneDelegate.scene?(scene, openURLContexts: Set<UIOpenURLContext>([MockOpenUrlContext(url: url)]))
        } else {
            guard let appDelegate = UIApplication.shared.delegate else {
                throw SceneDelegateProxyError.appDelegateNotFound
            }
            _ = appDelegate.application?(UIApplication.shared, open: url, options: [:])
        }
    }

    func sendContinueUserActivityEvent(urlString: String) throws {
        let url = try urlString.asUrl()
        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = url
        if TealiumDelegateProxy.sceneEnabled {
            UIApplication.shared.manualSceneContinueUserActivity(activity)
        } else {
            UIApplication.shared.manualContinueUserActivity(activity)
        }
    }
}
#endif
