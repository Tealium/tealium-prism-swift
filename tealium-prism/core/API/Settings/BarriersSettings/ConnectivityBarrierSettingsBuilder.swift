//
//  ConnectivityBarrierSettingsBuilder.swift
//  tealium-prism
//
//  Created by Den Guzov on 09/12/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// A builder used to configure the `ConnectivityBarrier` settings.
public class ConnectivityBarrierSettingsBuilder: BarrierSettingsBuilder {
    typealias Keys = ConnectivityBarrierConfiguration.Keys

    /// Set whether to restrict dispatching to WiFi connections only.
    /// When enabled, dispatches will be blocked when only cellular connection is available.
    /// - Parameter wifiOnly: Whether to allow only WiFi connections. Default is false.
    /// - Returns: The builder instance for method chaining.
    public func setWifiOnly(_ wifiOnly: Bool) -> Self {
        _configurationObject.set(wifiOnly, key: Keys.wifiOnly)
        return self
    }
}
