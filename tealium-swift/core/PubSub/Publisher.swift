//
//  Publisher.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 03/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

/// A protocol to provide all publisher-like classes some utilities like `publish()` for `Void` events.
public protocol Publisher: ObservableConvertible {
    func publish(_ element: Element)
}

public extension Publisher where Element == Void {
    /// Just publish a `Void` event.
    func publish() {
        self.publish(())
    }
}
