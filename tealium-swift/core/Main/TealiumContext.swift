//
//  TealiumContext.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public class TealiumContext {
    public weak var tealiumProtocol: TealiumProtocol?
    public let config: TealiumConfig
    public var coreSettings: CoreSettings
    public let databaseHelper: DatabaseHelper?
    public weak var modulesManager: ModulesManager?

    @ToAnyObservable<TealiumReplaySubject<CoreSettings>>(TealiumReplaySubject<CoreSettings>())
    var onSettingsUpdate: TealiumObservable<CoreSettings>

    init(_ teal: TealiumProtocol, modulesManager: ModulesManager, config: TealiumConfig, coreSettings: CoreSettings, databaseHelper: DatabaseHelper?) {
        self.tealiumProtocol = teal
        self.modulesManager = modulesManager
        self.config = config
        self.coreSettings = coreSettings
        self.databaseHelper = databaseHelper
    }

    func updateSettings(_ dict: [String: Any]) {
        coreSettings.updateSettings(dict)
        _onSettingsUpdate.publish(coreSettings)
    }
}
