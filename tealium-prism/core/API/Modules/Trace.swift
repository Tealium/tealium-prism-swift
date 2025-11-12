//
//  Trace.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 12/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

/**
 * The `Trace` is responsible for handling Tealium trace registration.
 *
 * Joining a trace will add the trace id to each event for filtering server side. Users can leave
 * the trace when finished.
 */
public protocol Trace {
    /**
     * Joins a Trace for the given `id`. The trace id will be added to all future
     * events that are tracked until either `leave` is called, or the current session expires.
     */
    @discardableResult
    func join(id: String) -> SingleResult<Void, ModuleError<Error>>

    /**
     * Leaves the current trace if one has been joined.
     */
    @discardableResult
    func leave() -> SingleResult<Void, ModuleError<Error>>

    /**
     * Attempts to kill the visitor session for the current trace.
     *
     * The trace will remain active until `leave` is called.
     *
     * The operation will fail in case a trace is not already joined.
     *
     * Internally this method will dispatch a track call that will be used to manually kill the session.
     * When this method completes with success, the track can either be accepted or dropped, as all other track requests.
     *
     * The track request will leave the device after it's been accepted, following standard dequeueing flows.
     */
    @discardableResult
    func killVisitorSession() -> SingleResult<TrackResult, ModuleError<Error>>
}
