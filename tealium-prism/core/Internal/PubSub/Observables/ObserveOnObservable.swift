//
//  ObserveOnObservable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/04/26.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

private class ObserveOnObserver<Element>: Observer {
    private var downstream: (any Observer<Element>)?
    private let queue: TealiumQueue
    private let container: AsyncDisposableContainer

    init(downstream: any Observer<Element>, queue: TealiumQueue, container: AsyncDisposableContainer) {
        self.downstream = downstream
        self.queue = queue
        self.container = container
    }

    func onNext(_ element: Element) {
        queue.ensureOnQueue {
            guard !self.container.isDisposed else { return }
            self.downstream?.onNext(element)
        }
    }

    func onComplete() {
        queue.ensureOnQueue {
            guard !self.container.isDisposed else { return }
            self.downstream?.onComplete()
            self.downstream = nil
            self.container.dispose()
        }
    }
}

class ObserveOnObservable<Element>: Observable<Element> {
    private let source: Observable<Element>
    private let queue: TealiumQueue

    init(source: Observable<Element>, queue: TealiumQueue) {
        self.source = source
        self.queue = queue
    }

    override func subscribe<O: Observer<Element>>(_ observer: O) -> any Disposable {
        let container = AsyncDisposableContainer(queue: queue)
        let observer = ObserveOnObserver(downstream: observer, queue: queue, container: container)
        source.subscribe(observer).addTo(container)
        return container
    }
}
