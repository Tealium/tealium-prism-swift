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
/// Usage:
/// ```swift
/// let settings = JavaScriptTransformationSettingsBuilder(id: "my-transform")
///     .setJsCode("payload.custom_key = 'value'")
///     .addScope(.afterCollectors)
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
    /// Beyond `payload`, the JS environment exposes additional globals: `scope`, `track(...)`, `drop()`,
    /// `dataLayer`, `network`, `console`, and `Expiry`. See [`Modules.javaScriptTransformer(forcingSettings:)`](doc:Modules/javaScriptTransformer(forcingSettings:))
    /// for the full list and description of each global.
    ///
    /// - Parameter code: A JavaScript code string.
    /// - Returns: `self` for chaining.
    public func setJsCode(_ code: String) -> Self {
        self.code = code
        return self
    }

    override public func build() -> TransformationSettings {
        _ = _setConfiguration(DataObject(compacting: [Keys.code: code]))
        return super.build()
    }
}
#endif
