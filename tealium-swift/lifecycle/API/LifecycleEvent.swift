//
//  LifecycleEvent.swift
//  tealium-swift
//
//  Created by Denis Guzov on 27/08/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

public enum LifecycleEvent: String, CaseIterable, Codable, DataInputConvertible {
    case launch, wake, sleep

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
