//
//  Tealium+JavaScriptTransformer.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

#if !os(watchOS)
import Foundation
#if jstransformer
import TealiumPrismCore
#endif

public extension Modules.Types {
    /// Module type identifier for the JavaScript Transformer.
    static let javaScriptTransformer = "JavaScriptTransformer"
}

public extension Modules {
    /// Creates a `ModuleFactory` for the JavaScript Transformer module.
    ///
    /// The JavaScript Transformer executes user-provided JavaScript code against each dispatch payload
    /// using Apple's JavaScriptCore engine. The following globals are available inside the JS code:
    ///
    /// - `payload` – mutable object representing the dispatch data; modifications are reflected in the result.
    /// - `scope` – string indicating the current `DispatchScope` (e.g. `"aftercollectors"`).
    /// - `track(...)` – triggers a new SDK track call from within JS. Supported signatures:
    ///   - `track(event)` – tracks an event with the given name.
    ///   - `track(event, payload)` – tracks an event with additional data (2nd arg must be an object).
    ///   - `track(event, type)` – tracks an event with a specific type string (e.g. `"view"`).
    ///   - `track(event, type, payload)` – tracks an event with type and additional data.
    /// - `drop()` – sets `payload` to `undefined`, causing the dispatch to be dropped.
    /// - `dataLayer` – read/write access to the persistent data layer (`get`, `getAll`, `put`, `remove`, `clear`).
    /// - `console` – logging bridge (`debug`, `log`, `info`, `warn`, `error`).
    /// - `Expiry` – constants for data expiry (`forever`, `session`, `untilRestart`).
    ///
    /// - Parameter block: Optional closure to enforce module-level settings.
    /// - Returns: A `ModuleFactory` that produces `JavaScriptTransformer` instances.
    static func javaScriptTransformer(forcingSettings block: EnforcingSettings<ModuleSettingsBuilder> = { $0 }) -> some ModuleFactory {
        BasicModuleFactory<JavaScriptTransformer>(moduleType: Modules.Types.javaScriptTransformer,
                                                  enforcedSettings: block(ModuleSettingsBuilder()).build())
    }
}
#endif
