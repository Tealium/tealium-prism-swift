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

    func createModuleFactories() -> [any TealiumModuleFactory] {
        [
         TealiumModules.appData(),
         TealiumModules.deepLink(forcingSettings: { enforcedSettings in
             enforcedSettings.setSendDeepLinkEvent(true)
         }),
         TealiumModules.trace(forcingSettings: { enforcedSettings in
             enforcedSettings.setEnabled(true)
         }),
         TealiumModules.collect(forcingSettings: { enforcedSettings in
             enforcedSettings.setEnabled(true)
         }),
         TealiumModules.deviceData(forcingSettings: { enforcedSettings in
             enforcedSettings.setMemoryReportingEnabled(true)
         }),
         TealiumModules.lifecycle(forcingSettings: { enforcedSettings in
             enforcedSettings.setEnabled(true)
         }),
         TealiumModules.customCollector(SomeModule.self),
         TealiumModules.timeCollector(),
         TealiumModules.connectivityCollector(),
         ModuleWithExternalDependencies.Factory(otherDependencies: NSObject())
        ]
    }

    func createTeal() -> Tealium {
        let config = TealiumConfig(account: "tealiummobile",
                                   profile: "enrico-test",
                                   environment: "dev",
                                   modules: createModuleFactories(),
                                   settingsFile: "TealiumConfig",
                                   settingsUrl: "https://api.npoint.io/e6449d2df760465f7d7f",
                                   forcingSettings: { builder in
            builder.setMinLogLevel(.trace)
                .setVisitorIdentityKey("email")
        })
// Uncomment to enable consent. At the moment this will block everything due to no functioning consent adapter and no configuration setup for the dispatchers' purposes.
//        config.enableConsentIntegration(with: CustomCmp()) { enforcedConfiguration in
//            enforcedConfiguration.setTealiumPurposeId("tealium")
//                .setRefireDispatchersIds(["collect"])
//                .addPurpose("purpose1", dispatcherIds: ["dispatcher_id_1"])
//        }
        return Tealium.create(config: config) { _ in }
    }
    func startTealium() {
        let teal = createTeal()
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
        }.onFailure { error in
            print("Transaction update failed with \(error)")
        }
    }

    func stopTealium() {
        self.teal = nil
    }
    
}
