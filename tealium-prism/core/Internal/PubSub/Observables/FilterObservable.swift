//
//  FilterObservable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

private class FilterObserver<Element>: Observer {
    private let downstream: any Observer<Element>
    private let predicate: (Element) -> Bool

    init(downstream: any Observer<Element>, predicate: @escaping (Element) -> Bool) {
        self.predicate = predicate
        self.downstream = downstream
    }

    func onNext(_ element: Element) {
        guard predicate(element) else { return }
        downstream.onNext(element)
    }

    func onComplete() {
        downstream.onComplete()
    }
}

class FilterObservable<Element>: Observable<Element> {
    private let source: Observable<Element>
    private let predicate: (Element) -> Bool

    init(source: Observable<Element>, predicate: @escaping (Element) -> Bool) {
        self.source = source
        self.predicate = predicate
    }

    override func subscribe<O: Observer<Element>>(_ observer: O) -> any Disposable {
        source.subscribeAndLink(
            FilterObserver(downstream: observer, predicate: predicate)
                .asLinkableObserver()
        )
    }
}
