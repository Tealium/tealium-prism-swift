//
//  TraceManager.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

/**
 * The `TraceManager` is responsible for handling Tealium trace registration.
 *
 * Joining a trace will add the trace id to each event for filtering server side. Users can leave
 * the trace when finished.
 */
public protocol TraceManager {
    /**
     * Joins a Trace for the given `id`. The trace id will be added to all future
     * events that are tracked until either `leave` is called, or the current session expires.
     */
    func join(id: String, _ completion: ErrorHandlingCompletion?)
    /**
     * Leaves the current trace if one has been joined.
     */
    func leave(_ completion: ErrorHandlingCompletion?)
    /**
     * Attempts to kill the visitor session for the current trace.
     * The Trace will remain active until `leave` is called.
     */
    func killVisitorSession(_ completion: ErrorHandlingCompletion?)
}

public extension TraceManager {
    func join(id: String) {
        join(id: id, nil)
    }

    func leave() {
        leave(nil)
    }

    func killVisitorSession() {
        killVisitorSession(nil)
    }
}
