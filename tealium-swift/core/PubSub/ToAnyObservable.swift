//
//  ToAnyObservable.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 03/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

@propertyWrapper
public final class ToAnyObservable<P: TealiumPublisherProtocol>: TealiumPublisherProtocol {
    public typealias Element = P.Element

    public let publisher: P
    public init(_ anyPublisher: P) {
        self.publisher = anyPublisher
    }

    public var wrappedValue: TealiumObservable<Element> {
        return asObservable()
    }

    public func asObservable() -> TealiumObservable<Element> {
        return publisher.asObservable()
    }

    public func publish(_ element: P.Element) {
        publisher.publish(element)
    }
}
