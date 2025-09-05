//
//  LifecycleError.swift
//  tealium-swift
//
//  Created by Den Guzov on 04/11/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

#if lifecycle
import TealiumCore
#endif

public enum LifecycleError: Error, TealiumErrorEnum {
    case manualTrackNotAllowed
    case invalidEventOrder

    var localizedDescription: String {
        switch self {
        case .manualTrackNotAllowed:
            "Lifecycle auto-tracking is enabled, cannot manually track lifecycle event."
        case .invalidEventOrder:
            "Invalid lifecycle event order. The event is not registered/tracked."
        }
    }
}
