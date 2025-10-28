//
//  Publisher.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 03/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

/// A protocol to provide all publisher-like classes some utilities like `publish()` for `Void` events.
public protocol Publisher: ObservableConvertible {
    /// Publishes an element to all subscribers.
    /// - Parameter element: The element to publish.
    func publish(_ element: Element)
}

public extension Publisher where Element == Void {
    /// Just publish a `Void` event.
    func publish() {
        self.publish(())
    }
}
