//
//  VisitorIdProviderWrapper.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 24/08/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

/// Implements the public `VisitorIdProvider` by delegating to `VisitorIdProviderModule` through a `ModuleProxy`.
class VisitorIdProviderWrapper: VisitorIdProvider {
    let onVisitorId: any Subscribable<String>
    private let moduleProxy: ModuleProxy<VisitorIdProviderModule, Error>

    init(moduleProxy: ModuleProxy<VisitorIdProviderModule, Error>) {
        self.moduleProxy = moduleProxy
        onVisitorId = moduleProxy.observeModule { module in module.storage.visitorId }
    }

    func getVisitorId() -> SingleResult<String, ModuleError<Error>> {
        moduleProxy.executeModuleTask { module in
            module.getVisitorId()
        }
    }

    @discardableResult
    func reset() -> SingleResult<String, ModuleError<Error>> {
        moduleProxy.executeModuleTask { module in
            try module.reset()
        }
    }

    @discardableResult
    func clearStored() -> SingleResult<String, ModuleError<Error>> {
        moduleProxy.executeModuleTask { module in
            try module.clearStored()
        }
    }
}
