//
//  DisposableObserver.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/// An observer that wraps a downstream `Observer`, guards against events after stopping,
/// and disposes its linked upstream subscription on completion.
class DisposableObserver<O: Observer<Element>, Element>: LinkableObserver {
    private var downstream: O?
    private let linkable = SingleLinkable()

    private(set) var isCompleted = false

    var isDisposed: Bool { linkable.isDisposed }

    init(downstream: O) {
        self.downstream = downstream
    }

    func onNext(_ element: Element) {
        guard !isCompleted && !isDisposed  else { return }
        downstream?.onNext(element)
    }

    func onComplete() {
        guard !isCompleted && !isDisposed else { return }
        isCompleted = true
        downstream?.onComplete()
        dispose()
    }

    func link(_ disposable: any Disposable) {
        linkable.link(disposable)
    }

    func dispose() {
        guard !isDisposed else { return }
        linkable.dispose()
        downstream = nil
    }
}

extension Observable {
    /// Subscribes a `LinkableObserver` as downstream, then links the resulting upstream disposable back to it.
    @discardableResult
    func subscribeAndLink<Downstream: LinkableObserver>(_ observer: Downstream) -> Downstream where Downstream.Element == Element {
        let upstream = subscribe(observer)
        observer.link(upstream)
        return observer
    }
}

extension Observer {
    func asLinkableObserver() -> some LinkableObserver<Element> {
        DisposableObserver(downstream: self)
    }
}
