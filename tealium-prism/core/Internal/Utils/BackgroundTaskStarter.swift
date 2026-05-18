//
//  BackgroundTaskStarter.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 25/08/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation
#if os(iOS)
import UIKit
#endif

class BackgroundTaskStarter {

    private let queue: TealiumQueue

    /// The amount of time a background task can last to allow items to be flushed
    private let backgroundTaskTimeout: DispatchTimeInterval

#if os(iOS)
    static var sharedApplication: UIApplication? {
        let selector = NSSelectorFromString("sharedApplication")
        return UIApplication.perform(selector)?.takeUnretainedValue() as? UIApplication
    }
#endif

    init(queue: TealiumQueue, backgroundTaskTimeout: DispatchTimeInterval) {
        self.queue = queue
        self.backgroundTaskTimeout = backgroundTaskTimeout
    }

    /// Returns an observable that emits true upon subscription, starts a background task on iOS or WatchOS,
    /// and emits false when the background task ended or expired.
    func startBackgroundTask(withName name: String? = nil) -> Observable<Bool> {
        Observables.create { [queue, backgroundTaskTimeout] observer in
            observer.onNext(true)
            let disposable = AsyncDisposableContainer(queue: queue)
            let completion = SelfDestructingCompletion {
                if !disposable.isDisposed {
                    observer.onNext(false)
                    observer.onComplete()
                }
                disposable.dispose()
            }
#if os(iOS)
            if let application = Self.sharedApplication {
                // Only use from main thread
                var taskId: UIBackgroundTaskIdentifier = .invalid
                func endTaskIfNeeded() {
                    guard taskId != .invalid else {
                        return
                    }
                    application.endBackgroundTask(taskId)
                    taskId = .invalid
                }

                disposable.onDispose {
                    DispatchQueue.main.async {
                        endTaskIfNeeded()
                    }
                }
                taskId = application.beginBackgroundTask(withName: name) {
                    // End task immediately on main thread to avoid potential crashes
                    endTaskIfNeeded()
                    queue.ensureOnQueue {
                        completion.complete(result: ())
                    }
                }
            }
#elseif os(watchOS)
            ProcessInfo.processInfo
                .performExpiringActivity(withReason: name ?? "Tealium Background Task") { expired in
                    if expired {
                        queue.ensureOnQueue {
                            completion.complete(result: ())
                        }
                    }
                }
#endif
            queue.dispatchQueue.asyncAfter(deadline: .now() + backgroundTaskTimeout) {
                completion.complete(result: ())
            }
            return disposable
        }
    }
}
