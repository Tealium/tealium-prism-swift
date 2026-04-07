//
//  LazyConstant.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 02/04/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

private enum LazyValue<T> {
    case resolved(T)
    case constructor(() -> T)
}

/**
 * A class (so it can be used within immutable structs) that computes its value lazily,
 * at most once on first access.
 *
 * If embedded in a `Struct`, this will still only compute the value once and the value will be shared for all of the copies of the struct.
 * Since this is not a `Struct`, it is not thread safe to use. You must always compute the value from the same thread.
 */
@propertyWrapper
class LazyConstant<Value> {
    private var value: LazyValue<Value>

    init(wrappedValue constructor: @autoclosure @escaping () -> Value) {
        self.value = .constructor(constructor)
    }

    init(resolved: Value) {
        self.value = .resolved(resolved)
    }

    var wrappedValue: Value {
        switch value {
        case .resolved( let value):
            return value
        case .constructor(let constructor):
            let value = constructor()
            self.value = .resolved(value)
            return value
        }
    }
}
