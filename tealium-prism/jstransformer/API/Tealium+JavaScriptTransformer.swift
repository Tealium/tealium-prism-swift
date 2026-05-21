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
#endif
