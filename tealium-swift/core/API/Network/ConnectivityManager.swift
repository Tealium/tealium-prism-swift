//
//  ConnectivityManager.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/05/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol ConnectivityManagerProtocol: RequestInterceptor {
    var connectionAssumedAvailable: ObservableState<Bool> { get }
}

/**
 * A manager that handles system connectivity monitor and empirical connectivity monitor to establish when connectivity is actually available or not on the device.
 *
 * The default behavior would be to always assume that connectivity is available until system monitor or empirical connectivity result unavaialble or unknown.
 */
public class ConnectivityManager: ConnectivityManagerProtocol {
    let connectivityMonitor: ConnectivityMonitorProtocol
    let empiricalConnectivity: EmpiricalConnectivityProtocol
    private let automaticDisposer = AutomaticDisposer()

    /// The shared instance of the `ConnectivityManager`
    public static let shared = ConnectivityManager()

    init(connectivityMonitor: ConnectivityMonitorProtocol = ConnectivityMonitor.shared, empiricalConnectivity: EmpiricalConnectivityProtocol = EmpiricalConnectivity()) {
        self.connectivityMonitor = connectivityMonitor
        self.empiricalConnectivity = empiricalConnectivity
        connectivityMonitor.connection.asObservable()
            .combineLatest(empiricalConnectivity.onEmpiricalConnectionAvailable)
            .map { monitoredConnection, empiricalConnectionAvailable in
                switch monitoredConnection {
                case .notConnected, .unknown:
                    return empiricalConnectionAvailable
                case .connected:
                    return true
                }
            }.subscribe { [weak self] available in
                self?._connectionAssumedAvailable.publishIfChanged(available)
            }.addTo(automaticDisposer)
    }

    public func waitingForConnectivity(_ task: URLSessionTask) {
        self.empiricalConnectivity.connectionFail()
    }

    /// Returns `true` if either monitored or empirical connectivity result available
    public var isConnectionAssumedAvailable: Bool {
        connectionAssumedAvailable.value
    }

    /**
     * An observable that emits `true` when connection is assumed to be available and `false` when it's assumed to be unavailable.
     *
     * The internal behavior is to merge the information from the system connectivity monitor and the result of network requests
     * and only report as unavailable when both do so or if empirical is unavailable and the monitored one is unknown.
     */
    @StateSubject(true)
    public var connectionAssumedAvailable: ObservableState<Bool>

    public func didComplete(_ request: URLRequest, with response: NetworkResult) {
        // Here we always assume that the response is never coming from a local cache
        switch response {
        case let .failure(.urlError(urlError)) where urlError.isClientConnectionError:
            self.empiricalConnectivity.connectionFail()
        case .failure(.non200Status), .success:
            self.empiricalConnectivity.connectionSuccess()
        default:
            break // Unknown
        }
    }

    public func shouldRetry(_ request: URLRequest, retryCount: Int, with response: NetworkResult) -> RetryPolicy {
        switch response {
        case .failure(let error) where error.isRetryable && !isConnectionAssumedAvailable:
            return .afterEvent(
                connectionAssumedAvailable
                    .filter { $0 }
                    .map { _ in }
            )
        default:
            return .doNotRetry
        }
    }
}
