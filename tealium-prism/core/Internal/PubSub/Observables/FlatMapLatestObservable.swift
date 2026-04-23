//
//  FlatMapLatestObservable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

private class FlatMapLatestObserver<Element, Result>: Observer {
    private let downstream: any Observer<Result>
    private let transform: (Element) -> Observable<Result>
    private let container: DisposableContainer
    private var subscription: (any Disposable)?
    private var isSubscribing = false
    private var latestElement: Element?
    private var upstreamCompleted = false
    private var innerCompleted = false

    init(downstream: any Observer<Result>,
         transform: @escaping (Element) -> Observable<Result>,
         container: DisposableContainer) {
        self.downstream = downstream
        self.transform = transform
        self.container = container
    }

    func onNext(_ element: Element) {
        latestElement = element
        guard !isSubscribing else { return }
        isSubscribing = true
        while let element = latestElement {
            latestElement = nil
            subscription?.dispose()
            // TODO: Phase 5 — container.remove(old subscription) before replacing
            innerCompleted = false
            subscription = transform(element).subscribe { [downstream] value in
                downstream.onNext(value)
            } onComplete: {
                self.innerCompleted = true
                if self.upstreamCompleted {
                    self.downstream.onComplete()
                    self.container.dispose()
                }
            }
        }
        subscription?.addTo(container)
        isSubscribing = false
    }

    func onComplete() {
        guard !upstreamCompleted else { return }
        upstreamCompleted = true
        if subscription == nil || innerCompleted {
            downstream.onComplete()
            container.dispose()
        }
    }
}

class FlatMapLatestObservable<Element, Result>: Observable<Result> {
    private let source: Observable<Element>
    private let transform: (Element) -> Observable<Result>

    init(source: Observable<Element>, transform: @escaping (Element) -> Observable<Result>) {
        self.source = source
        self.transform = transform
    }

    override func subscribe<O: Observer>(_ observer: O) -> Disposable where O.Element == Result {
        let container = DisposableContainer()
        let observer = FlatMapLatestObserver(downstream: observer, transform: transform, container: container)
        source.subscribe(observer).addTo(container)
        return container
    }
}
