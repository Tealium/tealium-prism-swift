//
//  DeepLinkSettingsBuilder.swift
//  tealium-swift
//
//  Created by Den Guzov on 16/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// A builder used to enforce some of the `DeepLinkModuleConfiguration` settings.
public class DeepLinkSettingsBuilder: CollectorSettingsBuilder {
    typealias Keys = DeepLinkModuleConfiguration.Keys

    /// Enable or disable using trace from deep links.
    ///
    /// When this is enabled, using the camera to scan the QR code from the QR Trace tool will automatically join the trace.
    /// If set to `false`, trace actions (join, leave, kill visitor session) cannot be fired by `DeepLinkHandler`.
    public func setDeepLinkTraceEnabled(_ enabled: Bool) -> Self {
        _configurationObject.set(enabled, key: Keys.deepLinkTraceEnabled)
        return self
    }

    /// Enable or disable sending deep link events.
    /// If set to `true` and deep link tracking is enabled, the handler will additionally track a deep link event on call.
    public func setSendDeepLinkEvent(_ enabled: Bool) -> Self {
        _configurationObject.set(enabled, key: Keys.sendDeepLinkEvent)
        return self
    }
}
