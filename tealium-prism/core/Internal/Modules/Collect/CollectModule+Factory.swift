//
//  CollectModule+Factory.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 08/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

extension CollectModule {

    class Factory: ModuleFactory {
        let allowsMultipleInstances: Bool = true
        let moduleType: String = Modules.Types.collect

        typealias Module = CollectModule
        let enforcedSettings: [DataObject]
        typealias SettingsBuilderBlock = Modules.EnforcingSettings<CollectSettingsBuilder>

        init(forcingSettings blocks: [SettingsBuilderBlock?] = []) {
            self.enforcedSettings = blocks.compactMap { block in block?(CollectSettingsBuilder()).build() }
        }

        public func create(moduleId: String, context: TealiumContext, moduleConfiguration: DataObject) -> Module? {
            Module(moduleId: moduleId, context: context, moduleConfiguration: moduleConfiguration)
        }

        public func getEnforcedSettings() -> [DataObject] {
            enforcedSettings
        }
    }
}
