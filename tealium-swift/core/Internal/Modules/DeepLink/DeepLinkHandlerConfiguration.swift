//
//  DeepLinkHandlerConfiguration.swift
//  tealium-swift
//
//  Created by Den Guzov on 15/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

struct DeepLinkHandlerConfiguration {
    let deepLinkTrackingEnabled: Bool
    let qrTraceEnabled: Bool
    let sendDeepLinkEvent: Bool

    enum Keys {
        static let deepLinkTrackingEnabled = "deep_link_tracking_enabled"
        static let qrTraceEnabled = "qr_trace_enabled"
        static let sendDeepLinkEvent = "send_deep_link_event"
    }

    enum Defaults {
        static let deepLinkTrackingEnabled: Bool = true
        static let qrTraceEnabled: Bool = true
        static let sendDeepLinkEvent: Bool = false
    }

    init(configuration: DataObject) {
        deepLinkTrackingEnabled = configuration.get(key: Keys.deepLinkTrackingEnabled) ?? Defaults.deepLinkTrackingEnabled
        qrTraceEnabled = configuration.get(key: Keys.qrTraceEnabled) ?? Defaults.qrTraceEnabled
        sendDeepLinkEvent = configuration.get(key: Keys.sendDeepLinkEvent) ?? Defaults.sendDeepLinkEvent
    }
}
