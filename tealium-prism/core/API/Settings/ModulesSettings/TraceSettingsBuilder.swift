//
//  TraceSettingsBuilder.swift
//  tealium-prism
//
//  Created by Den Guzov on 28/11/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// A builder used to enforce `TraceSettings`.
public class TraceSettingsBuilder: CollectorSettingsBuilder {
    typealias Keys = TraceModuleConfiguration.Keys

    /**
     * Set whether to automatically track logged errors during trace sessions.
     *
     * When enabled, the Trace module will automatically capture and send error events
     * that occur while a trace session is active. This is useful for debugging and
     * monitoring application errors in conjunction with trace data.
     *
     * Error events are sent as separate dispatches with the event name "tealium_error"
     * and include an "error_description" field containing the error details.
     *
     * - Parameter trackErrors: `true` to enable automatic error tracking during trace sessions,
     *                         `false` to disable it. Default is `false`.
     * - Returns: The builder instance for method chaining.
     */
    public func setTrackErrors(_ trackErrors: Bool) -> Self {
        _configurationObject.set(trackErrors, key: Keys.trackErrors)
        return self
    }
}
