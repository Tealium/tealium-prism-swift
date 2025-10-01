//
//  SubscriptionRetainCycleHelper.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 14/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumPrism

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
