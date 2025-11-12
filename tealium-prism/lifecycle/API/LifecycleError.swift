//
//  LifecycleError.swift
//  tealium-prism
//
//  Created by Den Guzov on 04/11/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

#if lifecycle
import TealiumPrismCore
#endif

/// An error from the `Lifecycle` module.
public enum LifecycleError: Error, ErrorEnum, ErrorWrapping {
    /// Lifecycle auto-tracking is enabled, cannot manually track lifecycle event.
    case manualTrackNotAllowed
    /// Invalid lifecycle event order. The event is not registered/tracked.
    case invalidEventOrder
    /// Lifecycle failed to perform a specific operation.
    case underlyingError(_ error: Error)

    var localizedDescription: String {
        switch self {
        case .manualTrackNotAllowed:
            "Lifecycle auto-tracking is enabled, cannot manually track lifecycle event."
        case .invalidEventOrder:
            "Invalid lifecycle event order. The event is not registered/tracked."
        case let .underlyingError(error):
            "Lifecycle failed due to error: \(error)"
        }
    }
}
