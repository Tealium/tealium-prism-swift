//
//  Expiry.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

/// The expiration type of some persisted value
public enum Expiry: Equatable {
    case session
    case untilRestart
    case forever
    case after(Date)

    /// Creates an `.after(Date)` expiry with a date that is value unit of time ahead of now.
    static func afterCustom(timeFrame: TimeFrame) -> Expiry {
        guard let date = timeFrame.dateAfter() else {
            return .forever
        }
        return .after(date)
    }

    init(timestamp milliseconds: Int64) {
        switch milliseconds {
        case -2:
            self = .session
        case -3:
            self = .untilRestart
        case -1:
            self = .forever
        default:
            self = .after(Date(unixMilliseconds: milliseconds))
        }
    }

    func expiryTime() -> Int64 {
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
