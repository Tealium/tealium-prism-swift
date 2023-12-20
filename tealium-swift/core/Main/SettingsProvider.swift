//
//  SettingsProvider.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 20/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A class that when instantiated reads the settings locally and then sets up a timer to refresh the settings via an API and inform who is registered on settings updates.
 */
class SettingsProvider {
    @TealiumMutableState var settings: TealiumObservableState<[String: Any]>
    let coreSettings: TealiumObservableState<CoreSettings>
    let consentSettings: TealiumObservableState<ConsentSettings>

    init(config: TealiumConfig, storeProvider: ModuleStoreProvider) {
        let trackingInterval = TealiumSignpostInterval(signposter: .settings, name: "Settings Retrieval")
            .begin(config.configFile)
        guard let path = Bundle.main.path(forResource: config.configFile, ofType: "json"),
            let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe),
            let settings = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        else {
            trackingInterval.end("FAILED")
            self._settings = TealiumMutableState([:])
            self.coreSettings = TealiumObservableState(mutableState: TealiumMutableState(CoreSettings(coreDictionary: [:])))
            self.consentSettings = TealiumObservableState(mutableState: TealiumMutableState(ConsentSettings(consentDictionary: [:])))
            return
        }
        trackingInterval.end("SUCCESS")
        let mutableSettings = TealiumMutableState(settings)
        self._settings = mutableSettings
        self.coreSettings = mutableSettings.toObservableState()
            .map { settings in CoreSettings(coreDictionary: settings["core"] as? [String: Any] ?? [:]) }
        self.consentSettings = mutableSettings.toObservableState()
            .map { settings in ConsentSettings(consentDictionary: settings["consent"] as? [String: Any] ?? [:]) }
    }

}
