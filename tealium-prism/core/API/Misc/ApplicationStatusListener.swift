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

@objc
public extension ApplicationStatusListener {
    static func setup() {
        _ = Self.shared
    }
}
