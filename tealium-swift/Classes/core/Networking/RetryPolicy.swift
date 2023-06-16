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
    
    var delayPolicy: DelayPolicy {
        switch self {
        case .doNotRetry:
            return .doNotDelay
        case .afterDelay(let time):
            return .afterDelay(time)
        case .afterEvent(let event):
            return .afterEvent(event)
        }
    }
    
    func shouldRetry(onQueue queue: DispatchQueue, afterPolicy completion: @escaping () -> Void) -> Bool {
        delayPolicy.shouldDelay(onQueue: queue, afterPolicy: completion)
    }
}

public enum DelayPolicy {
    case doNotDelay
    case afterDelay(TimeInterval)
    case afterEvent(TealiumObservable<Void>)
    
    func shouldDelay(onQueue queue: DispatchQueue, afterPolicy completion: @escaping () -> Void) -> Bool {
        switch self {
        case .doNotDelay:
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
