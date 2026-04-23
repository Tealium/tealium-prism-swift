//
//  Observable+Operators.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 07/02/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public extension Observable {

    /// Ensures that Observers to the returned observable are always subscribed on the provided queue.
    /// - Warning: Must be called as a last item in the observable chain. Failing to do so will result in subsequent operators to be subscribed on the calling Thread.
    func subscribeOn(_ queue: TealiumQueue) -> any Subscribable<Element> {
        SubscribeOnObservable(source: self, queue: queue)
    }

    /// Ensures that Observers to the returned observable are always called on the provided queue.
    /// - Warning: This can only be used when the Observable is also subscribed from that queue.
    func observeOn(_ queue: TealiumQueue) -> Observable<Element> {
        ObserveOnObservable(source: self, queue: queue)
    }

    /// Transforms the events provided to the observable into new events before calling the observers of the new observable.
    func map<Result>(_ transform: @escaping (Element) -> Result) -> Observable<Result> {
        MapObservable(source: self, transform: transform)
    }

    /// Transforms the events provided to the observable into new events, stripping out the nil events, before calling the observers of the new observable.
    func compactMap<Result>(_ transform: @escaping (Element) -> Result?) -> Observable<Result> {
        CompactMapObservable(source: self, transform: transform)
    }

    /// Only report the events that are included by the provided filter.
    func filter(_ isIncluded: @escaping (Element) -> Bool) -> Observable<Element> {
        FilterObservable(source: self, predicate: isIncluded)
    }

    /// Returns an observable that emits subsequent values only if they are different from the last one emitted by the underlying observable.
    func distinct(isEqual: @escaping (Element, Element) -> Bool) -> Observable<Element> {
        DistinctObservable(source: self, isEqual: isEqual)
    }

    /// Returns an observable that ignores the first N published events.
    func ignore(_ count: Int) -> Observable<Element> {
        IgnoreObservable(source: self, count: count)
    }

    /// Returns an observable that ignores the first published event.
    func ignoreFirst() -> Observable<Element> {
        ignore(1)
    }

    /// On subscription emits the provided elements before providing the other events from the original observable.
    func startWith(_ elements: Element...) -> Observable<Element> {
        StartWithObservable(source: self, elements: elements)
    }

    /**
     * Transforms an event by providing a new observable that is flattened in the observable that is returned by this method.
     *
     * - Parameter selector: the function that will return a new observable when an event is published by the original observable.
     *
     * - Returns: an observable that flattens the observables returned by the selector and emits all of their events.
     */
    func flatMap<Result>(_ selector: @escaping (Element) -> Observable<Result>) -> Observable<Result> {
        FlatMapObservable(source: self, transform: selector)
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
     * let subject = Subject<Int>()
     * _ = subject.asObservable().flatMapLatest { value in
     *     Observable<Int> { observer in
     *         // This is the block that is called on each `subscribe` call
     *         subject.publish(value + 1)
     *         observer(value)
     *         return Subscription(onDispose: {})
     *     }
     * }.subscribe { _ in }
     * subject.publish(0)
     * ```
     *
     * The following, instead, has an exit condition, so it's safe to use:
     *
     * ```swift
     * let subject = Subject<Int>()
     * _ = subject.asObservable().flatMapLatest { value in
     *     Observable<Int> { observer in
     *         // This is the block that is called on each `subscribe` call
     *         if value < 10 {
     *             subject.publish(value + 1)
     *         }
     *         observer(value)
     *         return Subscription(onDispose: {})
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
        FlatMapLatestObservable(source: self, transform: selector)
    }

    /// Returns a new observable that emits the events of the original observable and the otherObservable passed as parameter.
    func merge(_ otherObservables: Observable<Element>...) -> Observable<Element> {
        Observables.from([self] + otherObservables).flatMap { $0 }
    }

    /**
     * Returns an observable that emits only the first event that is included by the provided filter.
     *
     * If you don't provide a block then the first event will always be taken.
     * After the first event is published it automatically disposes the observer.
     */
    func first(where isIncluded: @escaping (Element) -> Bool = { _ in true }) -> Observable<Element> {
        FirstObservable(source: self, predicate: isIncluded)
    }

    /**
     * Returns a new observable that will emit events with a tuple containing the last event of the original and the provided observable.
     *
     * The first event will be fired when both observable have emitted at least one event.
     * Then a new event with the tuple will be emitted every time one of the two emits a new event.
     */
    func combineLatest<Other>(_ otherObservable: Observable<Other>) -> Observable<(Element, Other)> {
        CombineLatestObservable(source: self, other: otherObservable)
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
        ResubscribingWhileObservable(source: self, predicate: isIncluded)
    }

    /// Returns an observable that automatically unsubscribes when the provided condition is no longer met.
    /// If inclusive is `true` the last element will also be published.
    func takeWhile(_ isIncluded: @escaping (Element) -> Bool, inclusive: Bool = false) -> Observable<Element> {
        TakeWhileObservable(source: self, predicate: isIncluded, inclusive: inclusive)
    }

    /// Returns a `Single` that only emits the first value from the underlying observable, on the given `TealiumQueue`.
    func asSingle(queue: TealiumQueue) -> any Single<Element> {
        SingleImpl(observable: self, queue: queue)
    }

    /**
     * Returns an observable that will emit values in a possibly asynchronous manner determined by
     * the given `block`.
     *
     * - parameter block: a block of code, to be executed with the next value from the source, along with
     * the observer with which to emit downstream.
     */
    func callback<Result>(from block: @escaping (_ element: Element, _ completion: @escaping (Result) -> Void) -> Void) -> Observable<Result> {
        flatMap { value in
            Observables.callback { completion in
                block(value, completion)
            }
        }
    }

    /**
     * Returns an observable that will emit values in a possibly asynchronous manner determined by
     * the given `block`.
     *
     * - parameter block: a block of code, to be executed with the next value from the source, along with
     * the observer with which to emit downstream, disposable by the returned `Disposable` object.
     */
    func callback<Result>(fromDisposable block: @escaping (_ element: Element, _ completion: @escaping (Result) -> Void) -> Disposable) -> Observable<Result> {
        flatMap { value in
            Observables.callback { completion in
                block(value, completion)
            }
        }
    }

    /**
     * Returns an observable that will emit the last element received after the provided delay if no other event is emitted in the meantime.
     *
     * If the provided milliseconds are 0 or less, this behaves like an `observeOn`, dispatching events immediately on the provided queue,
     * potentially synchronously if the element was emitted from that same queue.
     *
     * - parameter milliseconds: The time to wait before emitting the elements
     * - parameter queue: The queue on which the debouncer is working on.
     */
    func debounce(_ milliseconds: Int, on queue: TealiumQueue) -> Observable<Element> {
        flatMapLatest { element in
            Observables.delayed(element: element,
                                milliseconds: milliseconds,
                                on: queue)
        }
    }

    /**
     * Returns an observable that will emit each value received after the provided delay.
     *
     * If the provided milliseconds are 0 or less, this behaves like an `observeOn`, dispatching events immediately on the provided queue,
     * potentially synchronously if the element was emitted from that same queue.
     *
     * - parameter milliseconds: The time to wait before emitting the elements
     * - parameter queue: The queue on which the debouncer is working on.
     */
    func delay(_ milliseconds: Int, on queue: TealiumQueue) -> Observable<Element> {
        flatMap { element in
            Observables.delayed(element: element,
                                milliseconds: milliseconds,
                                on: queue)
        }
    }
}

public extension Observable where Element: Equatable {
    /// Only emits new events if the last one is different from the new one.
    func distinct() -> Observable<Element> {
        distinct(isEqual: { $0 == $1 })
    }
}

fileprivate extension Observables {
    static func delayed<Element>(element: Element, milliseconds: Int, on queue: TealiumQueue) -> Observable<Element> {
        Observables.create { observer in
            let downstream = AsyncDisposableContainer(queue: queue)

            guard milliseconds > 0 else {
                queue.ensureOnQueue {
                    guard !downstream.isDisposed else { return }
                    observer.onNext(element)
                    observer.onComplete()
                }
                downstream.dispose()
                return downstream
            }
            queue.dispatchQueue.asyncAfter(deadline: .now() + .milliseconds(milliseconds)) {
                guard !downstream.isDisposed else { return }
                observer.onNext(element)
                observer.onComplete()
                downstream.dispose()
            }
            return downstream
        }
    }
}
