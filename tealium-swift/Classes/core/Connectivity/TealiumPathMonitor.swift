//
//  TealiumNWPathMonitor.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
#if canImport(Network)
import Network
#endif

#if !os(watchOS)
@available(iOS 12, *)
@available(tvOS 12, *)
@available(macCatalyst 13, *)
@available(OSX 10.14, *)
class TealiumNWPathMonitor: ConnectivityMonitorProtocol {

    let monitor = NWPathMonitor()
    
    @ToAnyObservable(TealiumReplaySubject<Connection>(initialValue: .unknown))
    var onConnection: TealiumObservable<Connection>
    
    var connection: Connection {
        $onConnection.last() ?? .unknown
    }

    init(queue: DispatchQueue = tealiumQueue) {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.$onConnection.publish(path.connection)
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }

}

@available(macOS 10.14, iOS 12.0, watchOS 5.0, tvOS 12.0, *)
extension NWPath {
    var connection: Connection {
        switch self.status {
        case .satisfied:
            return .connected(connectionType)
        case .unsatisfied:
            return .notConnected
        default: // .requiresConnection
            return .unknown // TODO: is unknown correct here? probably yes because we don't want to say that we have connection and if we had before now we might not have it anymore.
        }
    }
    
    var connectionType: Connection.ConnectionType {
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
