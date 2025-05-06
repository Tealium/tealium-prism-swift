//
//  Tracker.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 20/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * Track result shows whether the dispatch being tracked has been enqueued for further processing or not.
 *
 * The `TealiumDispatch` passed in the enum is the version of the TealiumDispatch that is actually accepted,
 * after collection, transformation and consent.
 */
public enum TrackResult {
    case accepted(_ dispatch: TealiumDispatch)
    case dropped(_ dispatch: TealiumDispatch)
}

/// An object that receives a `TealiumDispatch`, enriches it and sends it to be dispatched.
public protocol Tracker: AnyObject {
    /**
     * Takes a trackable and a source, collects additional data from Collectors, and dispatches the result to the Dispatchers.
     *
     * - note: When this `onTrackResult` callback is called, even when accepted, the `TealiumDispatch` is safely stored to disk but not yet dispatched to the Dispatchers.
     *
     * - Parameters:
     *      - trackable: The `TealiumDispatch` that needs to be tracked.
     *      - source: The `TealiumModule` that generated this track or the application
     *      - onTrackResult: A callback called when the track is either accepted or dropped.
     */
    func track(_ trackable: TealiumDispatch, source: DispatchContext.Source, onTrackResult: TrackResultCompletion?)
}

public extension Tracker {
    func track(_ trackable: TealiumDispatch, source: DispatchContext.Source) {
        track(trackable, source: source, onTrackResult: nil)
    }
}
