//
//  Session.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/08/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/**
 * Model of data required to keep track of the current session.
 *
 * - Parameters:
 *  - status: The status of this session
 *  - sessionId: Unique session id, typically the time in seconds at the time the session started
 *  - lastEventTimeMilliseconds: The time in milliseconds of the latest event of this session.
 *  - eventCount: The number of events that have occurred in this session
 */
public struct Session {
    /// Models the current status of the session.
    public enum Status: String {
        /// Indicates that a new session has been started.
        case started
        /// Indicates that an existing session was resumed.
        case resumed
        /// Indicates that an existing session was ended.
        case ended
    }
    public let status: Status
    public let sessionId: Int64
    public let lastEventTimeMilliseconds: Int64
    public let eventCount: Int

    init(status: Status, sessionId: Int64, lastEventTimeMilliseconds: Int64, eventCount: Int) {
        self.status = status
        self.sessionId = sessionId
        self.lastEventTimeMilliseconds = lastEventTimeMilliseconds
        self.eventCount = eventCount
    }

    init(status: Status, sessionInfo: SessionInfo) {
        self.init(status: status,
                  sessionId: sessionInfo.sessionId,
                  lastEventTimeMilliseconds:
                    sessionInfo.lastEventTimeMilliseconds,
                  eventCount: sessionInfo.eventCount)
    }

    var info: SessionInfo {
        SessionInfo(sessionId: sessionId,
                    lastEventTimeMilliseconds: lastEventTimeMilliseconds,
                    eventCount: eventCount)
    }

    func incrementAndExtend(timestamp: Int64) -> Self {
        Session(status: status,
                sessionId: sessionId,
                lastEventTimeMilliseconds: timestamp,
                eventCount: eventCount + 1)
    }
}
