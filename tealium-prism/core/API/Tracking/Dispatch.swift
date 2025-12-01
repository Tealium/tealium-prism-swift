//
//  Dispatch.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 24/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// The type of dispatch being sent.
public enum DispatchType: String {
    /// An event dispatch.
    case event
    /// A view dispatch.
    case view
}

/// Represents a tracking event or view to be dispatched.
public struct Dispatch {
    /// The payload data of the dispatch.
    public internal(set) var payload: DataObject
    /// The unique identifier of the dispatch.
    public let id: String
    /// The timestamp of when the dispatch was created, in Unix milliseconds.
    public let timestamp: Int64

    /// Creates a new dispatch with the specified parameters.
    /// - Parameters:
    ///   - name: The name of the event or view.
    ///   - type: The type of dispatch (event or view).
    ///   - data: Optional additional data to include.
    public init(name: String, type: DispatchType = .event, data: DataObject? = nil) {
        var payload: DataObject = data ?? [:]
        payload.set(name, key: TealiumDataKey.event)
        payload.set(type.rawValue, key: TealiumDataKey.eventType)
        self.init(payload: payload,
                  id: UUID().uuidString,
                  timestamp: Date().unixTimeMilliseconds)
    }

    init(payload: DataObject, id: String, timestamp: Int64) {
        self.payload = payload
        self.id = id
        self.timestamp = timestamp
        self.payload.set(timestamp, key: TealiumDataKey.timestampUnixMilliseconds)
    }

    /// The name of this dispatch.
    public var name: String? {
        payload.get(key: TealiumDataKey.event)
    }

    /// Enriches the dispatch with additional data.
    public mutating func enrich(data: DataObject) {
        payload += data
    }

    /// Replaces the current payload with a new one.
    public mutating func replace(payload: DataObject) {
        self.payload = payload
    }

    /// Returns a short description suitable for logging.
    /// - Returns: A string containing the dispatch ID prefix and name.
    public func logDescription() -> String {
        return id.prefix(5) + "-" + (name ?? "")
    }
}
