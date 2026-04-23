//
//  FlatMapObservable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

private class FlatMapObserver<Element, Result>: Observer {
    private let downstream: any Observer<Result>
    private let transform: (Element) -> Observable<Result>
    private let container: DisposableContainer
    private var activeInnerCount = 0
    private var upstreamCompleted = false

    init(downstream: any Observer<Result>,
         transform: @escaping (Element) -> Observable<Result>,
         container: DisposableContainer) {
        self.downstream = downstream
        self.transform = transform
        self.container = container
    }

    func onNext(_ element: Element) {
        // TODO: Phase 5 — inner subscriptions should self-remove from container on complete (UnsubscribingObserver)
        guard !upstreamCompleted else { return }
        activeInnerCount += 1
        transform(element).subscribe { [downstream] value in
            downstream.onNext(value)
        } onComplete: {
            self.activeInnerCount -= 1
            self.maybeComplete()
        }.addTo(container)
    }

    func onComplete() {
        guard !upstreamCompleted else { return }
        upstreamCompleted = true
        maybeComplete()
    }

    private func maybeComplete() {
        guard upstreamCompleted && activeInnerCount == 0 else {
            return
        }
        downstream.onComplete()
        container.dispose()
    }
}

class FlatMapObservable<Element, Result>: Observable<Result> {
    private let source: Observable<Element>
    private let transform: (Element) -> Observable<Result>

    init(source: Observable<Element>, transform: @escaping (Element) -> Observable<Result>) {
        self.source = source
        self.transform = transform
    }

    override func subscribe<O: Observer>(_ observer: O) -> Disposable where O.Element == Result {
        let container = DisposableContainer()
        let observer = FlatMapObserver(downstream: observer, transform: transform, container: container)
        source.subscribe(observer).addTo(container)
        return container
    }
}
