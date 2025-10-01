//
//  TrackResult.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 10/07/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/**
 * Track result shows whether the dispatch being tracked has been enqueued for further processing or not along
 * with some relevant information like the `Dispatch` after it's been collected, transformed and consented
 * and some readable info about the status of the dispatch.
 */
public struct TrackResult: CustomStringConvertible {
    /// Informs if the `Dispatch` has been accepted for processing, or dropped.
    public enum Status: CustomStringConvertible {
        case accepted
        case dropped

        public var description: String {
            switch self {
            case .accepted:
                "accepted for processing"
            case .dropped:
                "dropped"
            }
        }
    }
    /// The `Dispatch` after it's been collected, transformed and consented.
    public let dispatch: Dispatch
    /// The status that can be accepted for processing or dropped.
    public let status: Status
    /// Some human readable info regarding the reason behind the status decision.
    public let info: String

    public var description: String {
        "Dispatch \"\(dispatch.logDescription())\" has been \(status). \(info)"
    }

    static func dropped(_ dispatch: Dispatch, reason: String) -> Self {
        TrackResult(dispatch: dispatch, status: .dropped, info: "Reason: " + reason)
    }

    static func accepted(_ dispatch: Dispatch, info: String) -> Self {
        TrackResult(dispatch: dispatch, status: .accepted, info: info)
    }
}
