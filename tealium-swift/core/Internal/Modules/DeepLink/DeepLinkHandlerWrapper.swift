//
//  DeepLinkHandlerWrapper.swift
//  tealium-swift
//
//  Created by Den Guzov on 15/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

public class DeepLinkHandlerWrapper: DeepLinkHandler {
    typealias Module = DeepLinkHandlerModule
    private let moduleProxy: ModuleProxy<Module>

    init(moduleProxy: ModuleProxy<Module>) {
        self.moduleProxy = moduleProxy
    }

    @discardableResult
    public func handle(link: URL, referrer: Referrer? = nil) -> any Single<Result<Void, Error>> {
        moduleProxy.executeModuleTask { module in
            try module.handle(link: link, referrer: referrer)
        }
    }
}
