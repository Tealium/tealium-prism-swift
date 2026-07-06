//
//  UnsubscribingObserver.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 13/05/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

/// An observer that self-removes from its owning `CompositeDisposable` upon completion or disposal.
/// Used by `flatMap`/`flatMapLatest`/`resubscribingWhile` so completed inner-observable disposables don't accumulate in the container.
class UnsubscribingObserver<Element>: LinkableObserver {
    private let owner: any CompositeDisposable
    private var delegate: (any Observer<Element>)?
    private let linkable = SingleLinkable()

    var isDisposed: Bool { linkable.isDisposed }

    init(owner: any CompositeDisposable, delegate: any Observer<Element>) {
        self.owner = owner
        self.delegate = delegate
    }

    func onNext(_ element: Element) {
        guard !isDisposed else { return }
        delegate?.onNext(element)
    }

    func onComplete() {
        guard !isDisposed, let delegate else { return }
        self.delegate = nil
        delegate.onComplete()
        dispose()
    }

    func link(_ disposable: any Disposable) {
        linkable.link(disposable)
    }

    func dispose() {
        guard !isDisposed else { return }
        delegate = nil
        linkable.dispose()
        owner.remove(self)
    }
}
