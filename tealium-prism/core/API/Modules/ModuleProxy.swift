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
public class ModuleProxy<SpecificModule: Module, Failure: Error> {
    private let onModuleManager: Observable<ModuleManager?>
    private let onModuleManagerResult: Observable<Result<ModuleManager, TealiumError>>

    /// A synchronous task that can be executed on a module.
    public typealias ModuleTask<T> = (_ module: SpecificModule) throws(Failure) -> T
    /// An asynchronous task that can be executed on a module.
    public typealias AsyncModuleTask<T> = (
        _ module: SpecificModule,
        _ completion: @escaping (Result<T, ModuleError<Failure>>) -> Void
    ) throws(Failure) -> Void
    let asyncProxy: AsyncProxy<SpecificModule, ModuleError<Failure>>

    /**
     * Initialize the `ModuleProxy` for a specific `Module`.
     *
     * - Parameters:
     *      - queue: The `TealiumQueue` onto which events need to be subscribed upon
     *      - onModuleManager: An `Observable` that emits the result of the `Tealium` initialization: either the
     *      `ModuleManager` once it's created, or the `TealiumError` if initialization failed or the instance was
     *      shut down. The event must be emitted on the same queue as the other parameter.
     */
    init(queue: TealiumQueue, onModuleManager: Observable<Result<ModuleManager, TealiumError>>) {
        self.onModuleManagerResult = onModuleManager
        self.onModuleManager = onModuleManager.map { try? $0.get() }
        let onModule: Observable<Result<SpecificModule, ModuleError<Failure>>> = onModuleManager.flatMapLatest { managerResult in
            switch managerResult {
            case let .success(manager):
                return manager.observeModule(SpecificModule.self)
                    .first()
                    .map { module in
                        guard let module else {
                            return .failure(ModuleError.moduleNotEnabled(SpecificModule.moduleType))
                        }
                        return .success(module)
                    }
            case let .failure(error):
                return Observables.just(.failure(ModuleError.tealiumError(error)))
            }
        }
        self.asyncProxy = AsyncProxy(queue: queue,
                                     onObject: onModule)
    }

    /**
     * Observes an `Observable` derived from the `Module`, re-deriving it as the module's availability changes.
     *
     * Use this for state streams, where subscribers must know when the module is unavailable. For event streams,
     * use [`observeModule(transform:)`](doc:ModuleProxy/observeModule(transform:)) instead.
     *
     * The stream emits nothing until the `ModuleManager` is ready. Once it is, it emits `.success` with the
     * value produced by `transform` while the module is enabled, and `.failure` with
     * [`ModuleError.moduleNotEnabled(_:)`](doc:ModuleError/moduleNotEnabled(_:)) while the module is disabled
     * or missing - switching back to `.success` if the module is re-enabled. If the `Tealium` instance failed
     * to initialize, or is later shut down, this emits a single `.failure` with
     * [`ModuleError.tealiumError(_:)`](doc:ModuleError/tealiumError(_:)) and then completes.
     *
     * Values the module emits while the `Tealium` instance is shutting down are not delivered: the terminal
     * [`ModuleError.tealiumError(_:)`](doc:ModuleError/tealiumError(_:)) is the last value a subscriber receives.
     *
     * - parameter transform: The transformation that maps the `Module` to one of its `Observable`s.
     * - returns: A `Subscribable` for the transformed `Result`.
     */
    public func observeModuleResult<Other>(
        transform: @escaping (SpecificModule) -> Observable<Other>
    ) -> some Subscribable<Result<Other, ModuleError<Failure>>> {
        transformedModuleResults(transform: transform)
            .subscribeOn(asyncProxy.queue)
    }

