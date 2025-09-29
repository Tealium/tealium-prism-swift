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
     * Subscribes the given `visitorIdProvider` to receive identity updates from the lastest
     * DataLayer's `DataStore`.
     *
     * Identity updates are derived from updates to the given `dataLayerStore` using the
     * `CoreSettings.visitorIdentityKey`. If a value exists at that key in the `dataLayer` update
     * then the value will be taken as the identity and the `visitorIdProvider` will be notified.
     *
     * `CoreSettings`, `DataStore` and the actual data inside of the store can all change and we will react to all of those
     *  to end up with only identifying for the latest `identity`, stored at the latest `visitorIdentityKey` (as present
     *  in the latest `CoreSettings`) in the latest `DataStore`.
     *
     * - Parameters:
     *   - visitorIdProvider: The `VisitorIdProvider` to notify of identity updates.
     *   - onCoreSettings: The `CoreSettings` observable to derive the identity key from.
     *   - dataLayerStore: The `DataStore` to monitor for identity changes.
     */
    static func handleIdentitySwitches(visitorIdProvider: VisitorIdProvider, onCoreSettings: Observable<CoreSettings>, dataLayerStore: DataStore) -> Disposable {
        return onCoreSettings.map { $0.visitorIdentityKey }
            .distinct()
            .flatMapLatest { key -> Observable<String> in
                guard let key else { return .Empty() }
                return dataLayerStore.onDataUpdated.map { newData in
                    newData.get(key: key)
                }
                .startWith(dataLayerStore.get(key: key))
                .compactMap { $0 }
            }
            .distinct()
            .subscribe { identity in
                visitorIdProvider.identify(identity: identity)
            }
    }
}
