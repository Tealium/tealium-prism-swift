//
//  Observable+Operators.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 07/02/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public extension Observable {

    /// Ensures that the subscription to the source observable happens on the provided `queue`.
    ///
    /// The source **must** emit on this same `queue` (see the first warning below); this operator
    /// moves only the *subscription*, not the emission thread. It is useful to consume (via
    /// `observeOn`) an `Observable` that emits from a thread different from the consumer's.
    ///
    /// Example:
    ///
    /// ```swift
    /// let mainThreadSubject = Subject<Int>()
    /// let queue = TealiumQueue(label: "someQueue")
    /// queue.ensureOnQueue {
    ///     mainThreadObservable.asObservable()
    ///     .subscribeOn(.main)
    ///     .observeOn(queue)
    ///     .first()
    ///     .map { $0 * 10 }
    ///     .subscribe { print($0) }
    /// }
    ///
    /// DispatchQueue.main.async {
    ///     mainThreadSubject.onNext(1)
    /// }
    /// ```
    ///
    /// - Warning: This method is intended for observables that emit from the same queue as the one provided here.
    /// Calling this method on an `Observable` that emits from a different queue will cause race conditions.
    ///
    /// You can `subscribe` to this `Observable` directly and you will receive `onNext` and `onComplete`
    /// from the source queue (which must be the same as the provided queue) and you can dispose from any thread.
    ///
    /// - Warning: You can't chain any operator to the returned `Observable` other than `observeOn`
    /// with the queue on which the consumer runs. After doing that you can chain any other operator,
    /// as long as it also works from that same queue.
    ///
    func subscribeOn(_ queue: TealiumQueue) -> Observable<Element> {
        SubscribeOnObservable(source: self, queue: queue)
    }

    /// Ensures that downstream observers receive events on the provided queue.
    ///
    /// This is useful to consume an `Observable` that emits from a thread different from the consumer's:
    /// the source keeps emitting on its own thread, while `onNext`/`onComplete` are
    /// re-delivered downstream on this `queue`.
    ///
    /// Example:
    ///
    /// ```swift
    /// let mainThreadSubject = Subject<Int>()
    /// let queue = TealiumQueue(label: "someQueue")
    /// queue.ensureOnQueue {
    ///     mainThreadObservable.asObservable()
    ///     .subscribeOn(.main)
    ///     .observeOn(queue)
    ///     .first()
    ///     .map { $0 * 10 }
    ///     .subscribe { print($0) }
    /// }
    ///
    /// DispatchQueue.main.async {
    ///     mainThreadSubject.onNext(1)
    /// }
    /// ```
    ///
    /// - Warning: Disposing of a subscription to the returned `Observable` must happen from the same queue.
    /// Disposing from a different queue races with event delivery on this `queue`.
    ///
    /// - Warning: Immediately before `observeOn` you must ensure to `subscribeOn` the producer queue,
    /// and you must not chain any operator onto that `subscribeOn` before calling `observeOn`.
    ///
    /// See `subscribeOn` for the full contract.
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

    /// Returns an observable that ignores the first N emitted events.
    func ignore(_ count: Int) -> Observable<Element> {
        IgnoreObservable(source: self, count: count)
    }

    /// Returns an observable that ignores the first emitted event.
    func ignoreFirst() -> Observable<Element> {
        ignore(1)
    }

    /// On subscription emits the provided elements before providing the other events from the original observable.
    func startWith(_ elements: Element...) -> Observable<Element> {
        StartWithObservable(source: self, elements: elements)
    }

    /**
     * Transforms each event into a new observable, subscribing to all of them and flattening their emissions.
     *
     * **Completion:** Completes only when the upstream AND all inner observables have completed.
     *
     * - Parameter selector: the function that will return a new observable when an event is emitted by the original observable.
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
     * - Warning: If the observable returned from `selector`, on subscription, synchronously emits a new element upstream,
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
     *         subject.onNext(value + 1)
     *         observer.onNext(value)
     *         return Subscription(onDispose: {})
     *     }
     * }.subscribe { _ in }
     * subject.onNext(0)
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
     *             subject.onNext(value + 1)
     *         }
     *         observer.onNext(value)
     *         return Subscription(onDispose: {})
     *     }
     * }.subscribe { _ in }
     * subject.onNext(0)
     * ```
     *
     * - Note: more complex examples can be created where the upstream emit is less clear, so use this with caution.
     *
     * - Parameter selector: the function that will return a new observable when an event is emitted by the original observable.
     *
     * - Returns: an observable that flattens the observable returned by the selector and emits all of the events from the latest returned observable.
     */
    func flatMapLatest<Result>(_ selector: @escaping (Element) -> Observable<Result>) -> Observable<Result> {
        FlatMapLatestObservable(source: self, transform: selector)
    }

    /// Returns a new observable that emits the events of the original observable and all other observables passed as parameters.
    ///
    /// **Completion:** Completes only when all merged sources have completed.
    func merge(_ otherObservables: Observable<Element>...) -> Observable<Element> {
        Observables.merge([self] + otherObservables)
    }

    /**
     * Returns an observable that emits only the first event matching the filter, then completes.
     *
     * If you don't provide a block then the first event will always be taken.
     *
     * **Completion:** Completes immediately after the first matching element is emitted.
     * Also completes (without emitting) if the upstream completes before a match is found.
     */
    func first(where isIncluded: @escaping (Element) -> Bool = { _ in true }) -> Observable<Element> {
        FirstObservable(source: self, predicate: isIncluded)
    }

    /**
     * Combines the latest values from this observable and the provided observable into a tuple.
     *
     * The first emission occurs once both observables have emitted at least one event.
     * After that, a new tuple is emitted each time either source emits a new value.
     *
     * **Completion:** Completes when both sources complete, or early if either source
     * completes without ever having emitted a value.
     */
    func combineLatest<Other>(_ otherObservable: Observable<Other>) -> Observable<(Element, Other)> {
        CombineLatestObservable(source: self, other: otherObservable)
    }

    /**
     * Unsubscribes and subscribes again on each event while the condition is met.
     *
     * This is mainly used for cold observables that, when subscribed, start a new stream from zero. Use when you want to trigger the underlying observable to restart every time.
     *
     * **Completion:** Completes when the upstream completes without emitting a matching element,
     * or when the predicate returns `false`.
     *
     * - Warning: If the underlying observable always emits a new event and the condition is always met, this will end up calling endlessly until, eventually, the app will crash for stack overflow or out of memory exceptions.
     * You need to treat the underlying observable as a recursive function and make sure there is an exit condition.
     */
    func resubscribingWhile(_ isIncluded: @escaping (Element) -> Bool) -> Observable<Element> {
        ResubscribingWhileObservable(source: self, predicate: isIncluded)
    }

    /// Returns an observable that emits elements while the condition is met, then completes.
    /// If `inclusive` is `true`, the first element failing the condition is also emitted before completion.
    ///
    /// **Completion:** Completes when the predicate returns `false`, or when the upstream completes.
    func takeWhile(_ isIncluded: @escaping (Element) -> Bool, inclusive: Bool = false) -> Observable<Element> {
        TakeWhileObservable(source: self, predicate: isIncluded, inclusive: inclusive)
    }

    /// Returns a `Single` that only emits the first value from the underlying observable, on the given `TealiumQueue`.
    func asSingle(queue: TealiumQueue) -> Single<Element> {
        Single(observable: self, queue: queue)
    }

    /**
     * Returns an observable that will emit values in a possibly asynchronous manner determined by
     * the given `block`.
     *
     * - parameter block: a block of code, to be executed with the next value from the source, along with
     * the observer with which to emit downstream.
     * Each call to this block is expected to complete only once. Further completion calls are ignored.
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
     * Each call to this block is expected to complete only once. Further completion calls are ignored.
     */
    func callback<Result>(fromDisposable block: @escaping (_ element: Element, _ completion: @escaping (Result) -> Void) -> any Disposable) -> Observable<Result> {
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
