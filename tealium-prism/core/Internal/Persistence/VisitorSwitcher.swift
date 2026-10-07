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
     * Identity updates are derived from updates to the given `dataLayerStore` using the latest
     * visitor identity key emitted by `onIdentityKey`. If a value exists at that key in the `dataLayer` update
     * then the value will be taken as the identity and `identify` will be called with it.
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
                return dataLayerStore.onDataUpdated.map { newData in
                    newData.get(key: key)
                }
                .startWith(dataLayerStore.get(key: key))
                .compactMap { $0 }
            }
            .distinct()
            .subscribe { identity in
                identify(identity)
            }
    }
}
