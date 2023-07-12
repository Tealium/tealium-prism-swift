//
//  MockInstantDebouncer.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 13/06/23.
//  Copyright © 2023 CocoaPods. All rights reserved.
//

import Foundation
@testable import tealium_swift

class MockInstantDebouncer: DebouncerProtocol {
    let queue: DispatchQueue
    init(queue: DispatchQueue) {
        self.queue = queue
    }
    func debounce(time: TimeInterval, completion: @escaping () -> Void) {
        queue.async {
            completion()
        }
    }
    func cancel() {}
}
