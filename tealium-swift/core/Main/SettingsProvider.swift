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
    @TealiumVariableSubject var settings: TealiumStatefulObservable<[String: Any]>
    let coreSettings: TealiumStatefulObservable<CoreSettings>

    init(config: TealiumConfig, storeProvider: ModuleStoreProvider) {
        let trackingInterval = TealiumSignpostInterval(signposter: .settings, name: "Settings Retrieval")
            .begin(config.configFile)
        guard let path = Bundle.main.path(forResource: config.configFile, ofType: "json"),
            let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe),
            let settings = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        else {
            trackingInterval.end("FAILED")
            self._settings = TealiumVariableSubject([:])
            self.coreSettings = TealiumStatefulObservable(variableSubject: TealiumVariableSubject(CoreSettings(coreDictionary: [:])))
            return
        }
        trackingInterval.end("SUCCESS")
        let mutableSettings = TealiumVariableSubject(settings)
        self._settings = mutableSettings
        self.coreSettings = mutableSettings.toStatefulObservable()
            .map { settings in CoreSettings(coreDictionary: settings["core"] as? [String: Any] ?? [:]) }
    }

}
