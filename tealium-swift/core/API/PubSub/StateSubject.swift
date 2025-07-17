//
//  StateSubject.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 16/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

@propertyWrapper
public class StateSubject<Element>: ReplaySubject<Element> {

    public var value: Element {
        get {
            last()! // swiftlint:disable:this force_unwrapping
        }
        set {
            self.publish(newValue)
        }
    }

    public init(_ initialValue: Element) {
        super.init(cacheSize: 1)
        self.publish(initialValue)
    }

    override public func clear() {
        // Do nothing, can't clear this
    }

    public func toStatefulObservable() -> ObservableState<Element> {
        ObservableState<Element>(variableSubject: self)
    }

    /// Returns an observable that emits only new updates of this State.
    public func updates() -> Observable<Element> {
        asObservable().ignoreFirst()
    }

    public var wrappedValue: ObservableState<Element> {
        toStatefulObservable()
    }
}
