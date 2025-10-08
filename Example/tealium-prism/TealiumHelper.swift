//
//  TealiumHelper.swift
//  tealium-prism_Example
//
//  Created by Enrico Zannini on 16/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumPrism

class TealiumHelper {
    private(set) var teal: Tealium?
    var automaticDisposer = AutomaticDisposer()
    static let shared = TealiumHelper()
    let cmp = CustomCMP()
    func createModuleFactories() -> [any ModuleFactory] {
        [
            CustomCollector.Factory(),
            CustomDispatcher.Factory(),
            ModuleWithExternalDependencies.Factory(otherDependencies: NSObject())
        ]
    }

    func createTeal() -> Tealium {
        var config = TealiumConfig(account: "tealiummobile",
                                   profile: "enrico-test",
                                   environment: "dev",
                                   modules: createModuleFactories(),
                                   settingsFile: "TealiumSettings",
                                   settingsUrl: "https://tags.tiqcdn.com/dle/tealiummobile/lib/example_settings.json",
                                   forcingSettings: { builder in
            builder.setMinLogLevel(.trace)
                .setVisitorIdentityKey("email")
        })
        config.addBarrier(Barriers.batching())
        config.enableConsentIntegration(with: cmp) { enforcedConfiguration in
            enforcedConfiguration.setTealiumPurposeId(CustomCMP.Purposes.tealium.rawValue)
                .setRefireDispatchersIds([Modules.Types.collect])
                .addPurpose(CustomCMP.Purposes.tracking.rawValue, dispatcherIds: [
                    Modules.Types.collect,
                    CustomDispatcher.Factory.moduleType
                ])
        }
        return Tealium.create(config: config) { _ in }
    }
    func startTealium() {
        let teal = createTeal()
        self.teal = teal
        teal.dataLayer.transactionally { apply, getDataItem, commit in
            apply(.put(key: "key", value: "value", expiry: .forever))
            apply(.put(key: "key2", value: "value2", expiry: .forever))
            apply(.remove(key: "key3"))
            if let count = getDataItem("key4")?.get(as: Int.self) {
                apply(.put(key: "key4", value: count + 1, expiry: .forever))
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

    func flush() {
        teal?.flushEventQueue()
    }
}
