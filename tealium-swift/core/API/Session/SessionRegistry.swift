//
//  SessionRegistry.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/08/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

public protocol SessionRegistry {
    /**
     * An `Observable` of `Session` update events.
     *
     * There will be an emission each time the session is updated, including:
     *  - the number of events in this session has been updated
     *  - the session status has been updated (started, ended etc)
     */
    var session: Observable<Session> { get }
}
