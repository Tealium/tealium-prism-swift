//
//  LifecycleObservable.swift
//  tealium-swift
//
//  Created by Denis Guzov on 02/08/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

public struct ApplicationStatus {
    public let type: LifecycleStatus
    public let timestamp: Int64 = Int64(Date().timeIntervalSince1970)

    public enum LifecycleStatus {
        case initialized, foregrounded, backgrounded
    }
}

public class ApplicationStatusListener: NSObject {
    static let shared = ApplicationStatusListener()

    @ToAnyObservable<ReplaySubject>(ReplaySubject<ApplicationStatus>(initialValue: ApplicationStatus(type: .initialized), cacheSize: Int.max))
    public var onApplicationStatus: Observable<ApplicationStatus>

    var wakeNotificationObserver: NSObjectProtocol?
    var sleepNotificationObserver: NSObjectProtocol?

    var initGraceTimer: TealiumRepeatingTimer?
    let queue: TealiumQueue
    init(graceTimeInterval: Double = 10.0, queue: TealiumQueue = .worker) {
        self.queue = queue
        super.init()
        addListeners()
        initGraceTimer = TealiumRepeatingTimer(timeInterval: graceTimeInterval, repeating: .never, queue: queue, eventHandler: { [weak self] in
            self?._onApplicationStatus.publisher.resize(0)
            self?.initGraceTimer = nil
        })
        initGraceTimer?.resume()
    }

    /// Sets up notification listeners to trigger events in listening delegates.
    func addListeners() {
        #if os(watchOS)
        #else
        #if os(macOS)
        #else
        // swiftlint:disable identifier_name
        let notificationNameApplicationDidBecomeActive = UIApplication.didBecomeActiveNotification
        let notificationNameApplicationWillResignActive = UIApplication.willResignActiveNotification
        // swiftlint:enable identifier_name

        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = queue.dispatchQueue

        /// Notifies listeners of a sleep event.
        sleepNotificationObserver = NotificationCenter.default.addObserver(forName: notificationNameApplicationWillResignActive, object: nil, queue: operationQueue) { [weak self] _ in
            self?._onApplicationStatus.publish(ApplicationStatus(type: .backgrounded))
        }

        /// Notifies listeners of a wake event.
        wakeNotificationObserver = NotificationCenter.default.addObserver(forName: notificationNameApplicationDidBecomeActive, object: nil, queue: operationQueue) { [weak self] _ in
            self?._onApplicationStatus.publish(ApplicationStatus(type: .foregrounded))
        }

        #endif
        #endif
    }

    deinit {
        NotificationCenter.default.removeObserver(sleepNotificationObserver as Any)
        NotificationCenter.default.removeObserver(wakeNotificationObserver as Any)
    }
}

@objc
public extension ApplicationStatusListener {
    static func setup() {
        _ = Self.shared
    }
}
