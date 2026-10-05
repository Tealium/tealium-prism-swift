//
//  ModuleError.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 24/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/// An error caused when trying to use a `Module`.
public enum ModuleError<SomeError: Error>: ErrorEnum, ErrorWrapping {
    /// The module isn't found when the operation is about to start, either because it's disabled in the
    /// current settings or because it was never added to the `TealiumConfig`. No work was started, so
    /// retrying the operation after the module is enabled can succeed. An operation that already started
    /// fails instead with [`ModuleError.moduleShutdown(_:)`](doc:ModuleError/moduleShutdown(_:)).
    case moduleNotEnabled(_ module: String)
    /// The module was found and had started an operation, but was shut down - either together with the
    /// `Tealium` instance or by a settings update that disabled it - before the operation could complete.
    /// Only operations that were already in progress fail with this error. An operation requested after a
    /// settings update disabled the module fails instead with
    /// [`ModuleError.moduleNotEnabled(_:)`](doc:ModuleError/moduleNotEnabled(_:)), and one requested after the
    /// `Tealium` instance was shut down fails with
    /// [`ModuleError.tealiumError(_:)`](doc:ModuleError/tealiumError(_:)) with `.instanceShutdown`.
    case moduleShutdown(_ module: String)
    /// The `Tealium` instance failed to initialize or was shut down before a `Module` operation could be started.
    case tealiumError(_ error: TealiumError)
    /// The module failed to perform a specific operation.
    case underlyingError(_ error: SomeError)
}
