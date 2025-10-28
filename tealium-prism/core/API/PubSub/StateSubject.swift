//
//  StateSubject.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A `Subject` that must always have a value.
 *
 * You can use it as a property wrapper to make the publishing private in the class where it's contained, but still expose an `ObservableState`
 * to the other classes.
 */
@propertyWrapper
public class StateSubject<Element>: Subject<Element> {

    private var _value: Element
    /// The current state. Set a new value to publish an event to all `Observer`s
    public var value: Element {
        get {
            _value
        }
        set {
            self.publish(newValue)
        }
    }

    /// Creates a state subject with an initial value.
    /// - Parameter initialValue: The initial state value.
    public init(_ initialValue: Element) {
        self._value = initialValue
    }

    /// Publishes a new state value.
    /// - Parameter element: The new state value.
    public override func publish(_ element: Element) {
        self._value = element
        super.publish(element)
    }

    /// Converts this `StateSubject` to an `ObservableState` that is readonly and can only receive new values.
    public func asObservableState() -> ObservableState<Element> {
        ObservableState<Element>(valueProvider: self.value) { observer in
            defer { observer(self.value) }
            return super.asObservable().subscribe(observer)
        }
    }

    /// Returns an observable that emits only new updates of this State.
    public func updates() -> Observable<Element> {
        asObservable().ignoreFirst()
    }

    /// Returns this state subject as an observable.
    public override func asObservable() -> Observable<Element> {
        asObservableState()
    }

    /// The wrapped observable state value for property wrapper usage.
    public override var wrappedValue: ObservableState<Element> {
        asObservableState()
    }
}

public extension StateSubject where Element: Equatable {
    /// Publishes the new event only if the new one is different from the last one
    func publishIfChanged(_ element: Element) {
        if element != value {
            publish(element)
        }
    }
}
