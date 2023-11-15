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
    var eventData: TealiumDictionaryInput
    var id: String = UUID().uuidString

    public init(name: String, type: DispatchType = .event, data: TealiumDictionaryInput? = nil) {
        var eventData: TealiumDictionaryInput = data ?? [:]
        eventData[TealiumDataKey.event] = name
        eventData[TealiumDataKey.eventType] = type.rawValue
        self.eventData = eventData
    }

    public var name: String? {
        eventData[TealiumDataKey.event] as? String
    }

    mutating func enrich(data: TealiumDictionaryInput) {
        eventData += data
    }
}
