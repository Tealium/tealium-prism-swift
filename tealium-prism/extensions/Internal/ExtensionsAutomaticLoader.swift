//
//  ExtensionsAutomaticLoader.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/12/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation
#if extensions
import TealiumPrismCore
#endif

/// A class used to automatically load all Transformers modules in this package in the default modules created by all `Tealium` instances.
public class ExtensionsAutomaticLoader: NSObject {

    /// Call this method at the start of the application to affect all `Tealium` instances.
    /// Calling it more than once does nothing.
    @objc
    public static func setup() {
        _ = runOnce
    }

    /// Using Swift's lazy evaluation of a static property we get the same
    /// thread-safety and called-once guarantees as dispatch_once provided.
    private static let runOnce: () = {
        Modules.addDefaultModule(SetDataValuesTransformer.factory)
        Modules.addDefaultModule(PersistDataValueTransformer.factory)
        Modules.addDefaultModule(LowercaseTransformer.factory)
    }()
}
