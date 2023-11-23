//
//  SubscriptionRetainCycleHelper.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 14/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumSwift

class SubscriptionRetainCycleHelper<P: TealiumObservableConvertible>: DeinitTester {

    let anyPublisher: P
    var subscription: TealiumDisposable?

    init(publisher: P, onDeinit: @escaping () -> Void) {
        self.anyPublisher = publisher
        super.init(onDeinit: onDeinit)
        self.subscription = publisher.asObservable().subscribe { _ in
            print(self)
        }
    }
}
