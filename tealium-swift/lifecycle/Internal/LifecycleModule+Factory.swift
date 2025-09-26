//
//  LifecycleModule+Factory.swift
//  tealium-swift
//
//  Created by Den Guzov on 05/12/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

#if lifecycle
import TealiumCore
#endif

extension LifecycleModule {
    class Factory: ModuleFactory {
        let enforcedSettings: [DataObject]
        let moduleType: String = Modules.Types.lifecycle
        let allowsMultipleInstances: Bool = false
        typealias SettingsBuilderBlock = Modules.EnforcingSettings<LifecycleSettingsBuilder>

        init(forcingSettings block: SettingsBuilderBlock? = nil) {
            self.enforcedSettings = [block?(LifecycleSettingsBuilder()).build()].compactMap { $0 }
        }

        func create(moduleId: String, context: TealiumContext, moduleConfiguration: DataObject) -> LifecycleModule? {
            LifecycleModule(context: context, moduleConfiguration: moduleConfiguration)
        }

        func getEnforcedSettings() -> [DataObject] {
            return enforcedSettings
        }
    }
}
