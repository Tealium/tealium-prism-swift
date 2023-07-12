//
//  ConnectivityManager.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/05/23.
//

import Foundation

public protocol ConnectivityManagerProtocol: RequestInterceptor {
    var isConnectionAssumedAvailable: Bool { get }
    var onConnectionAssumedAvailable: TealiumObservable<Bool> { get }
}

public class ConnectivityManager: ConnectivityManagerProtocol {
    let connectivityMonitor: ConnectivityMonitorProtocol
    let empiricalConnectivity: EmpiricalConnectivityProtocol
    public static let shared = ConnectivityManager()
    private let bag = TealiumDisposeBag()
    init(connectivityMonitor: ConnectivityMonitorProtocol = ConnectivityMonitor.shared, empiricalConnectivity: EmpiricalConnectivityProtocol = EmpiricalConnectivity()) {
        self.connectivityMonitor = connectivityMonitor
        self.empiricalConnectivity = empiricalConnectivity
        connectivityMonitor.onConnection
            .combineLatest(empiricalConnectivity.onEmpiricalConnectionAvailable)
            .map { monitoredConnection, empiricalConnectionAvailable in
                switch monitoredConnection {
                case .notConnected, .unknown:
                    return empiricalConnectionAvailable
                case .connected:
                    return true
                }
            }.subscribe { [weak self] available in
                self?.$onConnectionAssumedAvailable.publishIfChanged(available)
        }.toDisposeBag(bag)
    }

    public func waitingForConnectivity(_ task: URLSessionTask) {
        self.empiricalConnectivity.connectionFail()
    }
    
    public var isConnectionAssumedAvailable: Bool {
        $onConnectionAssumedAvailable.last() ?? true
    }
    
    // Returns an observable that will fire with true when connection is available and false when it isn't.
    // The internal behavior is to detect URLSession waiting events and HTTP client connection errors + ConnectivityMonitor being notConnected or unknown to assume it's not available
    // Default behavior is to assume it's available when no error/waiting events occurred or when monitor measures as connected or an HTTP server response is received.
    @ToAnyObservable(TealiumReplaySubject<Bool>(initialValue: true))
    public var onConnectionAssumedAvailable: TealiumObservable<Bool>
    
    public func didComplete(_ request: URLRequest, with response: NetworkResult) {
        // Here we always assume that the response is never coming from a local cache
        switch response {
        case let .failure(.urlError(urlError)) where urlError.isConnectionError:
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
                onConnectionAssumedAvailable
                    .filter { $0 }
                    .map { _ in }
            )
        default:
            return .doNotRetry
        }
    }
}
