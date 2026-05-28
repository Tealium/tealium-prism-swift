//
//  JSContext+Subscripts.swift
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

extension JSContext {
    subscript(_ key: NSString) -> JSValue? {
        objectForKeyedSubscript(key)
    }

    subscript(_ key: NSString) -> Any? {
        get { return objectForKeyedSubscript(key) }
        set { setObject(newValue, forKeyedSubscript: key) }
    }
}

extension JSValue {
    subscript(_ key: NSString) -> JSValue? {
        objectForKeyedSubscript(key)
    }

    subscript(_ key: NSString) -> Any? {
        get { return objectForKeyedSubscript(key) }
        set { setObject(newValue, forKeyedSubscript: key) }
    }
}
#endif
