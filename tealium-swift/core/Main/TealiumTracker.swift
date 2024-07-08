//
//  TealiumTracker.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 20/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * Track result shows whether the dispatch being tracked has been enqueued for further processing (stored by QueueManager) or not.
 * It can be set by either DispatchManager (e.g., dispatch may be dropped by Transformer) or ConsentManager (if consent is applied).
 */
public enum TrackResult {
    case accepted, dropped
}

public protocol Tracker {
    func track(_ trackable: TealiumDispatch)
    func track(_ trackable: TealiumDispatch, onTrackResult: TrackResultCompletion?)
}

public extension Tracker {
    func track(_ trackable: TealiumDispatch) {
        track(trackable, onTrackResult: nil)
    }
}

public class TealiumTracker: Tracker {
    let modulesManager: ModulesManager
    let dispatchManager: DispatchManager
    let logger: TealiumLoggerProvider?
    init(modulesManager: ModulesManager, dispatchManager: DispatchManager, logger: TealiumLoggerProvider? = nil) {
        self.modulesManager = modulesManager
        self.dispatchManager = dispatchManager
        self.logger = logger
    }

    public func track(_ trackable: TealiumDispatch, onTrackResult: TrackResultCompletion?) {
        let trackingInterval = TealiumSignpostInterval(signposter: .tracking, name: "TrackingCall")
            .begin(trackable.name ?? "unknown")
        logger?.debug?.log(category: LogCategory.tealium, message: "New tracking event received: \(trackable.logDescription())")
        logger?.trace?.log(category: LogCategory.tealium, message: "Event data: \(trackable.eventData)")
        var trackable = trackable
        let modules = self.modulesManager.modules.value
        modules.compactMap { $0 as? Collector }
            .forEach { collector in
                TealiumSignpostInterval(signposter: .tracking, name: "Collecting")
                    .signpostedWork("Collector: \(collector.id)") {
                        trackable.enrich(data: collector.data) // collector.collect() maybe?
                    }
            }
        self.logger?.debug?.log(category: LogCategory.tealium, message: "Event: \(trackable.logDescription()) has been enriched by collectors")
        self.logger?.trace?.log(category: LogCategory.tealium, message: "Enriched event data: \(trackable.eventData)")
        self.dispatchManager.track(trackable, onTrackResult: onTrackResult)
        trackingInterval.end()
    }
}
