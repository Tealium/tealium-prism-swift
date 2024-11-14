//
//  ModuleProxy.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 23/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

public class ModuleProxy<Module: TealiumModule> {
    private let onModulesManager: Observable<ModulesManager?>
    private let queue: TealiumQueue
    init(queue: TealiumQueue = TealiumQueue.worker, onModulesManager: Observable<ModulesManager?>) {
        self.queue = queue
        self.onModulesManager = onModulesManager
    }
    public func observeModule<Other>(transform: @escaping (Module) -> Observable<Other>) -> any Subscribable<Other> {
        onModulesManager.flatMapLatest { $0?.modules.asObservable() ?? .Empty() }
            .map { $0.compactMap { $0 as? Module }.first }
            .distinct { $0 === $1 }
            .flatMapLatest { module in
                guard let module else {
                    return .Empty()
                }
                return transform(module)
            }
            .subscribeOn(queue)
    }
    public func getModule(completion: @escaping (Module?) -> Void) {
        _ = onModulesManager
            .first()
            .subscribeOn(queue)
            .subscribe { manager in
                completion(manager?.getModule())
            }
    }
}
