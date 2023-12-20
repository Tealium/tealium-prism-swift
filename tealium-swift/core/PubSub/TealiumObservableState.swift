//
//  TealiumObservableState.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 20/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A read only version of a `TealiumMutableState` which holds a value and publishes all the changes via observables.
 *
 * You can use `asObservable` to receive current value and all updates in a new observable.
 * You can use `updates` to receive only future updates in a new observable.
 */
public class TealiumObservableState<Element>: TealiumObservableConvertible {
    private let mutableState: TealiumMutableState<Element>
    private lazy var automaticDisposer = TealiumAutomaticDisposer()
    public var value: Element {
        mutableState.value
    }

    public init(mutableState: TealiumMutableState<Element>) {
        self.mutableState = mutableState
    }

    public init(initialValue: Element, updates: TealiumObservable<Element>) {
        self.mutableState = TealiumMutableState(initialValue)
        updates.subscribe { [weak self] element in
            self?.mutableState.value = element
        }.addTo(automaticDisposer)
    }

    public class func constant(_ value: Element) -> TealiumObservableState<Element> {
        TealiumObservableState<Element>(mutableState: .init(value))
    }

    /// Returns an observable that emits the current value and all updates of this State.
    public func asObservable() -> TealiumObservable<Element> {
        mutableState.asObservable()
    }

    /// Returns an observable that emits only new updates of this State.
    public func updates() -> TealiumObservable<Element> {
        mutableState.updates()
    }
}

public extension TealiumObservableState {
    func map<Result>(_ transform: @escaping (Element) -> Result) -> TealiumObservableState<Result> {
        TealiumObservableState<Result>(initialValue: transform(value),
                                       updates: updates().map(transform))
    }
}
