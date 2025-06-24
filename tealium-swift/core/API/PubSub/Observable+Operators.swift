//
//  Observable+Operators.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 07/02/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public extension Observable {

    /// Ensures that Observers to the returned observable are always subscribed on the provided queue.
    /// - Warning: Must be called as a last item in the observable chain. Failing to do so will result in subsequent operators to be subscribed on the calling Thread.
    func subscribeOn(_ queue: TealiumQueue) -> any Subscribable<Element> {
        CustomObservable<Element> { observer in
            let subscription = AsyncDisposer(disposeOn: queue)
            queue.ensureOnQueue {
                guard !subscription.isDisposed else { return }
                self.subscribe(observer).addTo(subscription)
            }
            return subscription
        }
    }

    /// Ensures that Observers to the returned observable are always called on the provided queue.
    func observeOn(_ queue: TealiumQueue) -> Observable<Element> {
        CustomObservable<Element> { observer in
            let container = AsyncDisposer(disposeOn: queue)
            self.subscribe { element in
                queue.ensureOnQueue {
                    guard !container.isDisposed else { return }
                    observer(element)
                }
            }.addTo(container)
            return container
        }
    }

    /// Transforms the events provided to the observable into new events before calling the observers of the new observable.
    func map<Result>(_ transform: @escaping (Element) -> Result) -> Observable<Result> {
        CustomObservable<Result> { observer in
            self.subscribe { element in
                observer(transform(element))
            }
        }
    }

    /// Transforms the events provided to the observable into new events, stripping out the nil events, before calling the observers of the new observable.
    func compactMap<Result>(_ transform: @escaping (Element) -> Result?) -> Observable<Result> {
        CustomObservable<Result> { observer in
            self.subscribe { element in
                if let transformed = transform(element) {
                    observer(transformed)
                }
            }
        }
    }

    /// Only report the events that are included by the provided filter.
    func filter(_ isIncluded: @escaping (Element) -> Bool) -> Observable<Element> {
        CustomObservable<Element> { observer in
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
    func flatMap<Result>(_ selector: @escaping (Element) -> Observable<Result>) -> Observable<Result> {
        CustomObservable<Result> { observer in
            let container = DisposeContainer()
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
     * - Warning: If the observable returned from `selector`, on subscription, synchronously publishes a new element upstream,
     * then the selector will be triggered again. This can cause a endless loop in which we endlessly resubscribe to the returned observable.
     * If this is the case, make sure to have an exit condition, from which the subscription doesn't publish elements upstream anymore,
     * to avoid blocking the thread in which this operator is being called.
     *
     * As a very simplified example, the following code causes an endless loop:
     *
     * ```swift
     * let subject = BaseSubject<Int>()
     * _ = subject.asObservable().flatMapLatest { value in
     *     CustomObservable<Int> { observer in
     *         // This is the block that is called on each `subscribe` call
     *         subject.publish(value + 1)
     *         observer(value)
     *         return Subscription(unsubscribe: {})
     *     }
     * }.subscribe { _ in }
     * subject.publish(0)
     * ```
     *
     * The following, instead, has an exit condition, so it's safe to use:
     *
     * ```swift
     * let subject = BaseSubject<Int>()
     * _ = subject.asObservable().flatMapLatest { value in
     *     CustomObservable<Int> { observer in
     *         // This is the block that is called on each `subscribe` call
     *         if value < 10 {
     *             subject.publish(value + 1)
     *         }
     *         observer(value)
     *         return Subscription(unsubscribe: {})
     *     }
     * }.subscribe { _ in }
     * subject.publish(0)
     * ```
     *
     * - Note: more complex examples can be created where the upstream publish is less clear, so use this with caution.
     *
     * - Parameter selector: the function that will return a new observable when an event is published by the original observable.
     *
     * - Returns: an observable that flattens the observable returned by the selector and emits all of the events from the latest returned observable.
     */
    func flatMapLatest<Result>(_ selector: @escaping (Element) -> Observable<Result>) -> Observable<Result> {
        CustomObservable<Result> { observer in
            let container = DisposeContainer()
            var isSubscribing = false
            var latestElement: Element?
            var subscription: Disposable?
            self.subscribe { element in
                latestElement = element
                guard !isSubscribing else {
                    return
                }
                isSubscribing = true
                while let element = latestElement {
                    latestElement = nil
                    subscription?.dispose()
                    subscription = selector(element)
                        .subscribe(observer)
                    // If the subscription here always causes a synchronous publishing
                    // to this same observable `self`, there will always be a latestElement
                    // and therefore we will never exit the loop.
                    // Make sure you have an exit condition to avoid a deadlock.
                }
                subscription?.addTo(container)
                isSubscribing = false
            }.addTo(container)
            return container
        }
    }

    /// On subscription emits the provided elements before providing the other events from the original observable.
    func startWith(_ elements: Element...) -> Observable<Element> {
        CustomObservable<Element> { observer in
            for startingElement in elements {
                observer(startingElement)
            }
            return self.subscribe { element in
                observer(element)
            }
        }
    }

    /// Returns a new observable that emits the events of the original observable and the otherObservable passed as parameter.
    func merge(_ otherObservables: Observable<Element>...) -> Observable<Element> {
        CustomObservable<Element> { observer in
            let container = DisposeContainer()
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
    func first(where isIncluded: @escaping (Element) -> Bool = { _ in true }) -> Observable<Element> {
        CustomObservable<Element> { observer in
            let container = DisposeContainer()
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
     * Then a new event with the tuple will be emitted every time one of the two emits a new event.
     */
    func combineLatest<Other>(_ otherObservable: Observable<Other>) -> Observable<(Element, Other)> {
        CustomObservable<(Element, Other)> { observer in
            let container = DisposeContainer()
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
    func ignore(_ count: Int) -> Observable<Element> {
        CustomObservable<Element> { observer in
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
    func ignoreFirst() -> Observable<Element> {
        ignore(1)
    }

    /**
     * Unsubscribes and subscribes again on each event while the condition is met.
     *
     * This is mainly used for cold observables that, when subscribed, start a new stream from zero. Use when you want to trigger the underlying observable to restart every time.
     *
     * - Warning: If the underlying observable always emits a new event and the condition is always met, this will end up calling endlessly until, eventually, the app will crash for stack overflow or out of memory exceptions.
     * You need to treat the underlying observable as a recursive function and make sure there is an exit condition.
     */
    func resubscribingWhile(_ isIncluded: @escaping (Element) -> Bool) -> Observable<Element> {
        func subscribeOnceInfiniteLoop(observer: @escaping (Element) -> Void, container: DisposeContainer) -> Disposable {
            self.subscribeOnce { element in
                guard !container.isDisposed else { return }
                observer(element)
                if isIncluded(element) {
                    subscribeOnceInfiniteLoop(observer: observer, container: container)
                        .addTo(container)
                }
            }
        }
        return CustomObservable<Element> { observer in
            let container = DisposeContainer()
            subscribeOnceInfiniteLoop(observer: observer, container: container)
                .addTo(container)
            return container
        }
    }

    /// Returns an observable that automatically unsubscribes when the provided condition is no longer met.
    /// If inclusive is `true` the last element will also be published.
    func takeWhile(_ isIncluded: @escaping (Element) -> Bool, inclusive: Bool = false) -> Observable<Element> {
        CustomObservable<Element> { observer in
            let container = DisposeContainer()
            self.subscribe { element in
                guard !container.isDisposed else { return }
                if isIncluded(element) {
                    observer(element)
                } else {
                    container.dispose()
                    if inclusive {
                        observer(element)
                    }
                }
            }.addTo(container)
            return container
        }
    }

    /// Returns an observable that emits subsequent values only if they are different from the last one emitted by the underlying observable.
    func distinct(isEqual: @escaping (Element, Element) -> Bool) -> Observable<Element> {
        CustomObservable<Element> { observer in
            var lastElement: Element?
            return self.subscribe { element in
                let isDistinct = if let lastElement {
                    !isEqual(lastElement, element)
                } else {
                    true
                }
                lastElement = element
                if isDistinct {
                   observer(element)
                }
            }
        }
    }

    /// Returns a `Single` that only emits the first value from the underlying observable, on the given `TealiumQueue`.
    func asSingle(queue: TealiumQueue) -> any Single<Element> {
        SingleImpl(observable: self, queue: queue)
    }
}

public extension Observable where Element: Equatable {
    /// Only emits new events if the last one is different from the new one.
    func distinct() -> Observable<Element> {
        distinct(isEqual: { $0 == $1 })
    }
}
