//
//  TealiumVariableSubject.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 16/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

@propertyWrapper
public class TealiumVariableSubject<Element>: TealiumReplaySubject<Element> {

    public var value: Element {
        get {
            // swiftlint:disable force_unwrapping
            last()!
            // swiftlint:enable force_unwrapping
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

    public func toStatefulObservable() -> TealiumStatefulObservable<Element> {
        TealiumStatefulObservable<Element>(variableSubject: self)
    }

    /// Returns an observable that emits only new updates of this State.
    public func updates() -> TealiumObservable<Element> {
        asObservable().ignoreFirst()
    }

    public var wrappedValue: TealiumStatefulObservable<Element> {
        toStatefulObservable()
    }
}
