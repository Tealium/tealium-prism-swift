//
//  TealiumInstanceManager.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 29/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

/**
 * A class that creates and stores all the created `Tealium` instances and reuse all of its dependencies
 * when a new instance is created with the same `account` and `profile`.
 *
 * All references to created `Tealium` instances are kept weak so that an app that removes all their references
 * to a `Tealium` instance will automatically deallocate that instance.
 */
public class TealiumInstanceManager {
    let queue = TealiumQueue.worker
    struct Weak<T: AnyObject> {
        weak var value: T?
    }
    var proxies = [String: Weak<Tealium>]()
    var instances = [String: Weak<TealiumImpl>]()
    private init() { }

    /// The shared `TealiumInstanceManager` object.
    public static let shared = TealiumInstanceManager()

    func createImplementation(config: TealiumConfig) -> Tealium.ImplementationObservable {
        let subject = ReplaySubject<Tealium.ImplementationResult>()
        queue.ensureOnQueue { [weak self] in
            guard let self else { return }
            if let instance = instances[config.key]?.value {
                instance.context
                    .logger?.warn(category: LogCategory.tealium,
                                  "Duplicate Tealium instance requested for \(config.key). Returning existing one.")
                subject.publish(.success(instance))
            } else {
                do {
                    let instance = try TealiumImpl(config)
                    instances[config.key] = Weak(value: instance)
                    subject.publish(.success(instance))
                } catch {
                    subject.publish(.failure(TealiumInitializationError(underlyingError: error)))
                }
            }
        }
        return subject.asObservable()
    }

    /**
     * Creates a new `Tealium` instance based on the provided `config`.
     *
     * Typical usage in an app would be to keep a reference of the returned instance to keep it alive for as long as the app is alive.
     * However, the returned `Tealium` should be shutdown by the user when no longer required by
     * removing all strong references to the returned instance.
     *
     * If you don't hold a strong reference to the returned instance, it will immediately shut down.
     *
     *
     *
     * - Parameters:
     *      - config: The required configuration options for this instance.
     *      - completion: The callback allows the caller to be notified once the instance is ready, or has
     * failed during initialization alongside the cause of the failure.
     *
     * - Returns: The `Tealium` instance ready to accept input, although if the initialization fails, any method calls made to this object will also fail.
     */
    public func create(config: TealiumConfig, completion: @escaping (Tealium.InitializationResult) -> Void) -> Tealium {
        let onImplementationReady = createImplementation(config: config)
        let teal = Tealium(onTealiumImplementation: onImplementationReady)
        _ = onImplementationReady
            .first()
            .subscribeOn(queue)
            .subscribe { [weak self] result in
                if case .success = result {
                    self?.proxies[config.key] = Weak(value: teal)
                }
                completion(result.map { _ in teal })
            }
        return teal
    }

    /**
     * Retrieves an existing `Tealium` instance, if one has already been created using its `TealiumConfig.key` and is still alive.
     *
     * - Parameters:
     *      - config: The config that was used to create the instance.
     *      - completion: The block to receive the `Tealium` instance on, if found.
     */
    public func get(_ config: TealiumConfig, completion: @escaping (Tealium?) -> Void) {
        get(config.key, completion: completion)
    }

    /**
     * Retrieves an existing `Tealium` instance, if one has already been created using its `TealiumConfig.key` and is still alive.
     *
     * - Parameters:
     *      - key: The key that identifies the `Tealium` instance.
     *      - completion: The block to receive the `Tealium` instance on, if found.
     */
    public func get(_ key: String, completion: @escaping (Tealium?) -> Void) {
        queue.ensureOnQueue { [weak self] in
            guard let teal = self?.proxies[key]?.value else {
                self?.proxies.removeValue(forKey: key)
                return completion(nil)
            }
            completion(teal)
        }
    }
}
