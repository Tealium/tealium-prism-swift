//
//  LifecycleWrapper.swift
//  tealium-prism
//
//  Created by Den Guzov on 28/11/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

#if lifecycle
import TealiumCore
#endif

class LifecycleWrapper: Lifecycle {
    private let moduleProxy: ModuleProxy<LifecycleModule>
    init(moduleProxy: ModuleProxy<LifecycleModule>) {
        self.moduleProxy = moduleProxy
    }

    @discardableResult
    func launch(_ event: DataObject?) -> SingleResult<Void> {
        moduleProxy.executeModuleTask { module in
            try module.launch(data: event)
        }
    }

    @discardableResult
    func wake(_ event: DataObject?) -> SingleResult<Void> {
        moduleProxy.executeModuleTask { module in
            try module.wake(data: event)
        }
    }

    @discardableResult
    func sleep(_ event: DataObject?) -> SingleResult<Void> {
        moduleProxy.executeModuleTask { module in
            try module.sleep(data: event)
        }
    }
}
