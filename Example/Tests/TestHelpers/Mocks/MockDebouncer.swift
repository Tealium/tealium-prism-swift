//
//  MockDebouncer.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 13/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumSwift

class MockDebouncer: DebouncerProtocol {
    let queue: DispatchQueue
    @ToAnyObservable(BasePublisher())
    var onDebounce: Observable<TimeInterval>
    init(queue: DispatchQueue) {
        self.queue = queue
    }
    func debounce(time: TimeInterval, completion: @escaping () -> Void) {
        queue.async {
            self._onDebounce.publish(time)
            completion()
        }
    }
    func cancel() {}
}
