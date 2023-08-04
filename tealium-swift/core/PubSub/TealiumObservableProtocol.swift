//
//  TealiumObservableProtocol.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 07/02/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// A protocol to provide all publisher-like classes access to a corresponding observable.
public protocol TealiumObservableConvertibleProtocol {
    associatedtype Element

    func asObservable() -> TealiumObservable<Element>
}

/// A protocol to provide all observable-like classes some utilities like subscribeOnce or the operators.
public protocol TealiumObservableProtocol: TealiumObservableConvertibleProtocol {
    typealias Observer = (Element) -> Void

    @discardableResult
    func subscribe(_ observer: @escaping Observer) -> any TealiumDisposable
}

public extension TealiumObservableProtocol {
    /**
     * Subscribes the observer only once and then automatically disposes it.
     *
     * This is meant to be used when you only need one observer to be registered once.
     * Use the standalone `first()` operator if multiple observers all need to register for one event.
     *
     * - returns: a `TealiumDisposable` that can be used to dispose this observer before the first event is sent to the observer, in case it's not needed any longer.
     */
    @discardableResult
    func subscribeOnce(_ observer: @escaping Observer) -> TealiumDisposable {
        first().subscribe(observer)
    }

    func asObservable() -> TealiumObservable<Element> {
        TealiumObservableCreate<Element> { observer in self.subscribe(observer) }
    }
}
