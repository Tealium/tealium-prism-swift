//
//  ConnectivityManager.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 24/05/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// Protocol for managing network connectivity state and monitoring.
public protocol ConnectivityManagerProtocol {
    /// Observable state indicating whether connection is assumed to be available.
    var connectionAssumedAvailable: ObservableState<Bool> { get }
    /// Observable state of the current network connection.
    var connection: ObservableState<NetworkConnection> { get }
}

/**
 * A manager that handles system connectivity monitor and empirical connectivity monitor to establish when connectivity is actually available or not on the device.
 *
 * See `connectionAssumedAvailable` for how the two are combined.
 */
public class ConnectivityManager: ConnectivityManagerProtocol, RequestInterceptor {
    static let defaultQueue = TealiumQueue.worker
    let connectivityMonitor: ConnectivityMonitorProtocol
    let empiricalConnectivity: EmpiricalConnectivityProtocol
    private let automaticDisposer = AutomaticDisposer()

    /// The shared instance of the `ConnectivityManager`
    public static let shared = ConnectivityManager()
    let queue: TealiumQueue

    init(queue: TealiumQueue = ConnectivityManager.defaultQueue,
         connectivityMonitor: ConnectivityMonitorProtocol? = nil,
         empiricalConnectivity: EmpiricalConnectivityProtocol? = nil) {
        self.queue = queue
        let connectivityMonitor = connectivityMonitor ?? ConnectivityMonitor.shared
        self.connectivityMonitor = connectivityMonitor
        let empiricalConnectivity = empiricalConnectivity ?? EmpiricalConnectivity(debouncer: Debouncer(queue: queue))
        self.empiricalConnectivity = empiricalConnectivity
        connectivityMonitor.connection.asObservable()
            .flatMapLatest { monitoredConnection in
                switch monitoredConnection {
                case .connected:
                    Observables.just(true)
                case .notConnected:
                    Observables.just(false)
                case .unknown:
                    empiricalConnectivity.onEmpiricalConnectionAvailable
                }
            }.distinct()
            .subscribeOn(queue)
            .subscribe(_connectionAssumedAvailable)
            .addTo(automaticDisposer)
    }

    /**
     * Shortcut for `connectionAssumedAvailable.value`.
     * It is `false` whenever the system monitor reports no connection, whatever the empirical connectivity says.
     */
    public var isConnectionAssumedAvailable: Bool {
        connectionAssumedAvailable.value
    }

    /// The current network connection state from the connectivity monitor.
    public var connection: ObservableState<NetworkConnection> {
        connectivityMonitor.connection
    }

    /**
     * An observable that emits `true` when connection is assumed to be available and `false` when it's assumed to be unavailable.
     *
     * The internal behavior is to merge the information from the system connectivity monitor and the result of network requests:
     * connected reports as available, not connected reports as unavailable, and unknown follows the empirical connectivity result.
     */
    @StateSubject(true)
    public var connectionAssumedAvailable

    /**
     * Feeds `EmpiricalConnectivity` from the result of every request attempt.
     *
     * Here we always assume that the response is never coming from a local cache.
     */
    public func onAttemptResult(_ request: URLRequest, retryCount: Int, with result: NetworkResult) {
        switch result {
        case let .failure(error) where error.isClientConnectionError:
            self.empiricalConnectivity.connectionFail()
        case .failure(let error) where error.urlResponse != nil:
            fallthrough // swiftlint:disable:this no_fallthrough_only
        case .success:
            self.empiricalConnectivity.connectionSuccess()
        default:
            break // Unknown
        }
    }

    /// Never retries: the `ConnectivityManager` only observes the completed requests.
    public func shouldRetry(_ request: URLRequest, consecutiveRetryCount: Int, with response: NetworkResult) -> RetryPolicy {
        .doNotRetry
    }

    func emittingOn(queue: TealiumQueue) -> ConnectivityManagerProtocol {
        ConnectivityManagerWrapper(connectivityManager: self, queue: queue)
    }
}
