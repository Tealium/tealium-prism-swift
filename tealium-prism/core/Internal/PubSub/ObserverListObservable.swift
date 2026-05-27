//
//  ObserverListObservable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 09/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A concrete implementation of `Observable` which holds a list of observers that can be added via the subscribe method and forwards them every event it receives.
 */
class ObserverListObservable<Element>: Observable<Element> {
    private let observerList = DisposableItemList<AnyObserver<Element>>()
    private var isCompleted = false

    override init() {}

    override func subscribe<O: Observer<Element>>(_ observer: O) -> any Disposable {
        guard !isCompleted else {
            observer.onComplete()
            return CompletedDisposable.shared
        }
        return observerList.append(AnyObserver(observer))
    }

    func onNext(_ element: Element) {
        guard !isCompleted else { return }
        for observer in observerList.toArray() {
            observer.onNext(element)
        }
    }

    func onComplete() {
        guard !isCompleted else { return }
        isCompleted = true
        let observers = observerList.toArray()
        observerList.removeAll()
        for observer in observers {
            observer.onComplete()
        }
    }
}
