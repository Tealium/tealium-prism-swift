//
//  ConnectivityBarrier.swift
//  tealium-prism
//
//  Created by Denis Guzov on 29/05/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

struct ConnectivityBarrierConfiguration {
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
    private let wifiOnly: StateSubject<Bool>
    private let connectionManager: ConnectivityManagerProtocol

    init(connectionManager: ConnectivityManagerProtocol, configuration: DataObject) {
        wifiOnly = StateSubject(ConnectivityBarrierConfiguration(dataObject: configuration).wifiOnly)
        self.connectionManager = connectionManager
    }

    var isFlushable: Observable<Bool> {
        connectionManager.connection.mapState { $0.isConnected }
    }

    /** `dispatcherId` is ignored for ConnectivityBarrier */
    func onState(for dispatcherId: String) -> Observable<BarrierState> {
        let onConnectionAllowed = connectionManager.connection
            .combineLatest(wifiOnly.asObservable())
            .map { connection, wifiOnly in
                guard wifiOnly, case let .connected(connectionType) = connection else {
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
        wifiOnly.value = ConnectivityBarrierConfiguration(dataObject: configuration).wifiOnly
    }

}

extension ConnectivityBarrier {
    class Factory: BarrierFactory {
        let _defaultScope: BarrierScope
        let enforcedSettings: DataObject

        init(defaultScope: BarrierScope, enforcedSettings: DataObject? = nil) {
            _defaultScope = defaultScope
            self.enforcedSettings = enforcedSettings ?? [:]
        }

        func create(context: TealiumContext, configuration: DataObject) -> ConnectivityBarrier {
            ConnectivityBarrier(connectionManager: context.connectivityManager,
                                configuration: configuration)
        }

        func defaultScope() -> BarrierScope {
            _defaultScope
        }

        func getEnforcedSettings() -> DataObject {
            enforcedSettings
        }
    }
}
