//
//  IgnoreObservable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

private class IgnoreObserver<Element>: Observer {
    private let downstream: any Observer<Element>
    private let count: Int
    private var current = 0

    init(downstream: any Observer<Element>, count: Int) {
        self.count = count
        self.downstream = downstream
    }

    func onNext(_ element: Element) {
        guard current >= count else { current += 1; return }
        downstream.onNext(element)
    }

    func onComplete() {
        downstream.onComplete()
    }
}

class IgnoreObservable<Element>: Observable<Element> {
    private let source: Observable<Element>
    private let count: Int

    init(source: Observable<Element>, count: Int) {
        self.source = source
        self.count = count
    }

    override func subscribe<O: Observer<Element>>(_ observer: O) -> any Disposable {
        source.subscribeAndLink(
            IgnoreObserver(downstream: observer, count: count)
                .asLinkableObserver()
        )
    }
}
