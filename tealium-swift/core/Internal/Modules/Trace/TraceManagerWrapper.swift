//
//  TraceManagerWrapper.swift
//  tealium-swift
//
//  Created by Den Guzov on 04/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

class TraceManagerWrapper: TraceManager {
    private let moduleProxy: ModuleProxy<TraceManagerModule>
    init(moduleProxy: ModuleProxy<TraceManagerModule>) {
        self.moduleProxy = moduleProxy
    }

    public func join(id: String, _ completion: ErrorHandlingCompletion? = nil) {
        moduleProxy.executeModuleTask({ module in
            try module.join(id: id)
        }, completion: completion)
    }

    public func leave(_ completion: ErrorHandlingCompletion? = nil) {
        moduleProxy.executeModuleTask({ module in
            try module.leave()
        }, completion: completion)
    }

    public func killVisitorSession(_ completion: ErrorHandlingCompletion? = nil) {
        moduleProxy.executeModuleTask({ module in
            module.killVisitorSession(completion: completion)
        }, completion: { error in
            if let error {
                completion?(error)
            }
        })
    }
}
