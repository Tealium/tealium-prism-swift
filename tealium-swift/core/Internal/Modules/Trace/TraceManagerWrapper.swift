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

    @discardableResult
    public func join(id: String) -> any Single<Result<Void, Error>> {
        moduleProxy.executeModuleTask { module in
            try module.join(id: id)
        }
    }

    @discardableResult
    public func leave() -> any Single<Result<Void, Error>> {
        moduleProxy.executeModuleTask { module in
            try module.leave()
        }
    }

    @discardableResult
    public func killVisitorSession() -> any Single<Result<TrackResult, Error>> {
        moduleProxy.executeModuleAsyncTask { module, completion in
            try module.killVisitorSession { result in
                completion(.success(result))
            }
        }
    }
}
