//
//  TealiumDispatch.swift
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

public struct TealiumDispatch {
    var eventData: DataObject
    let id: String
    let timestamp: Int64

    public init(name: String, type: DispatchType = .event, data: DataObject? = nil) {
        var eventData: DataObject = data ?? [:]
        eventData.set(name, key: TealiumDataKey.event)
        eventData.set(type.rawValue, key: TealiumDataKey.eventType)
        self.init(eventData: eventData,
                  id: UUID().uuidString,
                  timestamp: Date().unixTimeMillisecondsInt)
    }

    init(eventData: DataObject, id: String, timestamp: Int64) {
        self.eventData = eventData
        self.id = id
        self.timestamp = timestamp
        self.eventData.set(timestamp, key: TealiumDataKey.timestampUnixMilliseconds)
    }

    public var name: String? {
        eventData.get(key: TealiumDataKey.event)
    }

    mutating func enrich(data: DataObject) {
        eventData += data
    }

    public func logDescription() -> String {
        return id.prefix(5) + "-" + (name ?? "")
    }
}
