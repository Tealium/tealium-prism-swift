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

    public typealias Task<T> = (_ module: Module) throws -> T
    public typealias AsyncTask<T> = (_ module: Module, _ completion: @escaping (Result<T, Error>) -> Void) throws -> Void

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
     *     func doStuff() -> any Single<Result<SomeValue, Error>> {
     *         moduleProxy.executeModuleTask { module in
     *             module.doStuff() // returns `SomeValue`
     *         }
     *     }
     *     func throwStuff() -> any Single<Result<SomeValue, Error>> {
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
    public func executeModuleTask<T>(_ task: @escaping Task<T>) -> any Single<Result<T, Error>> {
        executeModuleAsyncTask { module, completion in
            do {
                let result = try task(module)
                completion(.success(result))
            } catch {
                completion(.failure(error))
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
     *     func doStuff() -> any Single<Result<SomeValue, Error>> {
     *         moduleProxy.executeModuleTask { module, completion in
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
     *     func doStuff() -> any Single<Result<Void, Error>> {
     *         moduleProxy.executeModuleTask { module, completion in
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
    public func executeModuleAsyncTask<T>(_ asyncTask: @escaping AsyncTask<T>) -> any Single<Result<T, Error>> {
        // Use the replay subject to make the returned Single a HOT observable.
        // A HOT observable doesn't require a subscription to start emitting events.
        let replay = ReplaySubject<Result<T, Error>>()
        _ = SingleImpl(observable: .Callback(from: { [weak self] observer in
            guard let self else {
                observer(.failure(TealiumError.moduleNotEnabled))
                return
            }
            self.getModule { module in
                guard let module else {
                    observer(.failure(TealiumError.moduleNotEnabled))
                    return
                }
                do {
                    try asyncTask(module) { result in
                        observer(result)
                    }
                } catch {
                    observer(.failure(error))
                }
            }
        }),
                   queue: queue)
            .subscribe(replay)
        return replay.asObservable().asSingle(queue: queue)
    }
}
