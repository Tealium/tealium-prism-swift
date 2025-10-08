//
//  LifecycleAutomaticLoader.swift
//  tealium-prism-Core-Lifecycle
//
//  Created by Enrico Zannini on 03/10/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation
#if lifecycle
import TealiumPrismCore
#endif

public class LifecycleAutomaticLoader: NSObject {

    @objc
    public static func setup() {
        _ = runOnce
    }

    /// Using Swift's lazy evaluation of a static property we get the same
    /// thread-safety and called-once guarantees as dispatch_once provided.
    private static let runOnce: () = {
        TealiumConfig.addDefaultModule(Modules.lifecycle(forcingSettings: nil))
    }()
}
