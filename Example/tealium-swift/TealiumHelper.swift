//
//  TealiumHelper.swift
//  tealium-swift_Example
//
//  Created by Enrico Zannini on 16/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumSwift

class TealiumHelper {
    private(set) var teal: Tealium?
    var automaticDisposer = AutomaticDisposer()
    static let shared = TealiumHelper()
    
    func startTealium() {
        let config = TealiumConfig(account: "tealiummobile",
                                   profile: "enrico-test",
                                   environment: "dev",
                                   modules: [
                                    TealiumModules.appData(),
                                    TealiumModules.deepLink(),
                                    TealiumModules.trace(),
                                    TealiumModules.collect(forcingSettings: { enforcedSettings in
                                        enforcedSettings.setEnabled(true)
                                    }),
                                    TealiumModules.consent(cmpIntegration: CustomCMP(),
                                                           forcingSettings: { enforcedSettings in
                                        enforcedSettings.setEnabled(false)
                                    }),
                                    TealiumModules.lifecycle(forcingSettings: { enforcedSettings in
                                        enforcedSettings.setEnabled(true)
                                    }),
                                    TealiumModules.customCollector(SomeModule.self),
                                    ModuleWithExternalDependencies.Factory(otherDependencies: NSObject())
                                   ],
                                   settingsFile: "TealiumConfig",
                                   settingsUrl: "https://api.npoint.io/f55d57e09b802cde39f9",
                                   forcingSettings: { builder in
            builder.setMinLogLevel(.trace)
                .setVisitorIdentityKey("email")
                .setScopedBarriers([ScopedBarrier(barrierId: "ConnectivityBarrier", scopes: [.dispatcher("Collect")])])
        })
        let teal = Tealium.create(config: config) { result in
            
        }
        self.teal = teal
        teal.dataLayer.transactionally { apply, getDataItem, commit in
            apply(.put("key", "value", .forever))
            apply(.put("key2", "value2", .forever))
            apply(.remove("key3"))
            if let count = getDataItem("key4")?.get(as: Int.self) {
                apply(.put("key4", count + 1, .forever))
            }
            do {
                try commit()
            } catch {
                print(error)
            }
        }
    }

    func stopTealium() {
        self.teal = nil
    }
    
}
