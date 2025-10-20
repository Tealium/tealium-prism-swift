//
//  ObservableState.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 20/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * An observable that holds the current value as the current state.
 *
 * You can use `updates` to receive only future updates in a new observable.
 */
public class ObservableState<Element>: Observable<Element> {
    typealias Element = Element
    private let valueProvider: () -> Element
    /// The current state of this `Observable`
    public var value: Element {
        valueProvider()
    }

    init(valueProvider: @autoclosure @escaping () -> Element, subscriptionHandler: @escaping SubscriptionHandler) {
        self.valueProvider = valueProvider
        super.init(subscriptionHandler)
    }

    /// Creates an `ObservableState` which can not emit other events, therefore keeping it's value constant.
    public class func constant(_ value: Element) -> ObservableState<Element> {
        ObservableState<Element>(valueProvider: value) { observer in
            observer(value)
            return Disposables.disposed()
        }
    }

    /// Returns an observable that emits only new updates of this State.
    public func updates() -> Observable<Element> {
        asObservable().ignoreFirst()
    }
}

extension ObservableState {
    func mapState<NewElement>(transform: @escaping (Element) -> NewElement) -> ObservableState<NewElement> {
        ObservableState<NewElement>(valueProvider: transform(self.value)) { observer in
            self.subscribe { element in
                observer(transform(element))
            }
        }
    }
}
