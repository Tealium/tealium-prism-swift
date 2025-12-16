//
//  Expiry.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 12/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

//TODO: Change how this expiry works. after(Date) needs to be after(milliseconds: Int64). Change Expiry to rawValue Int64 and use the raw value to store in Settings, while still using the expiryTime() to use the Expiry with the DataStore. the after part of the switch will probably change to Date() + milliseconds or something like that.
/// The expiration type of some persisted value.
public enum Expiry: Equatable {
    /// Expires when the session ends.
    case session
    /// Expires when the app restarts.
    case untilRestart
    /// Never expires.
    case forever
    /// Expires after the specified date.
    case after(Date)

    /// Creates an `.after(Date)` expiry with a date that is value unit of time ahead of now.
    static func afterCustom(timeFrame: TimeFrame) -> Expiry {
        .after(timeFrame.afterNow())
    }

    init(timestamp milliseconds: Int64) {
        switch milliseconds {
        case -1:
            self = .forever
        case -2:
            self = .session
        case -3:
            self = .untilRestart
        default:
            self = .after(Date(unixMilliseconds: milliseconds))
        }
    }

    public func expiryTime() -> Int64 {
        switch self {
        case .session:
            return -2
        case .untilRestart:
            return -3
        case .forever:
            return -1
        case .after(let date):
            return date.unixTimeMilliseconds
        }
    }
}
