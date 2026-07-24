//
//  TealiumInstanceManager.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 29/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

/**
 * A class that creates and stores all the created `Tealium` instances and reuses all of its dependencies
 * when a new instance is created with the same `account` and `profile`.
 *
 * All references to created `Tealium` instances are kept strong, so an instance stays alive until it is
 * explicitly shut down via `Tealium.shutdown()` or `TealiumInstanceManager.shutdown(_:)`. Dropping the
 * reference returned by `create(config:completion:)` does not deallocate the instance.
 */
public class TealiumInstanceManager {
    let queue: TealiumQueue
    var instances = [String: TealiumComponents]()
    init(queue: TealiumQueue = .worker) {
        self.queue = queue
    }

    /// The shared `TealiumInstanceManager` object.
    public static let shared = TealiumInstanceManager()

    /**
     * Creates a new `Tealium` instance based on the provided `config`.
     *
     * Typical usage in an app would keep the returned instance alive for as long as the app is alive.
     * However, the instance is retained by the manager regardless, so it will stay alive until it is
     * explicitly shut down via `Tealium.shutdown()` or `shutdown(_:)`.
     *
     * Calling this method with a `config` whose `TealiumConfig.key` matches an already created instance
     * returns a new `Tealium` that shares the same underlying implementation.
     *
     * - Important: Hold onto the returned `Tealium` instance for as long as you need it. Calling this
     * method again with the same `account`/`profile` combination is supported, but each duplicate call
     * allocates a small amount of internal state (a subject/subscription pair) that lives until
     * `shutdown()`. Prefer storing and reusing the original return value instead.
     *
     * - Parameters:
     *      - config: The required configuration options for this instance.
     *      - completion: The callback allows the caller to be notified once the instance is ready, or has
     * failed during initialization alongside the cause of the failure.
     *
     * - Returns: The `Tealium` instance ready to accept input, although if the initialization fails, any method calls made to this object will also fail.
     */
    public func create(config: TealiumConfig, completion: ((InitializationResult<Tealium>) -> Void)? = nil) -> Tealium {
        let proxySubject = ReplaySubject<InitializationResult<TealiumImpl>>()
        let teal = Tealium(key: config.key,
                           queue: queue,
                           onTealiumImplementation: proxySubject.asObservable(),
                           onShutdown: { [weak self] key in self?.shutdown(key) })
        queue.ensureOnQueue { [weak self] in
            guard let self else { return }
            if let components = instances[config.key] {
                components.instance.context
                    .logger?.warn(category: LogCategory.tealium,
                                  "Duplicate Tealium instance requested for \(config.key). Returning existing one.")
                // Each duplicate proxy must be subscribed to instanceSubject so it receives the
                // shutdown sentinel and can surface TealiumError.instanceShutdown to callers. The
                // subscription is torn down from the source side when instanceSubject completes.
                _ = components.instanceSubject.subscribe(proxySubject)
                completion?(.success(teal))
            } else {
                createComponents(config: config, proxy: teal, proxySubject: proxySubject, completion: completion)
            }
        }
        return teal
    }

    /**
     * Creates a new `TealiumImpl` for the given `config`, stores its `TealiumComponents` and wires the
     * shared instance subject into the given `proxySubject`.
     *
     * Must be called on `queue`.
     */
    private func createComponents(config: TealiumConfig,
                                  proxy: Tealium,
                                  proxySubject: ReplaySubject<InitializationResult<TealiumImpl>>,
                                  completion: ((InitializationResult<Tealium>) -> Void)?) {
        let instanceSubject = ReplaySubject<InitializationResult<TealiumImpl>>()
        do {
            let instance = try TealiumImpl(config, queue: queue)
            let components = TealiumComponents(instance: instance,
                                               instanceSubject: instanceSubject,
                                               proxy: proxy)
            instances[config.key] = components
            instanceSubject.onNext(.success(instance))
            _ = instanceSubject.subscribe(proxySubject)
            completion?(.success(proxy))
        } catch {
            proxySubject.onNext(.failure(error))
            completion?(.failure(error))
        }
    }

    /**
     * Shuts down the given `Tealium` instance.
     *
     * After calling this method, no further input will be processed and future method calls to the
     * instance will fail with `TealiumError.instanceShutdown`.
     *
     * - Parameter tealium: The `Tealium` instance to shut down.
     */
    public func shutdown(_ tealium: Tealium) {
        shutdown(tealium.key)
    }

    /**
     * Shuts down the `Tealium` instance identified by the given `key`.
     *
     * After calling this method, no further input will be processed and future method calls to the
     * instance will fail with `TealiumError.instanceShutdown`.
     *
     * - Parameter key: The key that identifies the `Tealium` instance, as provided by `TealiumConfig.key`.
     */
    public func shutdown(_ key: String) {
        queue.ensureOnQueue { [weak self] in
            guard let components = self?.instances.removeValue(forKey: key) else { return }
            components.instance.shutdown()
            // Propagate the shutdown to any live proxies so their subsequent calls fail with
            // `TealiumError.instanceShutdown`, then complete the subject: `onComplete` tears down all
            // proxy bridge subscriptions from the source side and signals downstream operators.
            components.instanceSubject.onNext(.failure(InstanceShutdownError()))
            components.instanceSubject.onComplete()
        }
    }

    /**
     * Retrieves an existing `Tealium` instance, if one has already been created using its `TealiumConfig.key` and has not been shut down.
     *
     * - Parameters:
     *      - config: The config that was used to create the instance.
     *      - completion: The block to receive the `Tealium` instance on, if found.
     */
    public func get(_ config: TealiumConfig, completion: @escaping (Tealium?) -> Void) {
        get(config.key, completion: completion)
    }

    /**
     * Retrieves an existing `Tealium` instance, if one has already been created using its `TealiumConfig.key` and has not been shut down.
     *
     * - Parameters:
     *      - key: The key that identifies the `Tealium` instance.
     *      - completion: The block to receive the `Tealium` instance on, if found.
     */
    public func get(_ key: String, completion: @escaping (Tealium?) -> Void) {
        queue.ensureOnQueue { [weak self] in
            completion(self?.instances[key]?.proxy)
        }
    }
}

/**
 * Holds the strong references required to keep a single `TealiumImpl` alive alongside the first
 * `Tealium` proxy created for it.
 *
 * Each `Tealium` proxy created for this instance is bridged to `instanceSubject`. Those bridge
 * subscriptions are torn down when `instanceSubject.onComplete()` is called on shutdown.
 */
struct TealiumComponents {
    let instance: TealiumImpl
    let instanceSubject: ReplaySubject<InitializationResult<TealiumImpl>>
    let proxy: Tealium
}

/// Internal sentinel emitted on an instance's implementation observable when it is shut down, so the
/// public `Tealium` can surface it as `TealiumError.instanceShutdown`.
struct InstanceShutdownError: Error {}
