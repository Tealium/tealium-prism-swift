//
//  LifecycleEvent.swift
//  tealium-prism
//
//  Created by Denis Guzov on 27/08/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

#if lifecycle
import TealiumPrismCore
#endif

/// The types of lifecycle events that can be tracked.
public enum LifecycleEvent: String, CaseIterable, DataInputConvertible {
    /// App launch event.
    case launch
    /// App wake (foreground) event.
    case wake
    /// App sleep (background) event.
    case sleep

    public init?(rawValue: String) {
        switch rawValue.lowercased() {
        case Self.launch.rawValue: self = .launch
        case Self.wake.rawValue: self = .wake
        case Self.sleep.rawValue: self = .sleep
        default: return nil
        }
    }

    init?(rawValue: String?) {
        guard let rawValue else {
            return nil
        }
        self.init(rawValue: rawValue)
    }

    public func toDataInput() -> any DataInput {
        self.rawValue
    }
}
