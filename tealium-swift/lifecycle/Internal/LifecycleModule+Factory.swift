//
//  LifecycleModule+Factory.swift
//  tealium-swift
//
//  Created by Den Guzov on 05/12/2024.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

extension LifecycleModule {
    class Factory: TealiumModuleFactory {
        typealias Module = LifecycleModule

        private var settings: DataObject?

        init(forcingSettings block: ((_ enforcedSettings: LifecycleSettingsBuilder) -> LifecycleSettingsBuilder)? = nil) {
            settings = block?(LifecycleSettingsBuilder()).build()
        }

        func getEnforcedSettings() -> DataObject? {
            return settings
        }

        func create(context: TealiumContext, moduleConfiguration: DataObject) -> Module? {
            guard let dataStore = try? context.moduleStoreProvider.getModuleStore(name: LifecycleModule.id) else {
                return nil
            }
            return LifecycleModule(
                context: context,
                configuration: LifecycleConfiguration(configuration: moduleConfiguration),
                service: LifecycleService(lifecycleStorage: LifecycleStorage(dataStore: dataStore),
                                          bundle: context.config.bundle)
            )
        }
    }
}
