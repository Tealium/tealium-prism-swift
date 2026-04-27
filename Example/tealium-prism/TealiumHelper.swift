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
    static let shared = TealiumHelper()
    let cmp = CustomCMP()
    var disposable: Disposable = Disposables.disposed()
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
                                   profile: "demo",
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
                .setRefireDispatcherIds([Modules.Types.collect])
                .addPurpose(CustomCMP.Purposes.tracking.rawValue, dispatcherIds: [
                    Modules.Types.collect,
                    CustomDispatcher.Factory.moduleType
                ])
        }
        config.setTransformation(
            SetDataValuesSettingsBuilder(id: "duplicate-tealium_event-to-some_destination")
                .setScope(.allDispatchers)
                .setFrom(.key("tealium_event"), to: .key("some_destination"))
                .setOrder(0)
        )

        config.setTransformation(
            LowercaseSettingsBuilder(id: "lowercase-specific")
                .setScope(.allDispatchers)
                .setOrder(1)
                .lowercaseVariables([.key("event_category"), .key("event_label"), .key("user_id")])
        )

        config.setTransformation(
            PersistDataValueSettingsBuilder(id: "persist-some value")
                .setExpiryPolicy(.forever)
                .setUpdatePolicy(.keepFirstValue)
                .persistConstant("some value", to: .key("some_key"))
                .setScope(.allDispatchers)
                .setOrder(2)
        )

        config.setTransformation(
            JavaScriptTransformationSettingsBuilder(id: "set-js_key")
                .setJsCode("payload.js_key = payload.tealium_event + '-JS'")
                .setScope(.afterCollectors)
                .setOrder(3)
        )

        config.setTransformation(
            JavaScriptTransformationSettingsBuilder(id: "put-data-layer")
                .setJsCode("""
                    dataLayer.put('js_put', payload.tealium_random, Expiry.forever); 
                    console.log('TealiumRandom: ' + dataLayer.get('js_put'))
                    """)
                .setScope(.afterCollectors)
                .setOrder(2)
        )

//        config.setTransformation(
//            JavaScriptTransformationSettingsBuilder(id: "make-http-request")
//                .setJsCode("""
//                        network.get('https://jsonplaceholder.typicode.com/todos/1', (status, data, headers) => {
//                            console.log('JS Request status code: ' + status + ' - Data: ' + JSON.stringify(data, null, 2))
//                        })
//                        """)
//                .setScope(.afterCollectors)
//                .setOrder(1)
//        )

        config.setTransformation(
            JavaScriptTransformationSettingsBuilder(id: "js-drop")
                .setJsCode("""
                        if (payload.tealium_event == 'screen_view') {
                            drop()
                        }
                        """)
                .setScope(.afterCollectors)
                .setOrder(4)
        )

        config.setTransformation(
            JavaScriptTransformationSettingsBuilder(id: "trackNewEvents")
                .setJsCode("""
                        track('some-new-event')
                        """)
                .setScope(.afterCollectors)
                .setOrder(5)
        )

        return Tealium.create(config: config)
    }

    func startTealium() {
        let teal = createTeal()
        disposable = teal.createDisposable()
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
        }.addTo(disposable)
    }

    func stopTealium() {
        disposable.dispose()
        self.teal = nil
    }

    func flush() {
        teal?.flushEventQueue()
            .subscribe { _ in }
            .addTo(disposable)
    }
}
