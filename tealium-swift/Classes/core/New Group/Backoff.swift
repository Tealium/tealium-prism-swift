//
//  Backoff.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/06/23.
//

import Foundation

protocol BackoffPolicy {
    func backoff(forAttempt number: Int) -> Double
}

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
        min(pow(exponentialBackoffBase, Double(number)) * exponentialBackoffScale, maximumBackoff)
    }
}
