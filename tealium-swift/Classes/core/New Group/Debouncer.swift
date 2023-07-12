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
class Debouncer: DebouncerProtocol {
    private var timer: TealiumRepeatingTimer?
    private let queue: DispatchQueue
    init(queue: DispatchQueue) {
        self.queue = queue
    }
    
    func debounce(time: TimeInterval, completion: @escaping () -> Void) {
        timer = TealiumRepeatingTimer(timeInterval: time, repeating: .never, dispatchQueue: queue) { [weak self] in
            self?.timer = nil
            completion()
        }
        timer?.resume()
    }
    
    func cancel() {
        timer = nil
    }
}
