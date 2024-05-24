//
//  ReachabilityConnectivityMonitor.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

#if !os(watchOS)
import Foundation
import SystemConfiguration

/**
 * The `ReachabilityConnectivityMonitor` class listens for reachability changes for iOS < 11.
 *
 * Reachability can be used to determine background information about why a network operation failed, or to retry
 * network requests when a connection is established. It should not be used to prevent a user from initiating a network
 * request, as it's possible that an initial request may be required to establish reachability.
 */
class ReachabilityConnectivityMonitor: ConnectivityMonitorProtocol {

    @TealiumVariableSubject(.unknown)
    var connection: TealiumStatefulObservable<NetworkConnection>

    /// Flags of the current reachability type, if any.
    var flags: SCNetworkReachabilityFlags? {
        var flags = SCNetworkReachabilityFlags()
        return SCNetworkReachabilityGetFlags(reachability, &flags) ? flags : nil
    }

    /// `SCNetworkReachability` instance providing notifications.
    let reachability: SCNetworkReachability

    /**
     * Creates an instance that monitors the address 0.0.0.0.
     *
     * Reachability treats the 0.0.0.0 address as a special token that causes it to monitor the general routing
     * status of the device, both IPv4 and IPv6.
     */
    convenience init?(queue: DispatchQueue = tealiumQueue) {
        var zero = sockaddr()
        zero.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        zero.sa_family = sa_family_t(AF_INET)

        guard let reachability = SCNetworkReachabilityCreateWithAddress(nil, &zero) else { return nil }

        self.init(reachability: reachability, queue: queue)
    }

    private init?(reachability: SCNetworkReachability, queue: DispatchQueue) {
        self.reachability = reachability
        guard startListening(onQueue: queue) else {
            stopListening()
            return nil
        }
    }

    deinit {
        stopListening()
    }

    // MARK: - Listening

    /**
     * Starts listening for changes in network reachability status.
     *
     *  - Parameters:
     *     - queue: the `DispatchQueue` on which to notify the status changes
     *
     * - Returns: `true` if listening was started successfully, `false` otherwise.
     */
    @discardableResult
    func startListening(onQueue queue: DispatchQueue) -> Bool {

        let weakManager = WeakManager(manager: self)

        var context = SCNetworkReachabilityContext(
            version: 0,
            info: Unmanaged.passUnretained(weakManager).toOpaque(),
            retain: { info in
                let unmanaged = Unmanaged<WeakManager>.fromOpaque(info)
                _ = unmanaged.retain()

                return UnsafeRawPointer(unmanaged.toOpaque())
            },
            release: { info in
                let unmanaged = Unmanaged<WeakManager>.fromOpaque(info)
                unmanaged.release()
            },
            copyDescription: { info in
                let unmanaged = Unmanaged<WeakManager>.fromOpaque(info)
                let weakManager = unmanaged.takeUnretainedValue()
                let description = weakManager.manager?.flags?.readableDescription ?? "nil"

                return Unmanaged.passRetained(description as CFString)
            })
        let callback: SCNetworkReachabilityCallBack = { _, flags, info in
            guard let info = info else { return }

            let weakManager = Unmanaged<WeakManager>.fromOpaque(info).takeUnretainedValue()
            weakManager.manager?.notify(flags)
        }

        let queueAdded = SCNetworkReachabilitySetDispatchQueue(reachability, queue)
        let callbackAdded = SCNetworkReachabilitySetCallback(reachability, callback, &context)

        // Manually call listener to give initial state, since the framework may not.
        if let currentFlags = flags {
            queue.async {
                self.notify(currentFlags)
            }
        }

        return callbackAdded && queueAdded
    }

    /// Stops listening for changes in network reachability status.
    func stopListening() {
        SCNetworkReachabilitySetCallback(reachability, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachability, nil)
    }

    /**
     * Converts the flags to a `NetworkConnection` and sends them in the onConnection `TealiumSubject`.
     *
     * - Note: Should only be called from the internal queue.
     *
     * - Parameter flags: `SCNetworkReachabilityFlags` to use to calculate the status.
     */
    private func notify(_ flags: SCNetworkReachabilityFlags) {
        _connection.publishIfChanged(NetworkConnection.fromFlags(flags))
    }

    private final class WeakManager {
        weak var manager: ReachabilityConnectivityMonitor?

        init(manager: ReachabilityConnectivityMonitor?) {
            self.manager = manager
        }
    }
}

extension NetworkConnection {
    static func fromFlags(_ flags: SCNetworkReachabilityFlags) -> Self {
        guard flags.isActuallyReachable else { return .notConnected }

        var connection: NetworkConnection = .connected(.wifi)

        if flags.isCellular { connection = .connected(.cellular) }

        return connection
    }
}

extension SCNetworkReachabilityFlags {
    var isReachable: Bool { contains(.reachable) }
    var isConnectionRequired: Bool { contains(.connectionRequired) }
    var canConnectAutomatically: Bool { contains(.connectionOnDemand) || contains(.connectionOnTraffic) }
    var canConnectWithoutUserInteraction: Bool { canConnectAutomatically && !contains(.interventionRequired) }
    var isActuallyReachable: Bool { isReachable && (!isConnectionRequired || canConnectWithoutUserInteraction) }
    var isCellular: Bool {
        #if os(iOS) || os(tvOS)
        return contains(.isWWAN)
        #else
        return false
        #endif
    }

    // swiftlint:disable identifier_name
    /// Human readable `String` for all states, to help with debugging.
    var readableDescription: String {
        let W = isCellular ? "W" : "-"
        let R = isReachable ? "R" : "-"
        let c = isConnectionRequired ? "c" : "-"
        let t = contains(.transientConnection) ? "t" : "-"
        let i = contains(.interventionRequired) ? "i" : "-"
        let C = contains(.connectionOnTraffic) ? "C" : "-"
        let D = contains(.connectionOnDemand) ? "D" : "-"
        let l = contains(.isLocalAddress) ? "l" : "-"
        let d = contains(.isDirect) ? "d" : "-"
        let a = contains(.connectionAutomatic) ? "a" : "-"

        return "\(W)\(R) \(c)\(t)\(i)\(C)\(D)\(l)\(d)\(a)"
    }
    // swiftlint:enable identifier_name
}
#endif
