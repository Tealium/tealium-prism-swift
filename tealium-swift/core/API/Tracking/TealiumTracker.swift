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

public protocol Tracker: AnyObject {
    func track(_ trackable: TealiumDispatch, source: DispatchContext.Source)
    func track(_ trackable: TealiumDispatch, source: DispatchContext.Source, onTrackResult: TrackResultCompletion?)
}

public extension Tracker {
    func track(_ trackable: TealiumDispatch, source: DispatchContext.Source) {
        track(trackable, source: source, onTrackResult: nil)
    }
}

public class TealiumTracker: Tracker {
    let modules: ObservableState<[TealiumModule]>
    let dispatchManager: DispatchManager
    let logger: LoggerProtocol?
    init(modules: ObservableState<[TealiumModule]>, dispatchManager: DispatchManager, logger: LoggerProtocol?) {
        self.modules = modules
        self.dispatchManager = dispatchManager
        self.logger = logger
    }

    public func track(_ trackable: TealiumDispatch, source: DispatchContext.Source, onTrackResult: TrackResultCompletion?) {
        let trackingInterval = TealiumSignpostInterval(signposter: .tracking, name: "TrackingCall")
            .begin(trackable.name ?? "unknown")
        logger?.debug(category: LogCategory.tealium, "New tracking event received: \(trackable.logDescription())")
        logger?.trace(category: LogCategory.tealium, "Event data: \(trackable.eventData)")
        var trackable = trackable
        modules.filter { !$0.isEmpty }
            .subscribeOnce { [weak self] modules in
                guard let self else { return }
                modules.compactMap { $0 as? Collector }
                    .forEach { collector in
                        TealiumSignpostInterval(signposter: .tracking, name: "Collecting")
                            .signpostedWork("Collector: \(collector.id)") {
                                let dispatchContext = DispatchContext(source: source, initialData: trackable.eventData)
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

public struct DispatchContext {
    public enum Source {
        case application
        case module(TealiumModule.Type)

        var moduleType: TealiumModule.Type? {
            switch self {
            case .application:
                nil
            case .module(let type):
                type
            }
        }
    }
    public let source: Source
    public let initialData: DataObject
}
