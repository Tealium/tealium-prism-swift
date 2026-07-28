//
//  SubscribeOnObservable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

private class SubscribeOnObserver<Element>: Observer {
    private var downstream: (any Observer<Element>)?
    private let container: AsyncDisposableContainer

    init(downstream: any Observer<Element>, container: AsyncDisposableContainer) {
        self.downstream = downstream
        self.container = container
    }

    func onNext(_ element: Element) {
        guard !container.isDisposed else { return }
        downstream?.onNext(element)
    }

    func onComplete() {
        guard !container.isDisposed else { return }
        downstream?.onComplete()
        downstream = nil
        container.dispose()
    }

}

class SubscribeOnObservable<Element>: Observable<Element> {
    private let source: Observable<Element>
    private let queue: TealiumQueue

    init(source: Observable<Element>, queue: TealiumQueue) {
        self.source = source
        self.queue = queue
    }

    override func subscribe<O: Observer<Element>>(_ observer: O) -> any Disposable {
        let container = AsyncDisposableContainer(queue: queue)
        queue.ensureOnQueue { [source] in
            guard !container.isDisposed else { return }
            let observer = SubscribeOnObserver(downstream: observer,
                                               container: container)
            source.subscribe(observer).addTo(container)
        }
        return container
    }
}
