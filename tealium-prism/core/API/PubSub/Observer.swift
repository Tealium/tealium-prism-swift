//
//  Observer.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/// A protocol representing an observer that can receive elements and a completion signal.
public protocol Observer<Element> {
    associatedtype Element
    /// Called when the upstream source emits a new element.
    func onNext(_ element: Element)
    /// Called when the upstream source has terminated and no further elements will be emitted.
    func onComplete()
}

extension Observer {
    func callAsFunction(_ element: Element) {
        onNext(element)
    }
}
