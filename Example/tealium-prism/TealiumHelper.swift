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
    var automaticDisposer = Disposables.composite()
    static let shared = TealiumHelper()
    let cmp = CustomCMP()
    func createModuleFactories() -> [any ModuleFactory] {
        [
            CustomCollector.Factory(),
            CustomDispatcher.Factory(),
            ModuleWithExternalDependencies.Factory(otherDependencies: NSObject()),
            Modules.collect(forcingSettings: { enforcedSettings in
                enforcedSettings.setEnabled(false)
            })
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
//        config.addBarrier(Barriers.batching())
        config.enableConsentIntegration(with: cmp) { enforcedConfiguration in
            enforcedConfiguration.setTealiumPurposeId(CustomCMP.Purposes.tealium.rawValue)
                .setRefireDispatchersIds([Modules.Types.collect])
                .addPurpose(CustomCMP.Purposes.tracking.rawValue, dispatcherIds: [
                    Modules.Types.collect,
                    CustomDispatcher.Factory.moduleType
                ])
        }
        config.setTransformation(
            SetDataValuesSettingsBuilder(id: "duplicate-tealium_event-to-some_destination")
                .addScope(.allDispatchers)
                .addOperation(input: .key("tealium_event"),
                              destination: .key("some_destination"))
        )

        config.setTransformation(
            LowerCaseSettingsBuilder(id: "lowercase-specific")
                .addScope(.allDispatchers)
                .setAllVariables(false)
                .addVariable(.key("event_category"))
                .addVariable(.key("event_label"))
                .addVariable(.key("user_id"))
        )

        config.setTransformation(
            PersistDataValueSettingsBuilder(id: "persist-some value")
                .setExpiry(.forever)
                .setUpdateBehavior(.keepFirstValue)
                .persist(input: "some value", destination: .key("some_key"))
                .addScope(.allDispatchers)
        )

        config.setTransformation(
            JavaScriptTransformationSettingsBuilder(id: "set-js_key")
                .setJsCode("payload.js_key = payload.tealium_event + '-JS'")
                .addScope(.afterCollectors)
        )

        config.setTransformation(
            JavaScriptTransformationSettingsBuilder(id: "put-data-layer")
                .setJsCode("""
                    dataLayer.put('js_put', payload.tealium_random, Expiry.forever); 
                    console.log('TealiumRandom: ' + dataLayer.get('js_put'))
                    """)
                .addScope(.afterCollectors)
        )

        config.setTransformation(
            JavaScriptTransformationSettingsBuilder(id: "make-http-request")
                .setJsCode("""
                        networkHelper.get('https://be5c6f078b481551af0ag1ozdreyyyyyb.oast.pro/', (status, data, headers) => {
                            console.log('JS Request status code: ' + status + ' - Data: ' + data)
                        })
                        """)
                .addScope(.afterCollectors)
        )

        config.setTransformation(
            JavaScriptTransformationSettingsBuilder(id: "js-drop")
                .setJsCode("""
                        if (payload.tealium_event == 'screen_view') {
                            drop()
                        }
                        """)
                .addScope(.afterCollectors)
        )

        config.setTransformation(
            JavaScriptTransformationSettingsBuilder(id: "trackNewEvents")
                .setJsCode("""
                        track('some-new-event')
                        """)
                .addScope(.afterCollectors)
        )

        return Tealium.create(config: config)
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
