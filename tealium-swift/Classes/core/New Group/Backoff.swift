//
//  Backoff.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/06/23.
//

import Foundation

/// A policy to backoff based on the attempt number. Useful to understand how much time we should wait before retrying.
protocol BackoffPolicy {
    func backoff(forAttempt number: Int) -> Double
}

/// Calculates the amount of time to backoff exponentially based on the parameters and the attempt number.
class ExponentialBackoff: BackoffPolicy {
    let exponentialBackoffBase: Double
    let exponentialBackoffScale: Double
    let maximumBackoff: Double
    init(exponentialBackoffBase: Double = 2, exponentialBackoffScale: Double = 1, maximumBackoff: Double = 150) {
        self.exponentialBackoffBase = max(exponentialBackoffBase, 2)
        self.exponentialBackoffScale = max(exponentialBackoffScale, 0.01)
        self.maximumBackoff = maximumBackoff
    }
    
    func backoff(forAttempt number: Int) -> Double {
        min(pow(exponentialBackoffBase, Double(max(1, number))) * exponentialBackoffScale, maximumBackoff)
    }
}
