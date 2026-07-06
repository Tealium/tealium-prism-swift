//
//  CompactMapObservable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

private class CompactMapObserver<Source, Element>: Observer {
    private let downstream: any Observer<Element>
    private let transform: (Source) -> Element?

    init(downstream: any Observer<Element>, transform: @escaping (Source) -> Element?) {
        self.transform = transform
        self.downstream = downstream
    }

    func onNext(_ element: Source) {
        guard let transformed = transform(element) else { return }
        downstream.onNext(transformed)
    }

    func onComplete() {
        downstream.onComplete()
    }
}

class CompactMapObservable<Source, Element>: Observable<Element> {
    private let source: Observable<Source>
    private let transform: (Source) -> Element?

    init(source: Observable<Source>, transform: @escaping (Source) -> Element?) {
        self.source = source
        self.transform = transform
    }

    override func subscribe<O: Observer<Element>>(_ observer: O) -> any Disposable {
        source.subscribeAndLink(
            CompactMapObserver(downstream: observer, transform: transform)
                .asLinkableObserver()
        )
    }
}
