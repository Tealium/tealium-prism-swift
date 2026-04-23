//
//  AnyObserver.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/// A type-erased wrapper for any `Observer`.
class AnyObserver<Element>: Observer {
    private let observer: any Observer<Element>
    init<O: Observer<Element>>(_ observer: O) {
        self.observer = observer
    }

    func onNext(_ element: Element) {
        observer.onNext(element)
    }

    func onComplete() {
        observer.onComplete()
    }
}
