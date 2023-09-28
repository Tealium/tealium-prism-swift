//
//  TealiumProtocol.swift
//  tealium-swift
//
//  Created by Tyler Rister on 5/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

public class TealiumTimedEvents {
    func start(event name: String, with data: [String: Any]? = [String: Any]()) {}
    func stop(event name: String) {}
    func cancel(event name: String) {}
    func cancelAll() {}
}

public class TealiumConsent {
    // func grant(withPurpose: )
}

public protocol TealiumProtocol: AnyObject {
    func track(_ trackable: TealiumDispatch)
    func onReady(_ completion: @escaping () -> Void)

    var trace: TealiumTrace { get }
    var deepLink: TealiumDeepLink { get }
    var dataLayer: TealiumDataLayer { get }
    var timedEvents: TealiumTimedEvents { get }
    var consent: TealiumConsent { get }
    var modules: [TealiumModule] { get }
    func getModule<T: TealiumModule>(completion: @escaping (T?) -> Void)
}
