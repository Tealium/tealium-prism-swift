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
    private let linkable = UpstreamLinkableImpl()

    private(set) var isStopped = false

    var isDisposed: Bool { linkable.isDisposed }

    init(downstream: O) {
        self.downstream = downstream
    }

    func onNext(_ element: Element) {
        guard !isStopped else { return }
        downstream?.onNext(element)
    }

    func onComplete() {
        guard !isStopped else { return }
        isStopped = true
        downstream?.onComplete()
        dispose()
    }

    func setUpstream(_ disposable: any Disposable) {
        linkable.setUpstream(disposable)
    }

    // TODO: Remove after we separate `Disposable` and `CompositeDisposable`
    @discardableResult
    @available(*, deprecated)
    func add(_ disposable: any Disposable) -> Self { self }

    func dispose() {
        isStopped = true
        downstream = nil
        linkable.dispose()
    }
}

extension Observable {
    /// Subscribes a `LinkableObserver` as downstream, then links the resulting upstream disposable back to it.
    @discardableResult
    func subscribeAndLink<L: LinkableObserver>(downstreamSupplier: () -> L) -> L where L.Element == Element {
        let downstream = downstreamSupplier()
        let upstream = subscribe(downstream)
        downstream.setUpstream(upstream)
        return downstream
    }
}

extension Observer {
    func asLinkableObserver() -> some LinkableObserver<Element> {
        DisposableObserver(downstream: self)
    }
}
