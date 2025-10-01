//
//  ModuleProxy.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 23/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A `ModuleProxy` is to be used for proxying access to modules that are or were available
 * to access from the main `Tealium` implementation.
 *
 * Any external `Module` implementation that provides functionality expected to be used by a
 * developer should wrap their access to `Tealium` through a `ModuleProxy`.
 */
public class ModuleProxy<SpecificModule: Module> {
    private let onModulesManager: Observable<ModulesManager?>

    public typealias ModuleTask<T> = (_ module: SpecificModule) throws -> T
    public typealias AsyncModuleTask<T> = (
        _ module: SpecificModule,
        _ completion: @escaping (Result<T, Error>) -> Void
    ) throws -> Void
    let asyncProxy: AsyncProxy<SpecificModule>

    /**
     * Initialize the `ModuleProxy` for a specific `Module`.
     *
     * - Parameters:
     *      - queue: The `TealiumQueue` onto which events need to be subscribed upon
     *      - onModulesManager: An `Observable` that will only emit 1 `ModulesManager` when it will be created.
     *      The event must be emitted on the same queue as the other parameter.
     */
    init(queue: TealiumQueue, onModulesManager: Observable<ModulesManager?>) {
        self.onModulesManager = onModulesManager
        let onModule: Observable<Result<SpecificModule, Error>> = onModulesManager.map { manager in
            guard let manager else {
                return .failure(TealiumError.objectNotFound(ModulesManager.self))
            }
            guard let module = manager.getModule(SpecificModule.self) else {
                return .failure(TealiumError.moduleNotEnabled(SpecificModule.self))
            }
            return .success(module)
        }
        self.asyncProxy = AsyncProxy(queue: queue,
                                     onObject: onModule)
    }

    /**
     * Observe an observable of the `Module` regardless of if the `Module` is currently enabled or not.
     *
     * - parameter transform: The transformation that maps the `Module` to one of it's `Observable`s.
     * - returns: A `Subscribable` for the inner `Observable`.
     */
    public func observeModule<Other>(transform: @escaping (SpecificModule) -> Observable<Other>) -> any Subscribable<Other> {
        onModulesManager.flatMapLatest { $0?.modules.asObservable() ?? .Empty() }
            .map { $0.compactMap { $0 as? SpecificModule }.first }
            .distinct { $0 === $1 }
            .flatMapLatest { module in
                guard let module else {
                    return .Empty()
                }
                return transform(module)
            }
            .subscribeOn(asyncProxy.queue)
    }

    /**
     * Observe an observable of the `Module` regardless of if the `Module` is currently enabled or not.
     *
     * - parameter keyPath: The `KeyPath` to the `Observable` inside of the `Module`.
     * - returns: A `Subscribable` for the inner `Observable`.
     */
    public func observeModule<Other>(_ keyPath: KeyPath<SpecificModule, Observable<Other>>) -> any Subscribable<Other> {
        observeModule { module in
            module[keyPath: keyPath]
        }
    }

    /**
     * Retrieves the `Module`, providing it in the `completion`.
     *
     * - parameter completion: The block of code to receive the `Module` in, if present, or nil.
     */
    public func getModule(completion: @escaping (SpecificModule?) -> Void) {
        asyncProxy.getProxiedObject(completion: completion)
    }

    /**
     * Executes a task for the `Module` and returns a `Single` with the `Result`.
     *
     * Example of usage inside a custom module wrapper:
     *
     * ```swift
     * class MyModuleWrapper {
     *     private let moduleProxy: ModuleProxy<MyModule>
     *     init(moduleProxy: ModuleProxy<MyModule>) {
     *         self.moduleProxy = moduleProxy
     *     }
     *     func doStuff() -> SingleResult<SomeValue> {
     *         moduleProxy.executeModuleTask { module in
     *             module.doStuff() // returns `SomeValue`
     *         }
     *     }
     *     func throwStuff() -> SingleResult<SomeValue> {
     *         moduleProxy.executeModuleTask { module in
     *             try module.throwStuff() // throws an `Error`
     *         }
     *     }
     * }
     * ```
     *
     * - Parameters:
     *   - task: the task to be executed if module is enabled
     * - Returns: the `Single` with the `Result`
     */
    public func executeModuleTask<T>(_ task: @escaping ModuleTask<T>) -> SingleResult<T> {
        asyncProxy.executeTask(task)
    }

    /**
     * Executes an async task for the `Module` and returns a `Single` with the `Result`.
     *
     * Example of usage inside a custom module wrapper:
     *
     * ```swift
     * class MyModuleWrapper {
     *     private let moduleProxy: ModuleProxy<MyModule>
     *     init(moduleProxy: ModuleProxy<MyModule>) {
     *         self.moduleProxy = moduleProxy
     *     }
     *     func doStuff() -> SingleResult<SomeValue> {
     *         moduleProxy.executeAsyncModuleTask { module, completion in
     *             module.doStuff(completion: completion) // Completes with a `Result<SomeValue, Error>`
     *         }
     *     }
     * }
     * ```
     *
     * Note that the completion of the module method needs to be with a `Result` as well
     * or the completion parameter needs to be converted to one like so:
     *
     * ```swift
     * class MyModuleWrapper {
     *     private let moduleProxy: ModuleProxy<MyModule>
     *     init(moduleProxy: ModuleProxy<MyModule>) {
     *         self.moduleProxy = moduleProxy
     *     }
     *     func doStuff() -> SingleResult<Void> {
     *         moduleProxy.executeAsyncModuleTask { module, completion in
     *             module.doStuff { optionalData, optionalError in
     *                  if let data = optionalData {
     *                      completion(.success(data))
     *                  } else if error = optionalError {
     *                      completion(.failure(error))
     *                  } else {
     *                      completion(.failure(TealiumError.genericError("Unexpected completion data")
     *                  }
     *             }
     *         }
     *     }
     * }
     * ```
     * - Parameters:
     *   - task: the task to be executed if module is enabled
     * - Returns: the `Single` with the `Result`.
     */
    public func executeAsyncModuleTask<T>(_ asyncTask: @escaping AsyncModuleTask<T>) -> SingleResult<T> {
        asyncProxy.executeAsyncTask(asyncTask)
    }
}
