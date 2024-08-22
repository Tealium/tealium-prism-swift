//
//  TealiumCollect+Factory.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 08/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

extension TealiumCollect {
    struct Factory: TealiumModuleFactory {
        typealias Module = TealiumCollect
        let enforcedSettings: [String: Any]?
        init(forcingSettings block: ((_ enforcedSettings: CollectSettingsBuilder) -> CollectSettingsBuilder)? = nil) {
            let builder = block?(CollectSettingsBuilder())
            enforcedSettings = builder?.build()
        }
        func create(context: TealiumContext, moduleSettings: [String: Any]) -> TealiumCollect? {
            TealiumCollect(context: context, moduleSettings: moduleSettings)
        }
        func getEnforcedSettings() -> [String: Any]? {
            enforcedSettings
        }
    }
}
