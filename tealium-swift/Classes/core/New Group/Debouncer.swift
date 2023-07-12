//
//  Debouncer.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/06/23.
//

import Foundation

protocol DebouncerProtocol {
    func debounce(time: TimeInterval, completion: @escaping () -> Void)
    func cancel()
}

/**
 * A class that delays the exeution of a block of code until the time between debounce calls expires, resetting the timer on each subsequent debounce call.
 */
class Debouncer: DebouncerProtocol {
    private var timer: TealiumRepeatingTimer?
    private let queue: DispatchQueue
    init(queue: DispatchQueue) {
        self.queue = queue
    }
    
    /**
     * Delays the execution of a block until an interval has passed, cancelling previous debounce calls.
     *
     * - Parameters:
     *    - time: the `TimeInterval` that has to be waited without further debounce calls before executing the completion block
     *    - completion: the block that has to be executed once the time has passed
     */
    func debounce(time: TimeInterval, completion: @escaping () -> Void) {
        timer = TealiumRepeatingTimer(timeInterval: time, repeating: .never, dispatchQueue: queue) { [weak self] in
            self?.timer = nil
            completion()
        }
        timer?.resume()
    }
    
    /// Cancel the ongoing timer and prevents the debounced block to be executed.
    func cancel() {
        timer = nil
    }
}
