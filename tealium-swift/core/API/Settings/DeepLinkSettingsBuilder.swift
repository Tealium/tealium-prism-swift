//
//  DeepLinkSettingsBuilder.swift
//  tealium-swift
//
//  Created by Den Guzov on 16/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// A builder used to enforce some of the `DeepLinkHandlerConfiguration` settings.
public class DeepLinkSettingsBuilder: CollectorSettingsBuilder {
    typealias Keys = DeepLinkHandlerConfiguration.Keys
    override init() { }

    /// Enable or disable QR trace functionality.
    /// If set to `false`, trace actions (join, leave, kill visitor session) cannot be fired by `DeepLinkHandler`.
    public func setQrTraceEnabled(_ enabled: Bool) -> Self {
        _configurationObject.set(enabled, key: Keys.qrTraceEnabled)
        return self
    }

    /// Enable or disable sending deep link events.
    /// If set to `true` and deep link tracking is enabled, the handler will additionally track a deep link event on call.
    public func setSendDeepLinkEvent(_ enabled: Bool) -> Self {
        _configurationObject.set(enabled, key: Keys.sendDeepLinkEvent)
        return self
    }
}
