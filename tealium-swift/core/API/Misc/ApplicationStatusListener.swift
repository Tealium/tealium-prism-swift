//
//  ApplicationStatusListener.swift
//  tealium-swift
//
//  Created by Denis Guzov on 02/08/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

public struct ApplicationStatus {
    public let type: StatusType
    public let timestamp: Int64

    public init(type: StatusType, timestamp: Int64 = Date().unixTimeMilliseconds) {
        self.type = type
        self.timestamp = timestamp
    }

    public enum StatusType {
        case initialized, foregrounded, backgrounded
    }
}

public class ApplicationStatusListener: NSObject {
    static let shared = ApplicationStatusListener()

    @ToAnyObservable<ReplaySubject>(ReplaySubject<ApplicationStatus>(initialValue: ApplicationStatus(type: .initialized), cacheSize: Int.max))
    public var onApplicationStatus: Observable<ApplicationStatus>

    private var wakeNotificationObserver: NSObjectProtocol?
    private var sleepNotificationObserver: NSObjectProtocol?

    private(set) var initGraceTimer: RepeatingTimer?
    let queue: TealiumQueue
    let notificationCenter: NotificationCenter
    init(graceTimeInterval: Double = 10.0, leeway: DispatchTimeInterval = .milliseconds(10), queue: TealiumQueue = .worker, notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.queue = queue
        self.notificationCenter = notificationCenter
        super.init()
        addListeners()
        initGraceTimer = RepeatingTimer(timeInterval: graceTimeInterval,
                                        repeating: .never,
                                        leeway: leeway,
                                        queue: queue,
                                        eventHandler: { [weak self] in
            self?._onApplicationStatus.publisher.resize(1)
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
        sleepNotificationObserver = notificationCenter.addObserver(forName: notificationNameApplicationWillResignActive, object: nil, queue: operationQueue) { [weak self] _ in
            self?._onApplicationStatus.publish(ApplicationStatus(type: .backgrounded))
        }

        /// Notifies listeners of a wake event.
        wakeNotificationObserver = notificationCenter.addObserver(forName: notificationNameApplicationDidBecomeActive, object: nil, queue: operationQueue) { [weak self] _ in
            self?._onApplicationStatus.publish(ApplicationStatus(type: .foregrounded))
        }

        #endif
        #endif
    }

    deinit {
        notificationCenter.removeObserver(sleepNotificationObserver as Any)
        notificationCenter.removeObserver(wakeNotificationObserver as Any)
    }
}

@objc
public extension ApplicationStatusListener {
    static func setup() {
        _ = Self.shared
    }
}