    /// The `Module` availability with `transform` applied: the transformed values as `.success` while the module is
    /// available, its unavailability as a `.failure`. Shared by `observeModuleResult` and `observeModule`.
    private func transformedModuleResults<Other>(
        transform: @escaping (SpecificModule) -> Observable<Other>
    ) -> Observable<Result<Other, ModuleError<Failure>>> {
        onModuleManagerResult.flatMapLatest { managerResult -> Observable<Result<Other, ModuleError<Failure>>> in
            switch managerResult {
            case let .success(manager):
                return manager.observeModule(SpecificModule.self)
                    .flatMapLatest { module -> Observable<Result<Other, ModuleError<Failure>>> in
                        guard let module else {
                            return Observables.just(.failure(.moduleNotEnabled(SpecificModule.moduleType)))
                        }
                        return transform(module).map { .success($0) }
                    }
            case let .failure(error):
                return Observables.just(.failure(.tealiumError(error)))
            }
        }
    }

    /**
     * Observes an `Observable` derived from the `Module`, re-deriving it as the module's availability changes.
     *
     * Use this for event streams: it emits only while the module is enabled, stays silent while it is disabled
     * or missing, and completes when the `Tealium` instance fails to initialize or is shut down. For state streams,
     * where subscribers must know the module is unavailable, use
     * [`observeModuleResult(transform:)`](doc:ModuleProxy/observeModuleResult(transform:)) instead.
     *
     * Values the module emits while the `Tealium` instance is shutting down are not delivered: the completion is
     * the last event a subscriber receives.
     *
     * - parameter transform: The transformation that maps the `Module` to one of it's `Observable`s.
     * - returns: A `Subscribable` for the inner `Observable`.
     */
    public func observeModule<Other>(transform: @escaping (SpecificModule) -> Observable<Other>) -> some Subscribable<Other> {
        transformedModuleResults(transform: transform)
            .compactMap { try? $0.get() }
            .subscribeOn(asyncProxy.queue)
    }

    /**
     * Observe an observable derived from every `SpecificModule` instance currently registered.
     *
     * Use this when a module type may be registered multiple times (for example, multiple
     * MomentsAI instances for different use cases) and the caller needs to react to the full
     * set of instances. The `transform` receives the current list and returns the `Observable`
     * to expose; it re-runs whenever the set changes by identity.
     *
     * - parameter transform: Maps the current list of instances to an `Observable`.
     * - returns: A `Subscribable` for the inner `Observable`.
     */
    public func observeModules<Other>(transform: @escaping ([SpecificModule]) -> Observable<Other>) -> any Subscribable<Other> {
        onModuleManager.flatMapLatest { moduleManager in
            guard let moduleManager else {
                return Observables.empty()
            }
            return moduleManager.observeModules { $0 as? SpecificModule }
                .flatMapLatest(transform)
        }.subscribeOn(asyncProxy.queue)
    }

    /**
     * Retrieves the `Module`, providing it in the `completion`.
     *
     * The `completion` receives `nil` whenever the module isn't available. Use `executeModuleTask { $0 }` to get
     * the `ModuleError` that explains why.
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
     * Fails with a `ModuleError` if the task can't be run or fails: see `ModuleError` for the meaning of each case.
     *
     * - Parameters:
     *   - task: the task to be executed if module is enabled
     * - Returns: the `Single` with the `Result`
     */
    public func executeModuleTask<T>(_ task: @escaping ModuleTask<T>) -> SingleResult<T, ModuleError<Failure>> {
        asyncProxy.executeTask { object throws(ModuleError<Failure>) in
            try ModuleError<Failure>.wrapErrors { () throws(Failure) -> T in
                return try task(object)
            }
        }
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
     *
     * Fails with a `ModuleError` if the task can't be run or fails: see `ModuleError` for the meaning of each case.
     *
     * - Parameters:
     *   - task: the task to be executed if module is enabled
     * - Returns: the `Single` with the `Result`.
     */
    public func executeAsyncModuleTask<T>(_ asyncTask: @escaping AsyncModuleTask<T>) -> SingleResult<T, ModuleError<Failure>> {
        asyncProxy.executeAsyncTask { object, completion throws(ModuleError<Failure>) in
            try ModuleError<Failure>.wrapErrors { () throws(Failure) in
                try asyncTask(object, completion)
            }
        }
    }
}
