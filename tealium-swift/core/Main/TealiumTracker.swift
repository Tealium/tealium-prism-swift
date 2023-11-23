//
//  TealiumTracker.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 20/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public class TealiumTracker {
    let modulesManager: ModulesManager
    let logger: TealiumLoggerProvider?
    init(modulesManager: ModulesManager, logger: TealiumLoggerProvider? = nil) {
        self.modulesManager = modulesManager
        self.logger = logger
    }
    public func track(_ trackable: TealiumDispatch) {
        let trackingInterval = TealiumSignpostInterval(signposter: .tracking, name: "TrackingCall")
            .begin(trackable.name ?? "unknown")
        logger?.debug?.log(category: TealiumLibraryCategories.tracking, message: "Received new track")
        logger?.trace?.log(category: TealiumLibraryCategories.tracking, message: "Tracked Event \(trackable.eventData)")
        tealiumQueue.async {
            var trackable = trackable
            let modules = self.modulesManager.modules
            modules.compactMap { $0 as? Collector }
                .forEach { collector in
                    TealiumSignpostInterval(signposter: .collecting, name: "Collecting")
                        .signpostedWork("Collector: \(type(of: collector as TealiumModule).id)") {
                            trackable.enrich(data: collector.data) // collector.collect() maybe?
                        }
                }
            self.logger?.debug?.log(category: TealiumLibraryCategories.tracking, message: "Enriched Event")
            self.logger?.trace?.log(category: TealiumLibraryCategories.tracking, message: "Updated Data \(trackable.eventData)")

            // dispatch barriers
            // queueing
            // batching
            // transform the data
            modules.compactMap { $0 as? Dispatcher }
                .forEach { dispatcher in
                    TealiumSignpostInterval(signposter: .dispatching, name: "Dispatching")
                        .signpostedWork("Dispatcher: \(type(of: dispatcher as TealiumModule).id)") {
                            dispatcher.dispatch([trackable]) { _ in

                            }
                        }
                }
            self.logger?.debug?.log(category: TealiumLibraryCategories.tracking, message: "Dispatched Event")
            trackingInterval.end()
        }
    }
}
