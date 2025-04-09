//
//  LifecycleWrapper.swift
//  tealium-swift
//
//  Created by Den Guzov on 28/11/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

class LifecycleWrapper: Lifecycle {
    private let moduleProxy: ModuleProxy<LifecycleModule>
    init(moduleProxy: ModuleProxy<LifecycleModule>) {
        self.moduleProxy = moduleProxy
    }

    public func launch(_ event: DataObject?, _ completion: ErrorHandlingCompletion? = nil) {
        moduleProxy.executeModuleTask({ module in
            try module.launch(data: event)
        }, completion: completion)
    }

    public func wake(_ event: DataObject?, _ completion: ErrorHandlingCompletion? = nil) {
        moduleProxy.executeModuleTask({ module in
            try module.wake(data: event)
        }, completion: completion)
    }

    public func sleep(_ event: DataObject?, _ completion: ErrorHandlingCompletion? = nil) {
        moduleProxy.executeModuleTask({ module in
            try module.sleep(data: event)
        }, completion: completion)
    }
}
