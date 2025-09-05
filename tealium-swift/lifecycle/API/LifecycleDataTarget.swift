//
//  LifecycleDataTarget.swift
//  tealium-swift
//
//  Created by Denis Guzov on 27/08/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

#if lifecycle
import TealiumCore
#endif

/**
 * LifecycleData target defines what targets the lifecycle event data is
 * added to. `LifecycleDataTarget.lifecycleEventsOnly` is selected by default,
 * and will only add related data to lifecycle events.
 */
public enum LifecycleDataTarget: String, DataInputConvertible {
    case allEvents, lifecycleEventsOnly

    init?(rawValue: String?) {
        guard let rawValue else {
            return nil
        }
        self.init(rawValue: rawValue)
    }

    public init?(rawValue: String) {
        switch rawValue.lowercased() {
        case Self.allEvents.rawValue.lowercased():
            self = .allEvents
        case Self.lifecycleEventsOnly.rawValue.lowercased():
            self = .lifecycleEventsOnly
        default:
            return nil
        }
    }

    public func toDataInput() -> any DataInput {
        self.rawValue
    }
}
