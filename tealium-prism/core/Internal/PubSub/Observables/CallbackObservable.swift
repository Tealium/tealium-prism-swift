//
//  CallbackObservable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 29/04/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

private class CallbackObserver<Element>: LinkableObserver {
    private var downstream: (any Observer<Element>)?
    private(set) var isStopped = false
    private let linkable = SingleLinkable()

    var isDisposed: Bool { linkable.isDisposed }

    init(downstream: any Observer<Element>) {
        self.downstream = downstream
    }

    func onNext(_ element: Element) {
        guard !isStopped else { return }
        isStopped = true
        downstream?.onNext(element)
        complete()
    }

    func onComplete() {
        guard !isStopped else { return }
        isStopped = true
        complete()
    }

    private func complete() {
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

/// An `Observable` that runs a block on each subscription, emits a single value through the supplied
/// observer, and auto-completes. The block returns a `Disposable` used to cancel the underlying work
/// if the subscription is disposed before the observer fires.
class CallbackObservable<Element>: Observable<Element> {
    private let block: SubscriptionHandler

    init(_ block: @escaping SubscriptionHandler) {
        self.block = block
    }

    override func subscribe<O: Observer<Element>>(_ observer: O) -> any Disposable {
        let observer = CallbackObserver(downstream: observer)
        let subscription = block(observer)
        observer.link(subscription)
        return observer
    }
}
