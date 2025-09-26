//
//  ConnectivityDataModule.swift
//  tealium-swift
//
//  Created by Den Guzov on 26/02/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

class ConnectivityDataModule: BasicModule, Collector {
    let version: String = TealiumConstants.libraryVersion
    let monitor: ConnectivityMonitorProtocol
    let id = Modules.Types.connectivityData

    required convenience init?(context: TealiumContext, moduleConfiguration: DataObject) {
        self.init()
    }

    init(monitor: ConnectivityMonitorProtocol = ConnectivityMonitor.shared) {
        self.monitor = monitor
    }

    func collect(_ dispatchContext: DispatchContext) -> DataObject {
        [TealiumDataKey.connectionType: monitor.connection.value.toString()]
    }
}

public extension TealiumDataKey {
    static let connectionType = "connection_type"
}
