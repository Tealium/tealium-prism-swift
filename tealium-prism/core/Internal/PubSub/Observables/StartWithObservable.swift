//
//  StartWithObservable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

private class StartWithObserver<Element>: Observer {
    private let downstream: any Observer<Element>

    init(downstream: any Observer<Element>, elements: [Element]) {
        self.downstream = downstream
        for element in elements { downstream.onNext(element) }
    }

    func onNext(_ element: Element) {
        downstream.onNext(element)
    }

    func onComplete() {
        downstream.onComplete()
    }
}

class StartWithObservable<Element>: Observable<Element> {
    private let source: Observable<Element>
    private let elements: [Element]

    init(source: Observable<Element>, elements: [Element]) {
        self.source = source
        self.elements = elements
    }

    override func subscribe<O: Observer<Element>>(_ observer: O) -> Disposable {
        source.subscribeAndLink {
            StartWithObserver(downstream: observer, elements: elements)
                .asLinkableObserver()
        }
    }
}
