//
//  TakeWhileObservable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

private class TakeWhileObserver<Element>: LinkableObserver {
    private var downstream: (any Observer<Element>)?
    private let predicate: (Element) -> Bool
    private let inclusive: Bool
    private(set) var isStopped = false
    private let linkable = SingleLinkable()

    var isDisposed: Bool { linkable.isDisposed }

    init(downstream: any Observer<Element>, predicate: @escaping (Element) -> Bool, inclusive: Bool) {
        self.downstream = downstream
        self.predicate = predicate
        self.inclusive = inclusive
    }

    func onNext(_ element: Element) {
        guard !isStopped else { return }
        if predicate(element) {
            downstream?.onNext(element)
        } else {
            isStopped = true
            if inclusive { downstream?.onNext(element) }
            downstream?.onComplete()
            dispose()
        }
    }

    func onComplete() {
        guard !isStopped else { return }
        isStopped = true
        downstream?.onComplete()
        dispose()
    }

    func link(_ disposable: any Disposable) { linkable.link(disposable) }

    func dispose() {
        isStopped = true
        downstream = nil
        linkable.dispose()
    }
}

class TakeWhileObservable<Element>: Observable<Element> {
    private let source: Observable<Element>
    private let predicate: (Element) -> Bool
    private let inclusive: Bool

    init(source: Observable<Element>, predicate: @escaping (Element) -> Bool, inclusive: Bool) {
        self.source = source
        self.predicate = predicate
        self.inclusive = inclusive
    }

    override func subscribe<O: Observer<Element>>(_ observer: O) -> any Disposable {
        source.subscribeAndLink(
            TakeWhileObserver(downstream: observer, predicate: predicate, inclusive: inclusive)
        )
    }
}
