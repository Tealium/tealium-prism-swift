//
//  TealiumSignposter.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 20/03/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import os.signpost

extension TealiumSignposter {
    static let startup = TealiumSignposter(category: LogCategory.startup)
    static let tracking = TealiumSignposter(category: LogCategory.tracking)
    static let dispatching = TealiumSignposter(category: LogCategory.dispatchManager)
    static let settings = TealiumSignposter(category: LogCategory.settingsManager)
    static let networking = TealiumSignposter(category: LogCategory.networkHelper)
    static let httpClient = TealiumSignposter(category: LogCategory.httpClient)
}
/**
 * A wrapper class to make the `OSSignpostIntervalState` easier to use on `iOS < 15`.
 */
public class SignpostStateWrapper {

    private let intervalState: Any
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    init(_ intervalState: OSSignpostIntervalState) {
        self.intervalState = intervalState
    }

    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    func state() -> OSSignpostIntervalState? {
        intervalState as? OSSignpostIntervalState
    }
}

@available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
public extension OSSignpostIntervalState {
    /**
     * Utility method to inline add an `OSSignpostIntervalState` to it's own `SignpostStateWrapper` and return that wrapper
     *
     * - Returns: the `SignpostStateWrapper` that wraps the `OSSignpostIntervalState` instance.
     */
    func toWrapper() -> SignpostStateWrapper {
        SignpostStateWrapper(self)
    }
}

/**
 * A wrapper around the OSSignposter API to make it easier to use when supporting `iOS < 15`. Enable it by changing the enabled static flag on this class.
 *
 * On `iOS < 15` this class does nothing.
 *
 * For normal usecases of intervals being signposted you can use the `TealiumSignpostInterval` instead of this class, so you can avoid handling the SignpostStateWrapper yourself.
 * If instead you want to handle it yourself, or you have to send singular events, you can use this class like so:
 *
 * ```
 * let signposter = TealiumSignposter("Networking")
 * let state = signposter.beginInterval("Start Request", "\(request)")
 * urlSession.dataTask(request) { _, response, _ in
 *      signposter.endInterval("Start Request", state: state, "\(response)")
 *      // Handle the HTTP response
 * }
 * ```
 * Note that the `beginInterval` name needs to match with the `endInterval` name.
 */
public class TealiumSignposter {
    /// Set this to true at the start of the app to make sure Signposting is enabled
    public static var enabled = false

    private var _signposter: Any?
    @available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *)
    var signposter: OSSignposter {
        _signposter as? OSSignposter ?? .disabled
    }

    private static func signposter(category: String) -> Any? {
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) {
            if TealiumSignposter.enabled {
                return OSSignposter(subsystem: "com.tealium.swift", category: category)
            } else {
                return OSSignposter.disabled
            }
        } else {
            return nil
        }
    }

    /// Creates and returns a `TealiumSignposter` with the given category
    public init(category: String) {
        _signposter = Self.signposter(category: category)
    }

    /**
     * Begins a new interval with the given name on iOS 15+.
     *
     * No-op on iOS < 15.
     *
     * - Parameter name: the `StaticString` used to name this interval
     *
     * - Returns: an optional `SignpostStateWrapper` used to pass it to the `endInterval` method. Nil on iOS < 15
     */
    public func beginInterval(_ name: StaticString) -> SignpostStateWrapper? {
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) {
            return signposter
                .beginInterval(name,
                               id: signposter.makeSignpostID())
                .toWrapper()
        }
        return nil
    }

    /**
     * Begins a new interval with the given name on iOS 15+.
     *
     * No-op on iOS < 15.
     *
     * - Parameters:
     *    - name: the `StaticString` used to name this interval
     *    - message: the autoclosure `String` used to describe some parameters for this begin interval
     *
     * - Returns: an optional `SignpostStateWrapper` used to pass it to the `endInterval` method. Nil on iOS < 15
     */
    public func beginInterval(_ name: StaticString, _ message: @autoclosure @escaping () -> String) -> SignpostStateWrapper? {
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) {
            return signposter
                .beginInterval(name,
                               id: signposter.makeSignpostID(),
                               "\(message(), privacy: .public)")
                .toWrapper()
        }
        return nil
    }

    /**
     * Ends an interval previusly created with the given name on iOS 15+.
     *
     * No-op on iOS < 15.
     *
     * - Parameters:
     *    - name: the `StaticString` used to name the interval. Must be an exact match with the begin interval call
     *    - state: the `SignpostStateWrapper` returned by the begin interval call
     *
     * - Returns: an optional `SignpostStateWrapper` used to pass it to the `endInterval` method. Nil on iOS < 15
     */
    public func endInterval(_ name: StaticString, state: SignpostStateWrapper?) {
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *), let state = state?.state() {
            signposter.endInterval(name,
                                   state)
        }
    }

    /**
     * Ends an interval previusly created with the given name on iOS 15+.
     *
     * No-op on iOS < 15.
     *
     * - Parameters:
     *    - name: the `StaticString` used to name the interval. Must be an exact match with the begin interval call
     *    - state: the `SignpostStateWrapper` returned by the begin interval call
     *    - message: the autoclosure `String` used to describe some parameters for this end interval call
     *
     * - Returns: an optional `SignpostStateWrapper` used to pass it to the `endInterval` method. Nil on iOS < 15
     */
    public func endInterval(_ name: StaticString, state: SignpostStateWrapper?, _ message: @autoclosure @escaping () -> String) {
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *), let state = state?.state() {
            signposter.endInterval(name,
                                   state,
                                   "\(message(), privacy: .public)")
        }
    }

    /**
     * Emits a single event on this signpost with the given name
     *
     * - Parameter name: the `StaticString` used to name the event
     */
    public func event(_ name: StaticString) {
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) {
            signposter.emitEvent(name,
                                 id: signposter.makeSignpostID())
        }
    }

    /**
     * Emits a single event on this signpost with the given name
     *
     * - Parameters:
     *    - name: the `StaticString` used to name the event
     *    - message: the autoclosure `String` used to describe some parameters for this event call
     */
    public func event(_ name: StaticString, message: @autoclosure @escaping () -> String) {
        if #available(macOS 12.0, iOS 15.0, watchOS 8.0, tvOS 15.0, *) {
            signposter.emitEvent(name,
                                 id: signposter.makeSignpostID(),
                                 "\(message(), privacy: .public)")
        }
    }
}

