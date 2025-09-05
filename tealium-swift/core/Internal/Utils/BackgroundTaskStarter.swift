//
//  BackgroundTaskStarter.swift
//  tealium-swift
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
    class var sharedApplication: UIApplication? {
        let selector = NSSelectorFromString("sharedApplication")
        return UIApplication.perform(selector)?.takeUnretainedValue() as? UIApplication
    }
#endif

    init(queue: TealiumQueue, backgroundTaskTimeout: DispatchTimeInterval) {
        self.queue = queue
        self.backgroundTaskTimeout = backgroundTaskTimeout
    }

    /// Returns an observable that emits true immediately, starts a background task on iOS or WatchOS,
    /// and emits false when the background task ended, expired or the subscription is disposed.
    func startBackgroundTask() -> Observable<Bool> {
        CustomObservable { [queue, backgroundTaskTimeout] observer in
            let disposable = DisposeContainer()
            observer(true)
            disposable.add(Subscription {
                observer(false)
            })
#if os(iOS)
            if let application = Self.sharedApplication {
                // Only use from main thread
                var taskId: UIBackgroundTaskIdentifier = .invalid
                disposable.add(Subscription {
                    DispatchQueue.main.async {
                        application.endBackgroundTask(taskId)
                        taskId = .invalid
                    }
                })
                taskId = application.beginBackgroundTask {
                    // End task immediately on main thread to avoid potential crashes
                    application.endBackgroundTask(taskId)
                    taskId = .invalid
                    queue.ensureOnQueue {
                        disposable.dispose()
                    }
                }
            }
#elseif os(watchOS)
            let pInfo = ProcessInfo()
            pInfo.performExpiringActivity(withReason: "Tealium Swift: Dispatch Queued Events") { expired in
                if expired {
                    queue.ensureOnQueue {
                        disposable.dispose()
                    }
                }
            }
#endif
            queue.dispatchQueue.asyncAfter(deadline: .now() + backgroundTaskTimeout) {
                disposable.dispose()
            }
            return disposable
        }
    }
}
