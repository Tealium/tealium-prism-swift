//
//  TealiumObservable+Create.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 09/06/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public extension TealiumObservable {
    // swiftlint:disable identifier_name
    /**
     * Returns an observable that will send only one event once the asyncFunction has completed.
     *
     * - Parameter asyncFunction: is the function that needs to be called and needs to report the completion to the provided observer.
     *  This function will only be called when an observer subscribes to the returned Observable. Every subscription will cause the asyncFunction to be called again.
     *
     * - Returns: a `TealiumObservable` that, when a new observer subscribes, will call the asyncFunction and publish a new event to the subscribers when the function completes.
     */
    static func Callback(from asyncFunction: @escaping (@escaping Observer) -> Void) -> TealiumObservable<Element> {
        TealiumObservableCreate { observer in
            var cancelled = false
            asyncFunction { res in
                if !cancelled {
                    observer(res)
                }
            }
            return TealiumSubscription {
                cancelled = true
            }
        }
    }

    /// Returns an observable that just reports the provided elements in order to each new subscriber.
    static func Just(_ elements: Element...) -> TealiumObservable<Element> {
        TealiumObservableCreate { observer in
            for element in elements {
                observer(element)
            }
            return TealiumSubscription { }
        }
    }

    /// Returns an empty observable that never reports anything
    static func Empty<Element>() -> TealiumObservable<Element> {
        TealiumObservableCreate { _ in
            return TealiumSubscription { }
        }
    }

    static func CombineLatest(_ observables: [TealiumObservable<Element>]) -> TealiumObservable<[Element]> {
        TealiumObservableCreate { observer in
            let container = TealiumDisposeContainer()
            let count = observables.count
            guard count > 0 else { return container }
            var temporaryArray: [Element?]? = [Element?](repeating: nil, count: observables.count)
            var resultArray = [Element]()
            func notify(element: Element, index: Int) {
                if temporaryArray != nil {
                    temporaryArray?[index] = element
                    if temporaryArray?.contains(where: { $0 == nil }) == false,
                       let unwrappedArray = temporaryArray?.compactMap({ $0 }),
                        unwrappedArray.count == count {
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
    }
    // swiftlint:enable identifier_name
}
