//
//  LifecycleWrapper.swift
//  tealium-swift
//
//  Created by Den Guzov on 28/11/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

class LifecycleWrapper: Lifecycle {
    typealias Module = LifecycleModule
    private let moduleProxy: ModuleProxy<Module>
    init(moduleProxy: ModuleProxy<Module>) {
        self.moduleProxy = moduleProxy
    }

    private func getModule(completion: @escaping (Module?) -> Void) {
        moduleProxy.getModule(completion: completion)
    }

    private func handleEvent(completion: ((Error?) -> Void)?, handler: @escaping (LifecycleModule) throws -> Void) {
        getModule { lifecycleModule in
            guard let lifecycleModule else {
                completion?(TealiumError.moduleNotEnabled)
                return
            }
            do {
                try handler(lifecycleModule)
                completion?(nil)
            } catch {
                completion?(error)
            }
        }
    }

    public func launch(_ event: DataObject?, _ completion: ((Error?) -> Void)? = nil) {
        handleEvent(completion: completion) { lifecycleModule in
            try lifecycleModule.launch(data: event)
        }

    }

    public func wake(_ event: DataObject?, _ completion: ((Error?) -> Void)? = nil) {
        handleEvent(completion: completion) { lifecycleModule in
            try lifecycleModule.wake(data: event)
        }
    }

    public func sleep(_ event: DataObject?, _ completion: ((Error?) -> Void)? = nil) {
        handleEvent(completion: completion) { lifecycleModule in
            try lifecycleModule.sleep(data: event)
        }
    }
}
