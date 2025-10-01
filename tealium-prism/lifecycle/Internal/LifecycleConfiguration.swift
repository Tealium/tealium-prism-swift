//
//  LifecycleConfiguration.swift
//  tealium-prism
//
//  Created by Denis Guzov on 27/08/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

#if lifecycle
import TealiumPrismCore
#endif

struct LifecycleConfiguration {
    /// If this timeout has been exceeded while the app is backgrounded, the next foreground event will be treated as a launch, rather than a wake.
    let sessionTimeoutInMinutes: Int
    /// If disabled, lifecycle calls must be made manually, or lifecycle metrics will be incorrect
    let autoTrackingEnabled: Bool
    /// Allows lifecycle events to be filtered so only specific events get sent from the device. Does not impact generation of lifecycle data, only sending of events.
    let trackedLifecycleEvents: [LifecycleEvent]
    /// If `.lifecycleEventsOnly` is selected, lifecycle data will only be attached to lifecycle events, and not to other tracked events.
    let dataTarget: LifecycleDataTarget

    enum Keys {
        static let sessionTimeoutInMinutes = "session_timeout"
        static let autoTrackingEnabled = "autotracking_enabled"
        static let trackedLifecycleEvents = "tracked_lifecycle_events"
        static let dataTarget = "data_target"
    }
    enum Defaults {
        static let sessionTimeoutInMinutes: Int = 24 * 60
        static let autoTrackingEnabled: Bool = true
        static let trackedLifecycleEvents: [LifecycleEvent] = LifecycleEvent.allCases
        static let dataTarget: LifecycleDataTarget = .lifecycleEventsOnly
    }

    init(configuration: DataObject) {
        sessionTimeoutInMinutes = configuration.get(key: Keys.sessionTimeoutInMinutes) ?? Defaults.sessionTimeoutInMinutes
        autoTrackingEnabled = configuration.get(key: Keys.autoTrackingEnabled) ?? Defaults.autoTrackingEnabled
        trackedLifecycleEvents = configuration.getDataArray(key: Keys.trackedLifecycleEvents)?.compactMap({
            LifecycleEvent(rawValue: $0.get())
        }) ?? Defaults.trackedLifecycleEvents
        dataTarget = LifecycleDataTarget(rawValue: configuration.get(key: Keys.dataTarget)) ?? Defaults.dataTarget
    }
}
