//
//  ResubscribingWhileObservable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

private class ResubscribingWhileCoordinator<Element>: Disposable {
    private var downstream: (any Observer<Element>)?
    private let source: Observable<Element>
    private let predicate: (Element) -> Bool
    private let container = DisposableContainer()

    var isDisposed: Bool { container.isDisposed }

    init(downstream: any Observer<Element>,
         source: Observable<Element>,
         predicate: @escaping (Element) -> Bool) {
        self.downstream = downstream
        self.source = source
        self.predicate = predicate
        subscribeOnce()
    }

    private func subscribeOnce() {
        // Per-call flag: first() fires onNext+onComplete on match; emitted=false means upstream ended without matching.
        var emitted = false
        source.first().subscribe { element in
            emitted = true
            self.handleElement(element)
        } onComplete: {
            if !emitted {
                self.handleUpstreamCompleted()
            }
        }.addTo(container)
    }

    private func handleElement(_ element: Element) {
        guard !isDisposed else { return }
        downstream?.onNext(element)
        if predicate(element) {
            subscribeOnce()
        } else {
            downstream?.onComplete()
            dispose()
        }
    }

    private func handleUpstreamCompleted() {
        guard !isDisposed else { return }
        downstream?.onComplete()
        dispose()
    }

    @discardableResult
    func add(_ disposable: any Disposable) -> Self {
        container.add(disposable)
        return self
    }

    func dispose() {
        downstream = nil
        container.dispose()
    }
}

class ResubscribingWhileObservable<Element>: Observable<Element> {
    private let source: Observable<Element>
    private let predicate: (Element) -> Bool

    init(source: Observable<Element>, predicate: @escaping (Element) -> Bool) {
        self.source = source
        self.predicate = predicate
    }

    override func subscribe<O: Observer<Element>>(_ observer: O) -> Disposable {
        ResubscribingWhileCoordinator(downstream: observer, source: source, predicate: predicate)
    }
}
