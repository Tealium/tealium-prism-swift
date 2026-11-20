//
//  ReplayingObserver.swift
//  tealium-prism
//
//  Created by Luca Looz on 04/11/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/// An observer that `ReplaySubject` and `StateSubject` register in place of a new observer, so that events emitted
/// during the new observer's replay reach it after the replayed values.
///
/// While `replay(_:)` runs, the values and the completion that reach this observer are buffered and delivered after
/// the replayed values, the completion last; events emitted while the buffer drains are buffered too. Otherwise
/// events are forwarded directly.
///
/// Like the rest of the pub/sub system, it is not thread-safe: use it from the subject's queue.
final class ReplayingObserver<Element>: Observer {
    private let downstream: any Observer<Element>
    private var isBuffering = false
    private var buffer = [Element]()
    private var completionBuffered = false

    init(downstream: any Observer<Element>) {
        self.downstream = downstream
    }

    func onNext(_ element: Element) {
        if isBuffering {
            buffer.append(element)
        } else {
            downstream.onNext(element)
        }
    }

    func onComplete() {
        if isBuffering {
            completionBuffered = true
        } else {
            downstream.onComplete()
        }
    }

    /// Delivers `values`, then everything buffered meanwhile, then a buffered completion.
    ///
    /// Call it once: right after subscribing this observer to the subject, or, on a completed subject, without
    /// subscribing it.
    func replay<Values: Sequence>(_ values: Values) where Values.Element == Element {
        isBuffering = true
        for value in values {
            downstream.onNext(value)
        }
        while !buffer.isEmpty {
            let batch = buffer
            buffer = []
            for value in batch {
                downstream.onNext(value)
            }
        }
        isBuffering = false
        if completionBuffered {
            completionBuffered = false
            downstream.onComplete()
        }
    }
}
