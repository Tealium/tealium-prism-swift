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
    // swiftlint:enable identifier_name
}
