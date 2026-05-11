//
//  SynchronizeLock.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 11/05/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

final class SynchronizeLock: NSLock, @unchecked Sendable {
    func synchronize<T>(_ action: () throws -> T) rethrows -> T {
        lock()
        defer {
            unlock()
        }
        return try action()
    }
}
