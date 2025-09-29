//
//  TealiumDispatchGroup.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 27/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A utility class that wraps a `DispatchGroup` and makes safer to use and includes an array of results in the completion.
 *
 * Differently from the `DispatchGroup`, if the first work completes synchronously the completion won't be called until all the other work is completed too.
 * All the results then are collected and returned in the completion.
 */
public class TealiumDispatchGroup {
    let queue: TealiumQueue
    public init(queue: TealiumQueue) {
        self.queue = queue
    }

    public func parallelExecution<Result>(_ works: [(@escaping (Result) -> Void) -> Void], completion: @escaping ([Result]) -> Void) {
        guard works.count > 0 else {
            completion([])
            return
        }
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        var results = [Int: Result]()
        let queue = self.queue
        dispatchGroup.notify(queue: queue.dispatchQueue) {
            completion(results.sorted { $0.key < $1.key }.map { $0.value })
        }
        for (index, work) in works.enumerated() {
            dispatchGroup.enter()
            work { result in
                queue.ensureOnQueue {
                    results[index] = result
                    dispatchGroup.leave()
                }
            }
        }
        dispatchGroup.leave()
    }
}
