//
//  SubscriptionRetainCycleHelper.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 14/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumPrism

/// Duplicated extension to provide asObservable utility to tests.
extension Subscribable {
    /// Not thread safe to chain operators on the `Observable` returned by this method, when it's used on Single or the object returned from `subscribeOn`.
    /// Use only when the `queue` passed to `Single` or `subscribeOn` is the same as the one in which we are actually subscribing.
    func asObservable() -> Observable<Element> {
        Observables.create { observer in self.subscribe(observer) }
    }
}

class SubscriptionRetainCycleHelper<P: Subscribable>: DeinitTester {

    let anyPublisher: P
    var subscription: Disposable?

    init(publisher: P, onDeinit: @escaping () -> Void) {
        self.anyPublisher = publisher
        super.init(onDeinit: onDeinit)
        self.subscription = publisher.subscribe { _ in
            print(self)
        }
    }
}
