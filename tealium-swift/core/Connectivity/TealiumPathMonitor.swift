//
//  TealiumNWPathMonitor.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

#if !os(watchOS)
import Foundation
import Network

/**
 * Monitors the NWPath changes to report when connection is available or not on iOS 12+.
 *
 * NWPath can be used to determine background information about why a network operation failed, or to retry
 * network requests when a connection is established. It should not be used to prevent a user from initiating a network
 * request, as it's possible that an initial request may be required to establish reachability.
 */
@available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *)
class TealiumNWPathMonitor: ConnectivityMonitorProtocol {

    let monitor = NWPathMonitor()

    @TealiumMutableState(.unknown)
    var connection: TealiumObservableState<NetworkConnection>

    init(queue: DispatchQueue = tealiumQueue) {
        monitor.pathUpdateHandler = { [weak self] path in
            self?._connection.mutateIfChanged(path.connection)
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

@available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *)
extension NWPath {
    var connection: NetworkConnection {
        switch self.status {
        case .satisfied:
            return .connected(connectionType)
        case .unsatisfied:
            return .notConnected
        default: // .requiresConnection
            return .unknown
        }
    }

    var connectionType: NetworkConnection.ConnectionType {
        if isExpensive {
            return .cellular
        } else if usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .wifi
        }
    }
}
#endif
