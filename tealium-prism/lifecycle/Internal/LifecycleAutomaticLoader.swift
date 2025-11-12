//
//  LifecycleAutomaticLoader.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 03/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation
#if lifecycle
import TealiumPrismCore
#endif

/// A class used to automatically load `Lifecycle` module in the default modules created by all `Tealium` instances.
public class LifecycleAutomaticLoader: NSObject {

    /// Call this method at the start of the application to affect all `Tealium` instances.
    /// Calling it more than once does nothing.
    @objc
    public static func setup() {
        _ = runOnce
    }

    /// Using Swift's lazy evaluation of a static property we get the same
    /// thread-safety and called-once guarantees as dispatch_once provided.
    private static let runOnce: () = {
        Modules.addDefaultModule(Modules.lifecycle(forcingSettings: nil))
    }()
}
