//
//  VisitorSwitcher.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 15/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

class VisitorSwitcher {
    /**
     * Subscribes the given `identify` closure to receive identity updates from the given
     * DataLayer's `DataStore`.
     *
     * Identity updates are derived from writes at the latest visitor identity key emitted by `onIdentityKey`:
     * on each write, `identify` is called with the value read from the store at that key afterwards, and
     * not called if no value is present (e.g. the same transaction also removed it, or it is already expired).
     * Removals are not reported, as an identity leaving the data layer never changes the visitor id.
     *
     * Consecutive writes of the same identity are all reported: after the identity is removed and the
     * visitor id regenerated, writing the same identity again must restore its visitor id.
     *
     * Both the identity key and the actual data inside of the store can change and we will react to all of those
     * to end up with only identifying for the latest `identity`, stored at the latest visitor identity key.
     *
     * - Parameters:
     *   - onIdentityKey: The `Observable` of the visitor identity key; a `nil` key disables Visitor Switching.
     *   - dataLayerStore: The `DataStore` to monitor for identity changes.
     *   - identify: The closure to notify of identity updates.
     */
    static func handleIdentitySwitches(onIdentityKey: Observable<String?>,
                                       dataLayerStore: any DataStore,
                                       identify: @escaping (_ identity: String) -> Void) -> any Disposable {
        return onIdentityKey
            .distinct()
            .flatMapLatest { key -> Observable<String> in
                guard let key else { return Observables.empty() }
                // Re-read the store, as the event payload may not be the value actually present: a put whose
                // expiry has already passed is still published, and a transaction's removals are published
                // before its updates regardless of edit order.
                return dataLayerStore.onDataUpdated
                    .filter { $0.keys.contains(key) }
                    .map { _ in dataLayerStore.get(key: key) }
                    .startWith(dataLayerStore.get(key: key))
                    .compactMap { $0 }
            }
            .subscribe { identity in
                identify(identity)
            }
    }
}
