//
//  TealiumMutableState.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 16/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A wrapper class around a subject that holds a value and publishes all the changes via observables.
 *
 * You can use `asObservable` to receive current value and all updates in a new observable.
 * You can use `updates` to receive only future updates in a new observable.
 * You can use `toObservableState` to create a read only observable State.
 */
@propertyWrapper
public class TealiumMutableState<Element>: TealiumObservableConvertible {
    private let subject: TealiumReplaySubject<Element>
    public var value: Element {
        get {
            // swiftlint:disable force_unwrapping
            subject.last()!
            // swiftlint:enable force_unwrapping
        }
        set {
            subject.publish(newValue)
        }
    }

    public init(_ initialValue: Element) {
        subject = TealiumReplaySubject(initialValue: initialValue)
    }

    /// Returns a read only observable version of this State.
    public func toObservableState() -> TealiumObservableState<Element> {
        TealiumObservableState(mutableState: self)
    }

    /// Returns an observable that emits the current value and all updates of this State.
    public func asObservable() -> TealiumObservable<Element> {
        subject.asObservable()
    }

    /// Returns an observable that emits only new updates of this State.
    public func updates() -> TealiumObservable<Element> {
        asObservable().ignoreFirst()
    }

    public var wrappedValue: TealiumObservableState<Element> {
        toObservableState()
    }

    public var projectedValue: TealiumObservable<Element> {
        asObservable()
    }
}

public extension TealiumMutableState where Element: Equatable {
    /// Only updates the value if the element is different from the current value.
    func mutateIfChanged(_ element: Element) {
        if value != element {
            value = element
        }
    }
}
