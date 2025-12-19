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

public class JavaScriptTransformationSettingsBuilder: TransformationSettingsBuilder {
    var code = ""
    enum Keys {
        static let code = "js_code"
    }

    public init(id: String) {
        super.init(id: id, transformerId: Modules.Types.javaScriptTransformer)
    }

    public func setJsCode(_ code: String) -> Self {
        self.code = code
        return self
    }

    override public func build() -> TransformationSettings {
        _ = _setConfiguration([Keys.code: code])
        return super.build()
    }
}
#endif
