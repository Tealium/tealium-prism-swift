//
//  ConnectivityBarrier.swift
//  tealium-swift
//
//  Created by Denis Guzov on 29/05/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

class ConnectivityBarrier: Barrier {
    let id: String = "ConnectivityBarrier"
    let onState: Observable<BarrierState>

    // connectionAssumedAvailable value of ConnectivityManager is gonna be passed here
    init(onConnection onConnectionAvailable: Observable<Bool>) {
        onState = onConnectionAvailable.map { isConnected in
            isConnected ? .open : .closed
        }
    }
}
