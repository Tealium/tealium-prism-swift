//
//  TealiumObservable+Operators.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 07/02/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// A simple wrapper that disposes the provided subscription on a specific queue.
class TealiumSubscriptionWrapper: TealiumDisposable {
    var subscription: TealiumDisposable?
    private(set) var isDisposed: Bool = false
    let queue: DispatchQueue?
    init(disposeOn queue: DispatchQueue? = nil) {
        self.queue = queue
    }
    func dispose() {
        if let queue = queue {
            queue.async { // TODO: We might want to add a check if we are already on that queue then don't dispatch
                self.subscription?.dispose()
            }
        } else {
            self.subscription?.dispose()
        }
        isDisposed = true
    }
}

public extension TealiumObservableProtocol {

    /// Ensures that Observers to the returned observable are always subscribed on the provided queue.
    func subscribeOn(_ queue: DispatchQueue) -> TealiumObservable<Element> {
        TealiumObservableCreate { observer in
            let subscription = TealiumSubscriptionWrapper(disposeOn: queue)
            queue.async { // TODO: We might want to add a check if we are already on that queue then don't dispatch
                subscription.subscription = self.subscribe(observer)
            }
            return subscription
        }
    }

    /// Ensures that Observers to the returned observable are always called on the provided queue.
    func observeOn(_ queue: DispatchQueue) -> TealiumObservable<Element> {
        TealiumObservableCreate { observer in
            self.subscribe { element in
                queue.async { // TODO: We might want to add a check if we are already on that queue then don't dispatch
                    observer(element)
                }
            }
        }
    }

    /// Transforms the events provided to the observable into new events before calling the observers of the new observable.
    func map<Result>(_ transform: @escaping (Element) -> Result) -> TealiumObservable<Result> {
        TealiumObservableCreate { observer in
            self.subscribe { element in
                observer(transform(element))
            }
        }
    }

    /// Transforms the events provided to the observable into new events, stripping out the nil events, before calling the observers of the new observable.
    func compactMap<Result>(_ transform: @escaping (Element) -> Result?) -> TealiumObservable<Result> {
        TealiumObservableCreate { observer in
            self.subscribe { element in
                if let transformed = transform(element) {
                    observer(transformed)
                }
            }
        }
    }

    /// Only report the events that are included by the provided filter.
    func filter(_ isIncluded: @escaping (Element) -> Bool) -> TealiumObservable<Element> {
        TealiumObservableCreate { observer in
            self.subscribe { element in
                if isIncluded(element) {
                    observer(element)
                }
            }
        }
    }

    /**
     * Transforms an event by providing a new observable that is flattened in the observable that is returned by this method.
     *
     * - Parameter selector: the function that will return a new observable when an event is published by the original observable.
     *
     * - Returns: an observable that flattens the observables returned by the selector and emits all of their events.
     */
    func flatMap<Result>(_ selector: @escaping (Element) -> TealiumObservable<Result>) -> TealiumObservable<Result> {
        return TealiumObservableCreate<Result> { observer in
            let container = TealiumDisposeContainer()
            self.subscribe { element in
                 selector(element)
                    .subscribe(observer)
                    .addTo(container)
            }.addTo(container)
            return container
        }
    }

    /**
     * Transforms an event by providing a new observable that is flattened in the observable that is returned by this method.
     * Every new observable returned will cancel the old observable subscriptions, therefore only emitting events for the latest returned observable.
     *
     * - Parameter selector: the function that will return a new observable when an event is published by the original observable.
     *
     * - Returns: an observable that flattens the observable returned by the selector and emits all of the events from the latest returned observable.
     */
    func flatMapLatest<Result>(_ selector: @escaping (Element) -> TealiumObservable<Result>) -> TealiumObservable<Result> {
        return TealiumObservableCreate<Result> { observer in
            let container = TealiumDisposeContainer()
            var subscription: TealiumDisposable?
            self.subscribe { element in
                subscription?.dispose()
                subscription = selector(element)
                    .subscribe(observer)
                subscription?.addTo(container)
            }.addTo(container)
            return container
        }
    }

    /// On subscription emits the provided elements before providing the other events from the original observable.
    func startWith(_ elements: Element...) -> TealiumObservable<Element> {
        return TealiumObservableCreate { observer in
            for startingElement in elements {
                observer(startingElement)
            }
            return self.subscribe { element in
                observer(element)
            }
        }
    }

