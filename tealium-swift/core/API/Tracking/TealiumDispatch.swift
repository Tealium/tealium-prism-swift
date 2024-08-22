//
//  TealiumDispatch.swift
//  Pods-tealium-swift_Example
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
    var eventData: [String: Any]
    let id: String
    let timestamp: Int64

    public init(name: String, type: DispatchType = .event, data: TealiumDictionaryInput? = nil) {
        var eventData: TealiumDictionaryInput = data ?? [:]
        eventData[TealiumDataKey.event] = name
        eventData[TealiumDataKey.eventType] = type.rawValue
        self.init(eventData: eventData,
                  id: UUID().uuidString,
                  timestamp: Date().unixTimeMillisecondsInt)
    }

    init(eventData: [String: Any], id: String, timestamp: Int64) {
        self.eventData = eventData
        self.id = id
        self.timestamp = timestamp
    }

    public var name: String? {
        eventData[TealiumDataKey.event] as? String
    }

    mutating func enrich(data: TealiumDictionaryInput) {
        eventData += data
    }

    public func logDescription() -> String {
        return id.prefix(5) + "-" + (name ?? "")
    }
}
