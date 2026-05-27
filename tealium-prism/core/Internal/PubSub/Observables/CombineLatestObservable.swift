//
//  CombineLatestObservable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

private class CombineLatestCoordinator<First, Other>: Disposable {
    private var downstream: (any Observer<(First, Other)>)?
    private let container = DisposableContainer()
    private var first: First?
    private var other: Other?
    private var firstCompleted = false
    private var otherCompleted = false

    var isDisposed: Bool { container.isDisposed }

    init(downstream: any Observer<(First, Other)>,
         source: Observable<First>,
         other: Observable<Other>) {
        self.downstream = downstream
        source.subscribe { element in
            guard !self.isDisposed else { return }
            self.first = element
            self.notifyIfReady()
        } onComplete: {
            guard !self.firstCompleted else { return }
            self.firstCompleted = true
            self.completeIfBothDone()
        }.addTo(container)
        other.subscribe { element in
            guard !self.isDisposed else { return }
            self.other = element
            self.notifyIfReady()
        } onComplete: {
            guard !self.otherCompleted else { return }
            self.otherCompleted = true
            self.completeIfBothDone()
        }.addTo(container)
    }

    private func notifyIfReady() {
        if let first, let other {
            downstream?.onNext((first, other))
        }
    }

    var isCompleted: Bool {
        firstCompleted && otherCompleted || first == nil && firstCompleted || other == nil && otherCompleted
    }

    private func completeIfBothDone() {
        guard !isDisposed, isCompleted else { return }
        downstream?.onComplete()
        dispose()
    }

    func dispose() {
        downstream = nil
        container.dispose()
    }
}

class CombineLatestObservable<First, Other>: Observable<(First, Other)> {
    private let source: Observable<First>
    private let other: Observable<Other>

    init(source: Observable<First>, other: Observable<Other>) {
        self.source = source
        self.other = other
    }

    override func subscribe<O: Observer>(_ observer: O) -> any Disposable where O.Element == (First, Other) {
        CombineLatestCoordinator(downstream: observer, source: source, other: other)
    }
}
