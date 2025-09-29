//
//  TrackerImpl.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 26/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

class TrackerImpl: Tracker {
    let modules: ObservableState<[Module]>
    let dispatchManager: DispatchManagerProtocol
    let sessionManager: SessionManager
    let logger: LoggerProtocol?
    let loadRuleEngine: LoadRuleEngine
    init(modules: ObservableState<[Module]>,
         loadRuleEngine: LoadRuleEngine,
         dispatchManager: DispatchManagerProtocol,
         sessionManager: SessionManager,
         logger: LoggerProtocol?) {
        self.modules = modules
        self.loadRuleEngine = loadRuleEngine
        self.dispatchManager = dispatchManager
        self.sessionManager = sessionManager
        self.logger = logger
    }

    func track(_ trackable: Dispatch, source: DispatchContext.Source, onTrackResult: TrackResultCompletion?) {
        guard !dispatchManager.tealiumPurposeExplicitlyBlocked else {
            let trackResult = TrackResult.dropped(trackable, reason: "Tealium consent purpose is explicitly blocked.")
            logger?.debug(category: LogCategory.tealium, trackResult.description)
            onTrackResult?(trackResult)
            return
        }
        let trackingInterval = TealiumSignpostInterval(signposter: .tracking, name: "TrackingCall")
            .begin(trackable.name ?? "unknown")
        logger?.debug(category: LogCategory.tealium, "New tracking event received: \(trackable.logDescription())")
        logger?.trace(category: LogCategory.tealium, "Event data: \(trackable.payload)")
        let dispatchContext = DispatchContext(source: source, initialData: trackable.payload)
        var trackable = trackable
        modules.filter { !$0.isEmpty }
            .subscribeOnce { [weak self] modules in
                guard let self else { return }
                sessionManager.registerDispatch(&trackable)
                modules.compactMap { $0 as? Collector }
                    .filter { self.loadRuleEngine.rulesAllow(dispatch: trackable, forModule: $0) }
                    .forEach { collector in
                        TealiumSignpostInterval(signposter: .tracking, name: "Collecting")
                            .signpostedWork("Collector: \(collector.id)") {
                                trackable.enrich(data: collector.collect(dispatchContext))
                            }
                    }
                self.logger?.debug(category: LogCategory.tealium, "Event: \(trackable.logDescription()) has been enriched by collectors")
                self.logger?.trace(category: LogCategory.tealium, "Enriched event data: \(trackable.payload)")
                self.dispatchManager.track(trackable, onTrackResult: onTrackResult)
                trackingInterval.end()
            }
    }
}
