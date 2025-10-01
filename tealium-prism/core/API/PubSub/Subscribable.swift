//
//  Subscribable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 07/02/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// A protocol to provide all publisher-like classes access to a corresponding observable.
public protocol ObservableConvertible<Element> {
    associatedtype Element

    func asObservable() -> Observable<Element>
}

/// A protocol to provide all observable-like classes some utilities like subscribeOnce or the operators.
public protocol Subscribable<Element>: ObservableConvertible {
    typealias Observer = (Element) -> Void

    func subscribe(_ observer: @escaping Observer) -> any Disposable
}

public extension Subscribable {
    func asObservable() -> Observable<Element> {
        CustomObservable<Element> { observer in self.subscribe(observer) }
    }

    /// Subscribe a `Subject` to this `Subscribable`.
    func subscribe<S: Subject>(_ subject: S) -> any Disposable where S.Element == Element {
        subscribe { element in
            subject.publish(element)
        }
    }
}
