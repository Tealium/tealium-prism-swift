//
//  Observer.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/// A protocol representing an observer that can receive elements and a completion signal.
///
/// **Contract:**
/// - `onNext(_:)` may be called zero or more times.
/// - `onComplete()` is called at most once, always after all `onNext` calls.
/// - After `onComplete()`, no further `onNext` calls will be made.
/// - `onComplete()` is NOT called upon external disposal — only on natural upstream termination.
public protocol Observer<Element> {
    associatedtype Element
    /// Called when the upstream source emits a new element.
    func onNext(_ element: Element)
    /// Called once when the upstream source has terminated. No further `onNext` calls will follow.
    func onComplete()
}
