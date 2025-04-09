//
//  ModuleProxy.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 23/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

public typealias ErrorHandlingCompletion = (Error?) -> Void

/**
 * A `ModuleProxy` is to be used for proxying access to modules that are or were available
 * to access from the main `Tealium` implementation.
 *
 * Any external `Module` implementation that provides functionality expected to be used by a
 * developer should wrap their access to `Tealium` through a `ModuleProxy`.
 */
public class ModuleProxy<Module: TealiumModule> {
    private let onModulesManager: Observable<ModulesManager?>
    private let queue: TealiumQueue

    /**
     * Initialize the `ModuleProxy` for a specific `TealiumModule`.
     *
     * - Parameters:
     *      - onModulesManager: An `Observable` that will only emit 1 `ModulesManager` when it will be created.
     *      The event must be emitted on the `TealiumQueue.worker` queue.
     */
    convenience public init(onModulesManager: Observable<ModulesManager?>) {
        self.init(queue: .worker, onModulesManager: onModulesManager)
    }

    /**
     * Initialize the `ModuleProxy` for a specific `TealiumModule`.
     *
     * - Parameters:
     *      - queue: The `TealiumQueue` onto which events need to be subscribed upon
     *      - onModulesManager: An `Observable` that will only emit 1 `ModulesManager` when it will be created.
     *      The event must be emitted on the same queue as the other parameter.
     */
    init(queue: TealiumQueue, onModulesManager: Observable<ModulesManager?>) {
        self.queue = queue
        self.onModulesManager = onModulesManager
    }

    /**
     * Observe an observable of the `Module` regardless of if the `Module` is currently enabled or not.
     *
     * - parameter transform: The transformation that maps the `Module` to one of it's `Observable`s.
     * - returns: A `Subscribable` for the inner `Observable`.
     */
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

    /**
     * Observe an observable of the `Module` regardless of if the `Module` is currently enabled or not.
     *
     * - parameter keyPath: The `KeyPath` to the `Observable` inside of the `Module`.
     * - returns: A `Subscribable` for the inner `Observable`.
     */
    public func observeModule<Other>(_ keyPath: KeyPath<Module, Observable<Other>>) -> any Subscribable<Other> {
        observeModule { module in
            module[keyPath: keyPath]
        }
    }

    /**
     * Retrieves the `Module`, providing it in the `completion`.
     *
     * - parameter completion: The block of code to receive the `Module` in, if present, or nil.
     */
    public func getModule(completion: @escaping (Module?) -> Void) {
        _ = onModulesManager
            .first()
            .subscribeOn(queue)
            .subscribe { manager in
                completion(manager?.getModule())
            }
    }

    /**
     * Executes task for the `Module` and calls the completion block either with `nil` or `error` (if task throws or module is disabled).
     *
     * Example of usage inside a custom module wrapper:
     *
     *     class MyModuleWrapper {
     *         private let moduleProxy: ModuleProxy<MyModule>
     *         init(moduleProxy: ModuleProxy<MyModule>) {
     *             self.moduleProxy = moduleProxy
     *         }
     *         func doStuff(_ completion: ErrorHandlingCompletion? = nil) {
     *             moduleProxy.executeModuleTask({ module in
     *                 module.doStuff()
     *             }, completion: completion)
     *         }
     *         func throwStuff(_ completion: ErrorHandlingCompletion? = nil) {
     *             moduleProxy.executeModuleTask({ module in
     *                 try module.throwStuff()
     *             }, completion: completion)
     *         }
     *     }
     *
     * - Parameters:
     *   - task: the task to be executed if module is enabled
     *   - completion: the completion block to handle an optional error
     */
    public func executeModuleTask(_ task: @escaping (Module) throws -> Void, completion: ErrorHandlingCompletion?) {
            getModule { module in
                guard let module else {
                    completion?(TealiumError.moduleNotEnabled)
                    return
                }
                do {
                    try task(module)
                    completion?(nil)
                } catch {
                    completion?(error)
                }
            }
        }
}
