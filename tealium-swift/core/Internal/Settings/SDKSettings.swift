//
//  SDKSettings.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 26/06/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/// A container of settings for each module.
struct SDKSettings {
    enum Keys {
        static let core = "core"
        static let modules = "modules"
        static let loadRules = "load_rules"
        static let transformations = "transformations"
        static let barriers = "barriers"
        static let consent = "consent"
    }
    let core: CoreSettings
    let modules: [String: ModuleSettings]
    let loadRules: [String: LoadRule]
    let transformations: [String: TransformationSettings]
    let barriers: [String: BarrierSettings]
    let consent: ConsentSettings?

    init(_ settings: DataObject) {
        self.init(
            core: settings.getConvertible(key: Keys.core,
                                          converter: CoreSettings.converter) ?? CoreSettings(),
            modules: settings.getDataDictionary(key: Keys.modules)?
                .compactMapValues { $0.getConvertible(converter: ModuleSettings.converter) } ?? [:],
            loadRules: settings.getDataDictionary(key: Keys.loadRules)?
                .compactMapValues {
                    $0.getConvertible(converter: LoadRule.converter)
                } ?? [:],
            transformations: settings.getDataDictionary(key: Keys.transformations)?
                .compactMapValues {
                    $0.getConvertible(converter: TransformationSettings.converter)
                } ?? [:],
            barriers: settings.getDataDictionary(key: Keys.barriers)?
                .compactMapValues {
                    $0.getConvertible(converter: BarrierSettings.converter)
                } ?? [:],
            consent: settings.getConvertible(key: Keys.consent,
                                             converter: ConsentSettings.converter)
        )
    }

    init(core: CoreSettings = CoreSettings(),
         modules: [String: ModuleSettings] = [:],
         loadRules: [String: LoadRule] = [:],
         transformations: [String: TransformationSettings] = [:],
         barriers: [String: BarrierSettings] = [:],
         consent: ConsentSettings? = nil
    ) {
        self.core = core
        self.modules = modules
        self.loadRules = loadRules
        self.transformations = transformations
        self.barriers = barriers
        self.consent = consent
    }
}
