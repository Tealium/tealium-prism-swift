//
//  DeepLinkModule+Factory.swift
//  tealium-swift
//
//  Created by Den Guzov on 15/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

extension DeepLinkModule {
    class Factory: DefaultModuleFactory<DeepLinkModule> {
        init(forcingSettings block: ((_ enforcedSettings: DeepLinkSettingsBuilder) -> DeepLinkSettingsBuilder)? = nil) {
            super.init(enforcedSettings: block?(DeepLinkSettingsBuilder()).build())
        }
    }
}
