//
//  SynchronizeLock.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 11/05/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/// A lock that allows to synchronize blocks of code.
/// It derives from an `NSRecursiveLock` to avoid deadlocks in case of reentrancy.
final class SynchronizeLock: NSRecursiveLock, @unchecked Sendable {
    func synchronize<T>(_ action: () throws -> T) rethrows -> T {
        lock()
        defer {
            unlock()
        }
        return try action()
    }
}
