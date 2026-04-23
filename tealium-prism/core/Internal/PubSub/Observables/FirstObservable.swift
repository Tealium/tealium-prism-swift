//
//  FirstObservable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

private class FirstObserver<Element>: LinkableObserver {
    private var downstream: (any Observer<Element>)?
    private let predicate: (Element) -> Bool
    private(set) var isStopped = false
    private let linkable = UpstreamLinkableImpl()

    var isDisposed: Bool { linkable.isDisposed }

    init(downstream: any Observer<Element>, predicate: @escaping (Element) -> Bool) {
        self.downstream = downstream
        self.predicate = predicate
    }

    func onNext(_ element: Element) {
        guard !isStopped, predicate(element) else { return }
        isStopped = true
        downstream?.onNext(element)
        downstream?.onComplete()
        dispose()
    }

    func onComplete() {
        guard !isStopped else { return }
        isStopped = true
        downstream?.onComplete()
        dispose()
    }

    func setUpstream(_ disposable: any Disposable) { linkable.setUpstream(disposable) }

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

class FirstObservable<Element>: Observable<Element> {
    private let source: Observable<Element>
    private let predicate: (Element) -> Bool

    init(source: Observable<Element>, predicate: @escaping (Element) -> Bool) {
        self.source = source
        self.predicate = predicate
    }

    override func subscribe<O: Observer<Element>>(_ observer: O) -> Disposable {
        source.subscribeAndLink {
            FirstObserver(downstream: observer, predicate: predicate)
        }
    }
}
