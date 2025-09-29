//
//  Observable+Create.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 09/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public extension Observable {
    // swiftlint:disable identifier_name
    /**
     * Returns an observable that will send only one event once the asyncFunction has completed.
     *
     * - Parameter asyncFunction: is the function that needs to be called and needs to report the completion to the provided observer.
     *  This function will only be called when an observer subscribes to the returned Observable. Every subscription will cause the asyncFunction to be called again.
     *
     * - Returns: a `Observable` that, when a new observer subscribes, will call the asyncFunction and publish a new event to the subscribers when the function completes.
     */
    static func Callback(from asyncFunction: @escaping (@escaping Observer) -> Void) -> Observable<Element> {
        CustomObservable { observer in
            var cancelled = false
            asyncFunction { res in
                if !cancelled {
                    observer(res)
                }
            }
            return Subscription {
                cancelled = true
            }
        }
    }

    /// Returns an observable that just reports the provided elements in order to each new subscriber.
    static func Just(_ elements: Element...) -> Observable<Element> {
        From(elements)
    }

    /// Returns an observable that just reports the provided elements in order to each new subscriber.
    static func From(_ elements: [Element]) -> Observable<Element> {
        CustomObservable<Element> { observer in
            for element in elements {
                observer(element)
            }
            return Subscription { }
        }
    }

    /// Returns an empty observable that never reports anything
    static func Empty() -> Observable<Element> {
        From([])
    }

    /**
     * Returns a single observable with an array of Elements from the provided array of elements
     *
     * The first element published from the returned observable will be published when all the observables provided emit at list one element.
     * All subsequent changes to any observable will be emitted one by one.
     */
    static func CombineLatest(_ observables: [Observable<Element>]) -> Observable<[Element]> {
        func subscriptionHandler(_ observer: @escaping ([Element]) -> Void) -> Disposable {
            let container = DisposeContainer()
            let count = observables.count
            guard count > 0 else {
                observer([])
                return container
            }
            var temporaryArray: [Element?]? = [Element?](repeating: nil, count: observables.count)
            var resultArray = [Element]()
            func notify(element: Element, index: Int) {
                if temporaryArray != nil {
                    temporaryArray?[index] = element
                    if let unwrappedArray = temporaryArray?.compactMap({ $0 }),
                        unwrappedArray.count == count { // true when temporary array is full of non-nil value
                        resultArray = unwrappedArray
                        temporaryArray = nil
                    }
                }
                if resultArray.count == count {
                    resultArray[index] = element
                    observer(resultArray)
                }
            }
            for i in 0..<count {
                observables[i].subscribe { element in
                    notify(element: element, index: i)
                }.addTo(container)
            }
            return container
        }
        return CustomObservable<[Element]>(subscriptionHandler)
    }
    // swiftlint:enable identifier_name
}
