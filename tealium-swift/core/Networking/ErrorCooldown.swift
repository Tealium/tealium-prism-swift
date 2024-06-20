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
    let baseInterval: Double
    var maxInterval: Double
    private var lastCallError: Error?
    private var consecutiveErrorsCount = 0

    convenience init?(baseInterval: Double?, maxInterval: Double) {
        guard let baseInterval = baseInterval else {
            return nil
        }
        self.init(baseInterval: baseInterval,
                  maxInterval: maxInterval)
    }

    init(baseInterval: Double, maxInterval: Double) {
        self.baseInterval = baseInterval
        self.maxInterval = maxInterval
    }

    var cooldownInterval: Double {
        return min(maxInterval, baseInterval * Double(consecutiveErrorsCount))
    }

    func isInCooldown(lastFetch: Date) -> Bool {
        guard lastCallError != nil else {
            return false
        }
        guard let cooldownEndDate = lastFetch.addSeconds(cooldownInterval) else {
            return false
        }
        return cooldownEndDate > Date()
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
