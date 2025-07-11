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
    let cmp = CustomCMP()
    func createModuleFactories() -> [any TealiumModuleFactory] {
        [
         Modules.appData(),
         Modules.deepLink(forcingSettings: { enforcedSettings in
             enforcedSettings.setSendDeepLinkEvent(true)
         }),
         Modules.trace(forcingSettings: { enforcedSettings in
             enforcedSettings.setEnabled(true)
         }),
         Modules.collect(forcingSettings: { enforcedSettings in
             enforcedSettings.setEnabled(true)
         }),
         Modules.deviceData(forcingSettings: { enforcedSettings in
             enforcedSettings.setMemoryReportingEnabled(true)
         }),
         Modules.lifecycle(forcingSettings: { enforcedSettings in
             enforcedSettings.setEnabled(true)
         }),
         Modules.customCollector(SomeModule.self),
         Modules.timeCollector(),
         Modules.connectivityCollector(),
         ModuleWithExternalDependencies.Factory(otherDependencies: NSObject())
        ]
    }

    func createTeal() -> Tealium {
        var config = TealiumConfig(account: "tealiummobile",
                                   profile: "enrico-test",
                                   environment: "dev",
                                   modules: createModuleFactories(),
                                   settingsFile: "TealiumConfig",
                                   settingsUrl: "https://api.npoint.io/e6449d2df760465f7d7f",
                                   forcingSettings: { builder in
            builder.setMinLogLevel(.trace)
                .setVisitorIdentityKey("email")
        })
        config.addBarrier(Barriers.batching())
        config.enableConsentIntegration(with: cmp) { enforcedConfiguration in
            enforcedConfiguration.setTealiumPurposeId("tealium")
                .setRefireDispatchersIds([Modules.IDs.collect])
                .addPurpose("tracking", dispatcherIds: [Modules.IDs.collect])
        }
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