    /// Returns a new observable that emits the events of the original observable and the otherObservable passed as parameter.
    func merge(_ otherObservables: TealiumObservable<Element>...) -> TealiumObservable<Element> {
        return TealiumObservableCreate { observer in
            let container = TealiumDisposeContainer()
            self.subscribe(observer)
                .addTo(container)
            for observable in otherObservables {
                observable.subscribe(observer)
                    .addTo(container)
            }
            return container
        }
    }

    /**
     * Returns an observable that emits only the first event that is included by the provided filter.
     *
     * If you don't provide a block then the first event will always be taken.
     * After the first event is published it automatically disposes the observer.
     */
    func first(where isIncluded: @escaping (Element) -> Bool = { _ in true }) -> TealiumObservable<Element> {
        TealiumObservableCreate { observer in
            let container = TealiumDisposeContainer()
            self.filter(isIncluded)
                .subscribe { element in
                    guard !container.isDisposed else { return } // Used to sync multiple events without unsubscribe capabilities
                    container.dispose()
                    observer(element)
                }.addTo(container)
            return container
        }
    }

    /**
     * Returns a new observable that will emit events with a tuple containing the last event of the original and the provided observable.
     *
     * The first event will be fired when both observable have emitted at least one event.
     * Then a new event with the tuple will be emitted everytime one of the two emits a new event.
     */
    func combineLatest<Other>(_ otherObservable: TealiumObservable<Other>) -> TealiumObservable<(Element, Other)> {
        TealiumObservableCreate { observer in
            let container = TealiumDisposeContainer()
            var first: Element?
            var other: Other?
            func notify() {
                if let first = first, let other = other {
                    observer((first, other))
                }
            }
            self.subscribe { element in
                first = element
                notify()
            }.addTo(container)
            otherObservable.subscribe { element in
                other = element
                notify()
            }.addTo(container)
            return container
        }
    }

    /// Returns an observable that ignores the first N published events.
    func ignore(_ count: Int) -> TealiumObservable<Element> {
        TealiumObservableCreate { observer in
            var current = 0
            return self.subscribe { element in
                guard current >= count else {
                    current += 1
                    return
                }
                observer(element)
            }
        }
    }

    /// Returns an observable that ignores the first published events.
    func ignoreFirst() -> TealiumObservable<Element> {
        ignore(1)
    }

    /**
     * Unsubscribes and subscribes again on each event while the condition is met.
     *
     * This is mainly used for cold observables that, when subscribed, start a new stream from zero. Use when you want to trigger the underlying observable to restart every time.
     *
     * - Warning: If the underlying observable always emits a new event and the condition is always met, this will end up calling endlessly until, eventually, the app will crash for stack overflow or out of memory exceptions.
     * You need to treat the underlying observable as a recurring function and make sure there is an exit condition.
     */
    func resubscribingWhile(_ isIncluded: @escaping (Element) -> Bool) -> TealiumObservable<Element> {
        func subscribeOnceInfiniteLoop(observer: @escaping (Element) -> Void, subscriptionWrapper: TealiumSubscriptionWrapper) -> TealiumDisposable {
            self.subscribeOnce { element in
                guard !subscriptionWrapper.isDisposed else { return }
                subscriptionWrapper.subscription?.dispose()
                observer(element)
                if isIncluded(element) {
                    subscriptionWrapper.subscription = subscribeOnceInfiniteLoop(observer: observer, subscriptionWrapper: subscriptionWrapper)
                }
            }
        }
        return TealiumObservableCreate { observer in
            let subscription = TealiumSubscriptionWrapper()
            subscription.subscription = subscribeOnceInfiniteLoop(observer: observer, subscriptionWrapper: subscription)
            return subscription
        }
    }

    /// Returns an observable that automatically unsubscribes when the provided condition is no longer met. If inclusive is `true` the last element will also be published.
    func takeWhile(_ isIncluded: @escaping (Element) -> Bool, inclusive: Bool = false) -> TealiumObservable<Element> {
        TealiumObservableCreate { observer in
            let container = TealiumDisposeContainer()
            self.subscribe { element in
                guard !container.isDisposed else { return }
                if isIncluded(element) {
                    observer(element)
                } else {
                    if inclusive {
                        observer(element)
                    }
                    container.dispose()
                }
            }.addTo(container)
            return container
        }
    }
}

public extension TealiumObservableProtocol where Element: Equatable {
    /// Only emits new events if the last one is different from the new one.
    func distinct() -> TealiumObservable<Element> {
        return TealiumObservableCreate { observer in
            var lastElement: Element?
            return self.subscribe { element in
                let isDistinct = lastElement == nil || lastElement != element
                lastElement = element
                if isDistinct {
                   observer(element)
                }
            }
        }
    }
}
