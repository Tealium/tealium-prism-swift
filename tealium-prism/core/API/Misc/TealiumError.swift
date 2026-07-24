//
//  TealiumError.swift
//  tealium-prism
//
//  Created by Den Guzov on 29/11/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/// Errors that can occur when calling methods directly on a `Tealium` instance.
public enum TealiumError: ErrorEnum, ErrorWrapping {
    /// An error happened during `Tealium` initialization that prevented the correct initialization of the `Tealium` instance.
    case initializationError(_ error: Error)

    /// The underlying error caused by the specific failed operation.
    case underlyingError(_ error: Error)

    /// The `Tealium` instance has been shut down. Any operation attempted on a shut-down instance fails with this error.
    case instanceShutdown
}
