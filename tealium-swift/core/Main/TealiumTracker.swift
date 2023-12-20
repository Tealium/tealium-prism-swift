//
//  TealiumTracker.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 20/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol Tracker {
    func track(_ trackable: TealiumDispatch)
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
    public func track(_ trackable: TealiumDispatch) {
        let trackingInterval = TealiumSignpostInterval(signposter: .tracking, name: "TrackingCall")
            .begin(trackable.name ?? "unknown")
        logger?.debug?.log(category: TealiumLibraryCategories.tracking, message: "Received new track \(trackable.name ?? "")")
        logger?.trace?.log(category: TealiumLibraryCategories.tracking, message: "Tracked Event \(trackable.eventData)")
        var trackable = trackable
        let modules = self.modulesManager.modules.value
        modules.compactMap { $0 as? Collector }
            .forEach { collector in
                TealiumSignpostInterval(signposter: .collecting, name: "Collecting")
                    .signpostedWork("Collector: \(type(of: collector as TealiumModule).id)") {
                        trackable.enrich(data: collector.data) // collector.collect() maybe?
                    }
            }
        self.logger?.debug?.log(category: TealiumLibraryCategories.tracking, message: "Enriched Event")
        self.logger?.trace?.log(category: TealiumLibraryCategories.tracking, message: "Updated Data \(trackable.eventData)")
        self.dispatchManager.track(trackable)
        self.logger?.debug?.log(category: TealiumLibraryCategories.tracking, message: "Dispatched Event")
        trackingInterval.end()
    }
}
