//
//  RepeatingTimer.swift
//  tealium-swift
//
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

// Credit/source: https://medium.com/@danielgalasko/a-background-repeating-timer-in-swift-412cecfd2ef9 🙏

import Foundation

public protocol Repeater {
    var eventHandler: (() -> Void)? { get }
    func resume()
    func suspend()
}

/// Safe implementation of a repeating timer for scheduling connectivity checks
public class RepeatingTimer: Repeater {

    let timeInterval: TimeInterval
    let repeating: DispatchTimeInterval
    let queue: TealiumQueue

    /// - Parameters:
    ///     - timeInterval: TimeInterval in seconds until the timed event happens, and repeating interval by default (if 'repeating' is not specified)
    ///     - repeating: The interval to repeat, otherwise the same timeInterval is reused
    ///     - queue: The queue to use for the timer
    public init(timeInterval: TimeInterval, repeating: DispatchTimeInterval? = nil, queue: TealiumQueue, eventHandler: @escaping () -> Void) {
        self.timeInterval = max(0, timeInterval)
        self.repeating = repeating ?? DispatchTimeInterval.milliseconds(Int(timeInterval * 1000))
        self.queue = queue
        self.eventHandler = eventHandler
    }

    private lazy var timer: DispatchSourceTimer = {
        let timer = DispatchSource.makeTimerSource(flags: [], queue: queue.dispatchQueue)

        timer.schedule(deadline: .now() + self.timeInterval, repeating: self.repeating)
        timer.setEventHandler(handler: { [weak self] in
            self?.eventHandler?()
        })
        return timer
    }()

    public private(set)  var eventHandler: (() -> Void)?

    private enum State {
        case suspended
        case resumed
    }

    private var state: State = .suspended

    deinit {
        self.timer.setEventHandler {}
        /*
         If the timer is suspended, calling cancel without resuming
         triggers a crash. This is documented here https://forums.developer.apple.com/thread/15902
         */
        if self.state == .suspended {
            self.timer.resume()
        }
        self.timer.cancel()
    }

    /// Resumes this timer instance if suspended
    public func resume() {
        queue.ensureOnQueue { [weak self] in
            guard let self = self else {
                return
            }
            if self.state == .resumed {
                return
            }
            self.state = .resumed
            self.timer.resume()
        }
    }

    /// Suspends this timer instance if running
    public func suspend() {
        queue.ensureOnQueue { [weak self] in
            guard let self = self else {
                return
            }
            if self.state == .suspended {
                return
            }
            self.state = .suspended
            self.timer.suspend()
        }
    }
}
