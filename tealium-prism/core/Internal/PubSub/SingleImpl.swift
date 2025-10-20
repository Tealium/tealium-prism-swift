//
//  SingleImpl.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 09/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

class SingleImpl<Element>: Single {
    private let subscribable: any Subscribable<Element>
    init(observable: Observable<Element>, queue: TealiumQueue) {
        self.subscribable = observable
            .first()
            .subscribeOn(queue)
    }

    @discardableResult
    func subscribe(_ observer: @escaping Observer) -> any Disposable {
        subscribable.subscribe(observer)
    }
}
