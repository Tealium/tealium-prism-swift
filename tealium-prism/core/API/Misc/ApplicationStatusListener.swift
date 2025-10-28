//
//  ApplicationStatusListener.swift
//  tealium-prism
//
//  Created by Denis Guzov on 02/08/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

#if os(iOS) || os(tvOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#elseif os(macOS)
import AppKit
#endif

import Foundation

/// Represents the current status of the application lifecycle.
public struct ApplicationStatus {
    /// The type of status change that occurred.
    public let type: StatusType
    /// The timestamp when this status change occurred, in milliseconds since Unix epoch.
    public let timestamp: Int64

    /// Creates a new application status.
    /// - Parameters:
    ///   - type: The type of status change.
    ///   - timestamp: The timestamp of the change, defaults to current time.
    public init(type: StatusType, timestamp: Int64 = Date().unixTimeMilliseconds) {
        self.type = type
        self.timestamp = timestamp
    }

    /// The different types of application status changes.
    public enum StatusType {
        /// The application has been initialized.
        case initialized
        /// The application has come to the foreground.
        case foregrounded
        /// The application has gone to the background.
        case backgrounded
    }
}

/// Listens for application lifecycle events and publishes status changes.
public class ApplicationStatusListener: NSObject {
    static let shared = ApplicationStatusListener()

    /// Observable that emits application status changes. By default, all published changes will be re-emitted to every new subscriber for 10 seconds after start.
    /// After that grace period only the last change is re-emitted to every new subscriber.
    @ReplaySubject(ApplicationStatus(type: .initialized), cacheSize: Int.max)
    public var onApplicationStatus

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
            self?._onApplicationStatus.resize(1)
            self?.initGraceTimer = nil
        })
        initGraceTimer?.resume()
    }

    /// Sets up notification listeners to trigger events in listening delegates.
    func addListeners() {
        #if os(watchOS)
        let notificationApplicationDidBecomeActive = WKExtension.applicationDidBecomeActiveNotification
        let notificationApplicationWillResignActive = WKExtension.applicationWillResignActiveNotification
        #elseif os(macOS)
        let notificationApplicationDidBecomeActive = NSApplication.didBecomeActiveNotification
        let notificationApplicationWillResignActive = NSApplication.willResignActiveNotification
        #else
        let notificationApplicationDidBecomeActive = UIApplication.didBecomeActiveNotification
        let notificationApplicationWillResignActive = UIApplication.willResignActiveNotification
        #endif
        let operationQueue = OperationQueue()
        operationQueue.underlyingQueue = queue.dispatchQueue

        /// Notifies listeners of a sleep event.
        sleepNotificationObserver = notificationCenter.addObserver(forName: notificationApplicationWillResignActive,
                                                                   object: nil,
                                                                   queue: operationQueue) { [weak self] _ in
            self?._onApplicationStatus.publish(ApplicationStatus(type: .backgrounded))
        }

        /// Notifies listeners of a wake event.
        wakeNotificationObserver = notificationCenter.addObserver(forName: notificationApplicationDidBecomeActive,
                                                                  object: nil,
                                                                  queue: operationQueue) { [weak self] _ in
            self?._onApplicationStatus.publish(ApplicationStatus(type: .foregrounded))
        }
    }

    deinit {
        notificationCenter.removeObserver(sleepNotificationObserver as Any)
        notificationCenter.removeObserver(wakeNotificationObserver as Any)
    }
}

/// Objective-C compatible extension for ApplicationStatusListener.
@objc
public extension ApplicationStatusListener {
    /// Sets up the shared application status listener.
    static func setup() {
        _ = Self.shared
    }
}
