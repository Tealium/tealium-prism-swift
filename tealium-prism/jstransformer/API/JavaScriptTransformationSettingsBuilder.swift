//
//  JavaScriptTransformationSettingsBuilder.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 18/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

#if !os(watchOS)
import Foundation
import JavaScriptCore
#if jstransformer
import TealiumPrismCore
#endif

/// Builder for creating `TransformationSettings` that configure a JavaScript transformation.
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
/// Usage:
/// ```swift
/// let settings = JavaScriptTransformationSettingsBuilder(id: "my-transform")
///     .setJsCode("payload.custom_key = 'value'")
///     .setScope(.afterCollectors)
///     .build()
/// ```
public class JavaScriptTransformationSettingsBuilder: TransformationSettingsBuilder {
    var code: String?
    enum Keys {
        static let code = "js_code"
    }

    /// Creates a new builder for a JavaScript transformation.
    /// - Parameter id: Unique identifier for this transformation.
    public init(id: String) {
        super.init(id: id, transformerId: Modules.Types.javaScriptTransformer)
    }

    /// Sets the JavaScript code to execute against each dispatch payload.
    ///
    /// See the class-level documentation for the full list of available globals.
    ///
    /// - Parameter code: A JavaScript code string.
    /// - Returns: `self` for chaining.
    public func setJsCode(_ code: String) -> Self {
        self.code = code
        return self
    }

    override public func build() -> DataObject {
        let config = DataObject(compacting: [Keys.code: code])
        if !config.keys.isEmpty {
            _setConfiguration(config)
        }
        return super.build()
    }
}
#endif
