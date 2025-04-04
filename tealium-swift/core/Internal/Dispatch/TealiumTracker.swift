//
//  TealiumTracker.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 26/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

class TealiumTracker: Tracker {
    let modules: ObservableState<[TealiumModule]>
    let dispatchManager: DispatchManagerProtocol
    let logger: LoggerProtocol?
    let loadRuleEngine: LoadRuleEngine
    init(modules: ObservableState<[TealiumModule]>, loadRuleEngine: LoadRuleEngine, dispatchManager: DispatchManagerProtocol, logger: LoggerProtocol?) {
        self.modules = modules
        self.loadRuleEngine = loadRuleEngine
        self.dispatchManager = dispatchManager
        self.logger = logger
    }

    func track(_ trackable: TealiumDispatch, source: DispatchContext.Source, onTrackResult: TrackResultCompletion?) {
        let trackingInterval = TealiumSignpostInterval(signposter: .tracking, name: "TrackingCall")
            .begin(trackable.name ?? "unknown")
        logger?.debug(category: LogCategory.tealium, "New tracking event received: \(trackable.logDescription())")
        logger?.trace(category: LogCategory.tealium, "Event data: \(trackable.eventData)")
        let dispatchContext = DispatchContext(source: source, initialData: trackable.eventData)
        var trackable = trackable
        modules.filter { !$0.isEmpty }
            .subscribeOnce { [weak self] modules in
                guard let self else { return }
                modules.compactMap { $0 as? Collector }
                    .filter { self.loadRuleEngine.rulesAllow(dispatch: trackable, forModule: $0) }
                    .forEach { collector in
                        TealiumSignpostInterval(signposter: .tracking, name: "Collecting")
                            .signpostedWork("Collector: \(collector.id)") {
                                trackable.enrich(data: collector.collect(dispatchContext))
                            }
                    }
                self.logger?.debug(category: LogCategory.tealium, "Event: \(trackable.logDescription()) has been enriched by collectors")
                self.logger?.trace(category: LogCategory.tealium, "Enriched event data: \(trackable.eventData)")
                self.dispatchManager.track(trackable, onTrackResult: onTrackResult)
                trackingInterval.end()
            }
    }
}
