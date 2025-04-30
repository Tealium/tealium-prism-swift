//
//  ConnectivityBarrier.swift
//  tealium-swift
//
//  Created by Denis Guzov on 29/05/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

struct ConnectivitySettings {
    enum Keys {
        static let wifiOnly = "wifiOnly"
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
    @ToAnyObservable<ReplaySubject<BarrierState>>(ReplaySubject())
    var onState: Observable<BarrierState>
    let settings: StateSubject<ConnectivitySettings>
    let disposer = AutomaticDisposer()

    init(connectionManager: ConnectivityManagerProtocol, configuration: DataObject) {
        settings = StateSubject(ConnectivitySettings(dataObject: configuration))

        let onConnectionAllowed = connectionManager.connection
            .combineLatest(settings.asObservable())
            .map { connection, settings in
                guard settings.wifiOnly,
                      case let .connected(connectionType) = connection else {
                    return true
                }
                return connectionType != .cellular // Allow both wifi and ethernet
            }

        connectionManager.connectionAssumedAvailable
            .combineLatest(onConnectionAllowed)
            .map { isConnected, connectionIsAllowed in
                guard isConnected && connectionIsAllowed else {
                    return BarrierState.closed
                }
                return BarrierState.open
            }.subscribe(_onState.publisher)
            .addTo(disposer)
    }

    func updateConfiguration(_ configuration: DataObject) {
        settings.value = ConnectivitySettings(dataObject: configuration)
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
