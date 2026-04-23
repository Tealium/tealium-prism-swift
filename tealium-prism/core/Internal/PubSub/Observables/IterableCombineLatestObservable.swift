//
//  IterableCombineLatestObservable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

private class IterableCombineLatestCoordinator<Element>: Disposable {
    private var downstream: (any Observer<[Element]>)?
    private let container = DisposableContainer()
    private let count: Int
    private var latestValues: [Element?]
    private var resultArray = [Element]()
    private var completedFlags: [Bool]

    var isDisposed: Bool { container.isDisposed }

    init(downstream: any Observer<[Element]>, observables: [Observable<Element>]) {
        self.downstream = downstream
        self.count = observables.count
        self.latestValues = [Element?](repeating: nil, count: observables.count)
        self.completedFlags = [Bool](repeating: false, count: observables.count)
        for index in 0 ..< observables.count {
            observables[index].subscribe { element in
                self.onNext(element: element, index: index)
            } onComplete: {
                self.onComplete(index: index)
            }.addTo(container)
        }
    }

    private func onNext(element: Element, index: Int) {
        guard !isDisposed else { return }
        if resultArray.isEmpty {
            latestValues[index] = element
            let filled = latestValues.compactMap { $0 }
            if filled.count == count {
                resultArray = filled
                latestValues = []
            }
        } else {
            resultArray[index] = element
        }
        if resultArray.count == count {
            downstream?.onNext(resultArray)
        }
    }

    private func onComplete(index: Int) {
        guard !completedFlags[index] else { return }
        completedFlags[index] = true
        if completedFlags.allSatisfy({ $0 }) {
            downstream?.onComplete()
            dispose()
        }
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

class IterableCombineLatestObservable<Element>: Observable<[Element]> {
    private let observables: [Observable<Element>]

    init(observables: [Observable<Element>]) {
        self.observables = observables
    }

    override func subscribe<O: Observer>(_ observer: O) -> Disposable where O.Element == [Element] {
        guard !observables.isEmpty else {
            observer.onNext([])
            observer.onComplete()
            return Disposables.disposed()
        }
        return IterableCombineLatestCoordinator(downstream: observer, observables: observables)
    }
}
