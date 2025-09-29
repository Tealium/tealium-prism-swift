//
//  SessionInfo.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 12/08/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

struct SessionInfo {

    let sessionId: Int64
    let lastEventTimeMilliseconds: Int64
    let eventCount: Int

    static func new(timestamp: Int64) -> Self {
        SessionInfo(sessionId: timestamp / 1000,
                    lastEventTimeMilliseconds: timestamp,
                    eventCount: 1)
    }

    func isExpired(currentTimeMilliseconds: Int64, sessionTimeout: TimeFrame) -> Bool {
        lastEventTimeMilliseconds < currentTimeMilliseconds - sessionTimeout.inMilliseconds()
    }

}

extension SessionInfo: DataObjectConvertible {
    func toDataObject() -> DataObject {
        [
            Keys.sessionId: sessionId,
            Keys.lastEventTimeMilliseconds: lastEventTimeMilliseconds,
            Keys.eventCount: eventCount
        ]
    }
}

extension SessionInfo {
    enum Keys {
        static let sessionId = "id"
        static let lastEventTimeMilliseconds = "last_event"
        static let eventCount = "event_count"
    }
    struct Converter: DataItemConverter {
        typealias Convertible = SessionInfo
        func convert(dataItem: DataItem) -> Convertible? {
            guard let dictionary = dataItem.getDataDictionary(),
                  let sessionId = dictionary.get(key: Keys.sessionId, as: Int64.self),
                  let lastEventTimestamp = dictionary.get(key: Keys.lastEventTimeMilliseconds, as: Int64.self) else {
                return nil
            }
            return SessionInfo(sessionId: sessionId,
                               lastEventTimeMilliseconds: lastEventTimestamp,
                               eventCount: dictionary.get(key: Keys.eventCount) ?? 1)
        }
    }
    static let converter: any DataItemConverter<Self> = Converter()
}
