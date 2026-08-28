//
//  ConnectivityDataModule.swift
//  tealium-prism
//
//  Created by Den Guzov on 26/02/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

class ConnectivityDataModule: BasicModule, Collector {
    let version: String = TealiumConstants.libraryVersion
    let manager: ConnectivityManagerProtocol
    let id = Modules.Types.connectivityData

    required convenience init?(context: TealiumContext, moduleConfiguration: DataObject) {
        self.init(manager: context.network.connectivityManager)
    }

    init(manager: ConnectivityManagerProtocol) {
        self.manager = manager
    }

    func collect(_ dispatchContext: DispatchContext) -> DataObject {
        [TealiumDataKey.connectionType: manager.connection.value.toString()]
    }
}

public extension TealiumDataKey {
    static let connectionType = "connection_type"
}
