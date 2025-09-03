//
//  MockDebouncer.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 13/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumSwift

class MockDebouncer: MockInstantDebouncer {
    let queue: DispatchQueue
    init(queue: DispatchQueue) {
        self.queue = queue
    }
    override func debounce(time: TimeInterval, completion: @escaping () -> Void) {
        queue.async {
            super.debounce(time: time, completion: completion)
        }
    }
}

class MockInstantDebouncer: DebouncerProtocol {
    @ToAnyObservable(BasePublisher())
    var onDebounce: Observable<TimeInterval>
    init() {
    }
    func debounce(time: TimeInterval, completion: @escaping () -> Void) {
        self._onDebounce.publish(time)
        completion()
    }
    func cancel() {}
}
