//
//  CollectBatcher.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 14/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// A utility class used to help creating the payload for collect endpoints.
class CollectBatcher {
    /**
     *  The keys that have to be extracted from a batch of events.
     *
     * - Note: There is no need to extrapolate all the shared keys as the call will be gzipped anyway. Only required shared keys are needed.
     */
    let sharedKeys = [
        TealiumDataKey.account,
        TealiumDataKey.profile,
        TealiumDataKey.visitorId
    ]

    /// Splits the array of dispatches in batches grouped by `visitorId`.
    func splitDispatchesByVisitorId(_ dispatches: [TealiumDispatch]) -> [[TealiumDispatch]] {
        Array([String: [TealiumDispatch]](grouping: dispatches, by: { $0.eventData.get(key: TealiumDataKey.visitorId) ?? "" }).values)
    }

    /**
     * Extracts shared keys from the list of dispatches and puts them in a new shared object returned alongside an array of events.
     *
     * - Parameters:
     *    - dispatches: the array of dispatches to compress
     *    - profileOverride: the tealium profile that should override the profile included in all dispatches
     *
     * - Returns: `DataObject?` containing the batched payload with shared keys extracted into the `shared` key and the events array under the `events` key.
     */
    func compressDispatches(_ dispatches: [TealiumDispatch], profileOverride: String?) -> DataObject? {
        guard let firstDispatch = dispatches.first else {
            return nil
        }
        let shared = extractSharedKeys(from: firstDispatch.eventData, profileOverride: profileOverride)
        let events = dispatches.map { dispatch in
            var eventData = dispatch.eventData
            for key in sharedKeys {
                eventData.removeValue(forKey: key)
            }
            return eventData
        }
        return ["events": events,
                "shared": shared]
    }

    /**
     * Returns an object from the shared keys contained in the provided dictionary.
     *
     * - Parameters:
     *    - dictionary: the dictionary containing the data
     *    - profileOverride: the tealium profile that should override the profile passed by all the dispatches.
     *
     * - Returns: `DataObject` containing the batched payload with shared keys extracted into the `shared` key.
     */
    func extractSharedKeys(from dataObject: DataObject, profileOverride: String?) -> DataObject {
        var newSharedDataObject = DataObject()
        let dictionary = dataObject.asDictionary()
        sharedKeys.forEach { key in
            if let item = dictionary[key] {
                newSharedDataObject.set(item, key: key)
            }
        }
        applyProfileOverride(profileOverride, to: &newSharedDataObject)
        return newSharedDataObject
    }

    /// Applies the profileOverride to the dictionary if the profileOverride is not nil.
    func applyProfileOverride(_ profileOverride: String?, to dataObject: inout DataObject) {
        if let profileOverride = profileOverride {
            dataObject.set(profileOverride, key: TealiumDataKey.profile)
        }
    }
}
