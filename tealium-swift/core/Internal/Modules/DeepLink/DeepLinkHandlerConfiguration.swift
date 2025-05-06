//
//  DeepLinkHandlerConfiguration.swift
//  tealium-swift
//
//  Created by Den Guzov on 15/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

struct DeepLinkHandlerConfiguration {
    let deepLinkTraceEnabled: Bool
    let sendDeepLinkEvent: Bool

    enum Keys {
        static let deepLinkTraceEnabled = "deep_link_trace_enabled"
        static let sendDeepLinkEvent = "send_deep_link_event"
    }

    enum Defaults {
        static let deepLinkTraceEnabled: Bool = true
        static let sendDeepLinkEvent: Bool = false
    }

    init(configuration: DataObject) {
        deepLinkTraceEnabled = configuration.get(key: Keys.deepLinkTraceEnabled) ?? Defaults.deepLinkTraceEnabled
        sendDeepLinkEvent = configuration.get(key: Keys.sendDeepLinkEvent) ?? Defaults.sendDeepLinkEvent
    }
}
