//
//  ConnectivityBarrier.swift
//  tealium-swift
//
//  Created by Denis Guzov on 29/05/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

struct ConnectivityBarrierSettings {
    enum Keys {
        static let wifiOnly = "wifi_only"
    }
    enum Defaults {
        static let wifiOnly: Bool = false
    }
    let wifiOnly: Bool

    init(dataObject: DataObject) {
        wifiOnly = dataObject.get(key: Keys.wifiOnly) ?? Defaults.wifiOnly
    }
}

class ConnectivityBarrier: ConfigurableBarrier {
    static var id: String = "ConnectivityBarrier"
    private let settings: StateSubject<ConnectivityBarrierSettings>
    private let connectionManager: ConnectivityManagerProtocol

    init(connectionManager: ConnectivityManagerProtocol, configuration: DataObject) {
        settings = StateSubject(ConnectivityBarrierSettings(dataObject: configuration))
        self.connectionManager = connectionManager
    }

    var isFlushable: Observable<Bool> {
        connectionManager.connection.mapState { $0.isConnected }
    }

    /** `dispatcherId` is ignored for ConnectivityBarrier */
    func onState(for dispatcherId: String) -> Observable<BarrierState> {
        let onConnectionAllowed = connectionManager.connection
            .combineLatest(settings.asObservable())
            .map { connection, settings in
                guard settings.wifiOnly,
                      case let .connected(connectionType) = connection else {
                    return true
                }
                return connectionType != .cellular // Allow both wifi and ethernet
            }

        return connectionManager.connectionAssumedAvailable
            .combineLatest(onConnectionAllowed)
            .map { isConnected, connectionIsAllowed in
                guard isConnected && connectionIsAllowed else {
                    return BarrierState.closed
                }
                return BarrierState.open
            }
    }

    func updateConfiguration(_ configuration: DataObject) {
        settings.value = ConnectivityBarrierSettings(dataObject: configuration)
    }

}

extension ConnectivityBarrier {
    class Factory: BarrierFactory {
        let _defaultScopes: [BarrierScope]
        init(defaultScopes: [BarrierScope]) {
            _defaultScopes = defaultScopes
        }

        func create(context: TealiumContext, configuration: DataObject) -> ConnectivityBarrier {
            ConnectivityBarrier(connectionManager: ConnectivityManager.shared,
                                configuration: configuration)
        }

        func defaultScopes() -> [BarrierScope] {
            _defaultScopes
        }
    }
}
