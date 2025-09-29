//
//  ResourceCacher.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 17/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 *  A storage to persist a resource and it's etag, when available.
 *
 * Resource is stored in the `DataStore` at the provided `fileName`, while the `etag` will be stored at `\(fileName)_etag`
 */
public class ResourceCacher<Resource: Codable> {
    let dataStore: DataStore
    let fileName: String
    var etagStorageKey: String {
        fileName + "_etag"
    }
    public init(dataStore: DataStore, fileName: String) {
        self.dataStore = dataStore
        self.fileName = fileName
    }

    /// Returns the stored resource, if present and successfuly decodable.
    public func readResource() -> Resource? {
        guard let stringValue = dataStore.get(key: fileName, as: String.self) else {
            return nil
        }
        return try? stringValue.deserializeCodable()
    }

    /// Returns the stored etag, if present.
    public func readEtag() -> String? {
        dataStore.get(key: etagStorageKey)
    }

    private func serialize(resource: Resource) throws -> String {
        let jsonEncoder = Tealium.jsonEncoder
        let jsonData = try jsonEncoder.encode(resource)
        // swiftlint:disable:next optional_data_string_conversion
        return String(decoding: jsonData, as: UTF8.self) // Safe as we just used encode that returns UTF8 formatted data
    }

    /**
     * Saves the provided resource with the etag, if provided, in a transaction.
     *
     * Both the resource and the etag will override previous resources stored at the same location.
     * In case of a `nil` etag any previous etag present will be deleted.
     *
     * - Parameters:
     *   - resource: the resource to be stored.
     *   - etag: the etag to save along with this resource.
     */
    public func saveResource(_ resource: Resource, etag: String?) throws {
        let serializedResource = try serialize(resource: resource)
        var edit = dataStore.edit()
            .put(key: fileName, value: serializedResource, expiry: .forever)
        if let etag {
            edit = edit.put(key: etagStorageKey, value: etag, expiry: .forever)
        } else {
            edit = edit.remove(key: etagStorageKey)
        }
        try edit.commit()
    }
}
