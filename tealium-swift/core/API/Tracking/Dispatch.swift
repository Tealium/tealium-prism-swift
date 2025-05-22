//
//  Dispatch.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public enum DispatchType: String {
    case event
    case view
}

public struct Dispatch {
    var payload: DataObject
    let id: String
    let timestamp: Int64

    public init(name: String, type: DispatchType = .event, data: DataObject? = nil) {
        var payload: DataObject = data ?? [:]
        payload.set(name, key: TealiumDataKey.event)
        payload.set(type.rawValue, key: TealiumDataKey.eventType)
        self.init(payload: payload,
                  id: UUID().uuidString,
                  timestamp: Date().unixTimeMillisecondsInt)
    }

    init(payload: DataObject, id: String, timestamp: Int64) {
        self.payload = payload
        self.id = id
        self.timestamp = timestamp
        self.payload.set(timestamp, key: TealiumDataKey.timestampUnixMilliseconds)
    }

    public var name: String? {
        payload.get(key: TealiumDataKey.event)
    }

    mutating func enrich(data: DataObject) {
        payload += data
    }

    public func logDescription() -> String {
        return id.prefix(5) + "-" + (name ?? "")
    }
}
