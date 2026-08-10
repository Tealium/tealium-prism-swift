//
//  NotificationCenter+observable.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 29/07/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

extension NotificationCenter {

    /// An implementation of `addObserver` that returns a cold `Observable` that emits the notifications upon subscription.
    ///
    /// This is useful so you can chain operators like:
    /// - `map`, to transform the `Notification` into another type
    /// - `observeOn`, to handle the notification on a different `TealiumQueue`.
    ///
    /// - Note: Using `observeOn` is different than passing an `OperationQueue` to `addObserver`.
    /// The former dispatches the work asynchronously while the latter blocks the posting thread.
    ///
    /// Emissions occur synchronously on the posting thread. If the consumer runs on a
    /// different queue, use `subscribeOn(<posting queue>)` (e.g. `.main` for UIApplication
    /// notifications) followed by `observeOn(<consumer queue>)`.
    func observable(forName name: Notification.Name,
                    object obj: Any? = nil) -> Observable<Notification> {
        Observables.create { observer in
            let handle = self.addObserver(forName: name,
                                          object: obj,
                                          queue: nil) { notification in
                observer.onNext(notification)
            }
            return Subscription { [weak self] in
                self?.removeObserver(handle)
            }
        }
    }
}
