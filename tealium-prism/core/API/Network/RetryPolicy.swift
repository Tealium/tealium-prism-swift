//
//  RetryPolicy.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/05/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * The policy, returned by a `RequestInterceptor` that the `NetworkClient` should apply on a given `NetworkResponse`.
 */
public enum RetryPolicy {
    /// Do not retry the request.
    case doNotRetry
    /// Retry the request after the specified delay.
    case afterDelay(TimeInterval)
    /// Retry the request after the specified observable emits.
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
    func shouldRetry(onQueue queue: TealiumQueue, afterPolicy completion: @escaping () -> Void) -> Bool {
        switch self {
        case .doNotRetry:
            return false
        case .afterDelay(let timeInterval):
            if timeInterval > 0 {
                queue.dispatchQueue.asyncAfter(deadline: .now() + timeInterval, execute: completion)
            } else {
                queue.ensureOnQueue(completion)
            }
        case .afterEvent(let tealiumObservable):
            _ = tealiumObservable
                .observeOn(queue)
                .asSingle(queue: queue)
                .subscribe(completion)
        }
        return true
    }
}
