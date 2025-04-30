//
//  DeepLinkHandlerConfiguration.swift
//  tealium-swift
//
//  Created by Den Guzov on 15/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

struct DeepLinkHandlerConfiguration {
    let qrTraceEnabled: Bool
    let sendDeepLinkEvent: Bool

    enum Keys {
        static let qrTraceEnabled = "qr_trace_enabled"
        static let sendDeepLinkEvent = "send_deep_link_event"
    }

    enum Defaults {
        static let qrTraceEnabled: Bool = true
        static let sendDeepLinkEvent: Bool = false
    }

    init(configuration: DataObject) {
        qrTraceEnabled = configuration.get(key: Keys.qrTraceEnabled) ?? Defaults.qrTraceEnabled
        sendDeepLinkEvent = configuration.get(key: Keys.sendDeepLinkEvent) ?? Defaults.sendDeepLinkEvent
    }
}
