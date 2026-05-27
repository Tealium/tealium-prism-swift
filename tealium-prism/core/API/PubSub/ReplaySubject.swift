//
//  ReplaySubject.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 17/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A `Subject` that, in addition to normal emission and subscribe behavior, holds a cache of items and sends it, in order, to each new observer that is subscribed.
 *
 * You can use it as a property wrapper to make the emitting private in the class where it's contained, but still expose an `Observable`
 * to the other classes.
 */
@propertyWrapper
public class ReplaySubject<Element>: Subject<Element> {
    private var cacheSize: Int?
    private var cache = [Element]()
    // Having a default value here would cause a crash on Carthage
    /// Creates a replay subject with the specified cache size.
    /// - Parameter cacheSize: The maximum number of elements to cache. If `nil` is provided, there will be no maximum.
    public init(cacheSize: Int?) {
        self.cacheSize = cacheSize
    }

    /// Creates a replay subject with a default cache size of 1.
    convenience public override init() {
        self.init(cacheSize: 1)
    }

    /// Creates a replay subject with an initial value and cache size.
    /// - Parameters:
    ///   - initialValue: The initial value to emit.
    ///   - cacheSize: The maximum number of elements to cache. If `nil` is provided, there will be no maximum.
    convenience public init(_ initialValue: Element, cacheSize: Int? = 1) {
        self.init(cacheSize: cacheSize)
        self.onNext(initialValue)
    }

    /// Returns an observable that replays cached elements to new subscribers.
    public override func asObservable() -> Observable<Element> {
        Observables.create { observer in
            for element in self.cache {
                observer.onNext(element)
            }
            return super.asObservable().subscribe(observer)
        }
    }

    public override func subscribe<O: Observer<Element>>(_ observer: O) -> any Disposable {
        asObservable().subscribe(observer)
    }

    /// Emits an element to all subscribers and adds it to the cache.
    public override func onNext(_ element: Element) {
        while let size = cacheSize, cache.count >= size && cache.count > 0 {
            cache.remove(at: 0)
        }
        if cacheSize == nil || cacheSize > 0 {
            cache.append(element)
        }
        super.onNext(element)
    }

    /// Removes all events from the cache.
    public func clear() {
        cache.removeAll()
    }

    /// Returns the last item that was emitted.
    public func last() -> Element? {
        return cache.last
    }

    /// Changes the cache size removing oldest elements not fitting in.
    public func resize(_ size: Int) {
        let newSize = size >= 0 ? size : Int.max
        cache = Array(cache.suffix(newSize))
        cacheSize = newSize
    }

    /// The wrapped observable value for property wrapper usage.
    public override var wrappedValue: Observable<Element> {
        super.wrappedValue
    }
}

public extension ReplaySubject where Element: Equatable {
    /// Emits the element only if it differs from the last cached value.
    func onNextIfChanged(_ element: Element) {
        if element != last() {
            onNext(element)
        }
    }
}
