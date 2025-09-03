//
//  ErrorCooldown.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/06/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/// An object that increases a cooldown for every error event, and resets the cooldown to 0 when a non-error event happens.
public class ErrorCooldown {
    let baseInterval: TimeFrame
    var maxInterval: TimeFrame
    private var lastCallError: Error?
    private var consecutiveErrorsCount: Int64 = 0

    convenience init?(baseInterval: TimeFrame?, maxInterval: TimeFrame) {
        guard let baseInterval = baseInterval else {
            return nil
        }
        self.init(baseInterval: baseInterval,
                  maxInterval: maxInterval)
    }

    init(baseInterval: TimeFrame, maxInterval: TimeFrame) {
        self.baseInterval = baseInterval
        self.maxInterval = maxInterval
    }

    var cooldownInterval: TimeFrame {
        return min(maxInterval, TimeFrame(unit: baseInterval.unit, interval: baseInterval.interval * consecutiveErrorsCount))
    }

    func isInCooldown(lastFetch: Date) -> Bool {
        guard lastCallError != nil else {
            return false
        }
        return cooldownInterval.after(date: lastFetch) > Date()
    }

    func newCooldownEvent(error: Error?) {
        if let _ = error {
            consecutiveErrorsCount += 1
        } else {
            consecutiveErrorsCount = 0
        }
        lastCallError = error
    }
}
