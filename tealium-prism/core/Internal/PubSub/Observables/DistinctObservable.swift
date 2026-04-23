//
//  DistinctObservable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

private class DistinctObserver<Element>: Observer {
    private let downstream: any Observer<Element>
    private let isEqual: (Element, Element) -> Bool
    private var lastElement: Element?

    init(downstream: any Observer<Element>, isEqual: @escaping (Element, Element) -> Bool) {
        self.isEqual = isEqual
        self.downstream = downstream
    }

    func onNext(_ element: Element) {
        let isDistinct = lastElement.map { !isEqual($0, element) } ?? true
        lastElement = element
        if isDistinct { downstream.onNext(element) }
    }

    func onComplete() {
        downstream.onComplete()
    }
}

class DistinctObservable<Element>: Observable<Element> {
    private let source: Observable<Element>
    private let isEqual: (Element, Element) -> Bool

    init(source: Observable<Element>, isEqual: @escaping (Element, Element) -> Bool) {
        self.source = source
        self.isEqual = isEqual
    }

    override func subscribe<O: Observer<Element>>(_ observer: O) -> Disposable {
        source.subscribeAndLink {
            DistinctObserver(downstream: observer, isEqual: isEqual)
                .asLinkableObserver()
        }
    }
}
