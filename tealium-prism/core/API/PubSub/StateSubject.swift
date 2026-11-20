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
 * You can use it as a property wrapper to make the emitting private in the class where it's contained, but still expose an `ObservableState`
 * to the other classes.
 */
@propertyWrapper
public class StateSubject<Element>: Subject<Element> {

    private var _value: Element
    /// The current state. Set a new value to emit an event to all `Observer`s; after the subject has completed, a new
    /// value is ignored.
    public var value: Element {
        get {
            _value
        }
        set {
            self.onNext(newValue)
        }
    }

    /// Creates a state subject with an initial value.
    /// - Parameter initialValue: The initial state value.
    public init(_ initialValue: Element) {
        self._value = initialValue
    }

    /// Emits a new state value to all subscribers and updates the stored state.
    /// After the subject has completed, it is ignored and the stored state does not change.
    /// - Parameter element: The new state value.
    public override func onNext(_ element: Element) {
        guard !isCompleted else { return }
        self._value = element
        super.onNext(element)
    }

    /// Converts this `StateSubject` to an `ObservableState` that is readonly and can only receive new values.
    ///
    /// A new observer first receives the current value. Values emitted into this subject while a new observer
    /// receives the current value reach it afterwards. Subscribing to a completed subject delivers the current value,
    /// then the completion; after completion, new values are ignored.
    public func asObservableState() -> ObservableState<Element> {
        ObservableState<Element>(valueProvider: self.value) { observer in
            self.subscribeThenNotify(ReplayingObserver(downstream: observer),
                                     onAfterSubscribed: { $0.replay(CollectionOfOne(self.value)) })
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
    /// Emits the element only if it differs from the current value.
    func onNextIfChanged(_ element: Element) {
        if element != value {
            onNext(element)
        }
    }
}
