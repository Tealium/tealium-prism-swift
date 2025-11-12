//
//  DeepLinkHandlerWrapper.swift
//  tealium-prism
//
//  Created by Den Guzov on 15/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

public class DeepLinkHandlerWrapper: DeepLinkHandler {
    private let moduleProxy: ModuleProxy<DeepLinkModule, Error>

    init(moduleProxy: ModuleProxy<DeepLinkModule, Error>) {
        self.moduleProxy = moduleProxy
    }

    @discardableResult
    public func handle(link: URL, referrer: Referrer? = nil) -> SingleResult<Void, ModuleError<Error>> {
        moduleProxy.executeModuleTask { module in
            try module.handle(link: link, referrer: referrer)
        }
    }
}
