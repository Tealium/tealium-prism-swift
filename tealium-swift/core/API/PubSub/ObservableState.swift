//
//  ObservableState.swift
//  tealium-swift
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
public class ObservableState<Element>: CustomObservable<Element> {
    typealias Element = Element
    private let valueProvider: () -> Element
    public var value: Element {
        valueProvider()
    }

    convenience init(variableSubject: StateSubject<Element>) {
        self.init(valueProvider: variableSubject.value) { observer in
            variableSubject.subscribe(observer)
        }
    }

    init(valueProvider: @autoclosure @escaping () -> Element, subscriptionHandler: @escaping SubscriptionHandler) {
        self.valueProvider = valueProvider
        super.init(subscriptionHandler)
    }

    public class func constant(_ value: Element) -> ObservableState<Element> {
        ObservableState<Element>(valueProvider: value) { _ in
            Subscription { }
        }
    }

    /// Returns an observable that emits only new updates of this State.
    public func updates() -> Observable<Element> {
        asObservable().ignoreFirst()
    }
}

extension ObservableState {
    func map<NewElement>(transform: @escaping (Element) -> NewElement) -> ObservableState<NewElement> {
        ObservableState<NewElement>(valueProvider: transform(self.value)) { observer in
            self.subscribe { element in
                observer(transform(element))
            }
        }
    }
}
