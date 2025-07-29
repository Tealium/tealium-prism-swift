//
//  CollectModule+Factory.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 08/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

extension CollectModule {
    class Factory: DefaultModuleFactory<CollectModule> {
        init(forcingSettings block: ((_ enforcedSettings: CollectSettingsBuilder) -> CollectSettingsBuilder)? = nil) {
            super.init(enforcedSettings: block?(CollectSettingsBuilder()).build())
        }
    }
}