/**
 * A convenience class to use the `TealiumSignposter` in an interval fashion that handles the `SignpostStateWrapper` internally.
 *
 * This class will work correctly as long as you get exactly one `end` call after every `begin`.
 * The suggested way to use this would be to create and begin a new interval everytime it's needed and then end it once the interval is completed.
 *
 * Usage:
 * ```
 * let signpostInterval = TealiumSignpostInterval(signposter: .networking, name: "HTTP Call Sent").begin("URL: \(request.url!)"
 * session.dataTask(request) { _, response, _ in
 *    signpostInterval.end("Response \(response)")
 *    // handle request completion
 * }
 * ```
 */
public class TealiumSignpostInterval {
    let signposter: TealiumSignposter
    let name: StaticString
    private var state: SignpostStateWrapper?

    /// Creates and return a new `TealiumSignposterInterval` with the given category and name
    public convenience init(category: String, name: StaticString) {
        self.init(signposter: TealiumSignposter(category: category),
                  name: name)
    }

    /// Creates and return a new `TealiumSignpostInterval` with the given `TealiumSignposter` and name
    public init(signposter: TealiumSignposter, name: StaticString) {
        self.signposter = signposter
        self.name = name
    }

    /**
     * Begins the interval
     *
     * No-op on iOS < 15.
     *
     * - Returns: self for ease of use
     */
    public func begin() -> Self {
        state = signposter.beginInterval(name)
        return self
    }

    /**
     * Begins the interval.
     *
     * No-op on iOS < 15.
     *
     * - Parameter message: the autoclosure `String` used to describe some parameters for this begin interval
     *
     * - Returns: self for ease of use
     */
    public func begin(_ message: @autoclosure @escaping () -> String) -> Self {
        state = signposter.beginInterval(name, message())
        return self
    }

    /**
     * Ends the previusly created interval.
     *
     * No-op on iOS < 15.
     */
    public func end() {
        signposter.endInterval(name, state: state)
        self.state = nil
    }

    /**
     * Ends an interval previusly created with the given name on iOS 15+.
     *
     * No-op on iOS < 15.
     *
     * - Parameter message: the autoclosure `String` used to describe some parameters for this end interval call
     */
    public func end(_ message: @autoclosure @escaping () -> String) {
        signposter.endInterval(name, state: state, message())
        self.state = nil
    }

    /**
     * Begins and ends a signpost interval around a synchronous block of code.
     *
     * Just runs the work on iOS < 15.
     *
     * - Parameter work: the block to be run while surrounded by the signpost interval
     *
     * - Returns: the same `Output` of the block passed as parameter
     */
    public func signpostedWork<Output>(_ work: () throws -> Output) rethrows -> Output {
        _ = begin()
        defer { end() }
        return try work()
    }

    /**
     * Begins and ends a signpost interval around a synchronous block of code.
     *
     * Just runs the work on iOS < 15.
     *
     * - Parameters:
     *    - work: the block to be run while surrounded by the signpost interval
     *    - message: the autoclosure `String` used to describe some parameters for the begin interval call
     *
     * - Returns: the same `Output` of the block passed as parameter
     */
    public func signpostedWork<Output>(_ message: @autoclosure @escaping () -> String, _ work: @escaping () throws -> Output) rethrows -> Output {
        _ = begin(message())
        defer { end() }
        return try work()
    }
}
