//
//  RetryPolicy.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 16/05/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * The policy, returned by a `RequestInterceptor` that the `NetworkClient` should apply on a given `NetworkResponse`.
 */
public enum RetryPolicy {
    case doNotRetry
    case afterDelay(TimeInterval)
    case afterEvent(Observable<Void>)

    /**
     * Waits for the `RetryPolicy` and calls the completion, if necessary, and returns a boolean expressing if the policy indicates it needs a retry.
     *
     * - Parameters:
     *    - queue: the `DispatchQueue` onto which call the completion block
     *    - completion: the completion block that is called, if necessary, once the policy has waited long enough
     *
     * - Returns: `true` if the policy indicates it needs a retry, `false` otherwise.
     */
    func shouldRetry(onQueue queue: DispatchQueue, afterPolicy completion: @escaping () -> Void) -> Bool {
        switch self {
        case .doNotRetry:
            return false
        case .afterDelay(let timeInterval):
            queue.asyncAfter(deadline: .now() + timeInterval, execute: completion)
        case .afterEvent(let tealiumObservable):
            tealiumObservable
                .subscribeOn(queue)
                .observeOn(queue)
                .subscribeOnce(completion)
        }
        return true
    }
}
