//
//  RetryPolicy.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 16/05/23.
//

import Foundation

public enum RetryPolicy {
    case doNotRetry
    case afterDelay(TimeInterval)
    case afterEvent(TealiumObservable<Void>)
    
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
