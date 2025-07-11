//
//  AsyncProxy.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 11/07/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/**
 * A proxy that allows access to the proxied object from a specific queue.
 *
 * The provided `queue` is the `TealiumQueue` from which the `onObject` will be subscribed on
 * and it's the queue from which the `onObject` is expected to emit the `Object` from.
 * The provided `onObject` observable is an `Observable` that, upon subscription, emits the proxied object,
 * if available, from the provided `queue`, or `nil` if it's not available.
 */
class AsyncProxy<Object: AnyObject> {
    typealias ObjectResult = Result<Object, any Error>
    typealias Task<T> = (_ object: Object) throws -> T
    typealias AsyncTask<T> = (
        _ object: Object,
        _ completion: @escaping (Result<T, Error>) -> Void
    ) throws -> Void

    let queue: TealiumQueue
    private let onObject: Observable<ObjectResult>

    init(queue: TealiumQueue, onObject: Observable<ObjectResult>) {
        self.queue = queue
        self.onObject = onObject
    }

    func getProxiedObject(completion: @escaping (Object?) -> Void) {
        let single = onObject.map { try? $0.get() }
            .asSingle(queue: queue)
        single.subscribe(completion) // Split to reduce compilation complexity
    }

    func executeTask<Output>(_ task: @escaping Task<Output>) -> SingleResult<Output> {
        executeAsyncTask { object, completion in
            do {
                let result = try task(object)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }

    func executeAsyncTask<Output>(_ asyncTask: @escaping AsyncTask<Output>) -> SingleResult<Output> {
        // Use the replay subject to make the returned Single a HOT observable.
        // A HOT observable doesn't require a subscription to start emitting events.
        let replay = ReplaySubject<Result<Output, Error>>()
        let observable = onObject.callback(from: { result, observer in
            do {
                let object = try result.get()
                try asyncTask(object) { result in
                    observer(result)
                }
            } catch {
                observer(.failure(error))
            }
        })
        _ = SingleImpl(observable: observable, queue: queue)
            .subscribe(replay)
        return replay.asObservable().asSingle(queue: queue)
    }
}
