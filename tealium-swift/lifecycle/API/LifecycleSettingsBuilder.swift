//
//  LifecycleSettingsBuilder.swift
//  tealium-swift
//
//  Created by Denis Guzov on 27/08/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

#if lifecycle
import TealiumCore
#endif

public class LifecycleSettingsBuilder: ModuleSettingsBuilder, CollectorSettingsBuilder {
    typealias Keys = LifecycleConfiguration.Keys

    /**
     * - parameter sessionTimeoutInMinutes: If this timeout has been exceeded while the app is backgrounded, the next foreground event will be treated as a launch, rather than a wake.
     *  You can pass -1 for the infinite session duration. Default is 24 * 60 (1 day).
     */
    public func setSessionTimeoutInMinutes(_ sessionTimeoutInMinutes: Int) -> LifecycleSettingsBuilder {
        _configurationObject.set(sessionTimeoutInMinutes, key: Keys.sessionTimeoutInMinutes)
        return self
    }

    /**
     * - parameter autoTrackingEnabled: If it's `false`, lifecycle calls must be made manually, or lifecycle metrics will be incorrect.
     *  If it's `true`, manual tracking calls are discarded. Default is `true`.
     */
    public func setAutoTrackingEnabled(_ autoTrackingEnabled: Bool) -> LifecycleSettingsBuilder {
        _configurationObject.set(autoTrackingEnabled, key: Keys.autoTrackingEnabled)
        return self
    }

    /**
     * - parameter trackedLifecycleEvents: Lifecycle events to be tracked. By default all of them are.
     */
    public func setTrackedLifecycleEvents(_ trackedLifecycleEvents: [LifecycleEvent]) -> LifecycleSettingsBuilder {
        _configurationObject.set(converting: trackedLifecycleEvents, key: Keys.trackedLifecycleEvents)
        return self
    }

    /**
     * - parameter dataTarget: If it's `.lifecycleEventsOnly`, lifecycle data will only be attached to lifecycle events, and not to any others.
     */
    public func setDataTarget(_ dataTarget: LifecycleDataTarget) -> LifecycleSettingsBuilder {
        _configurationObject.set(converting: dataTarget, key: Keys.dataTarget)
        return self
    }
}
