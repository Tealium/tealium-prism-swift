//
//  TraceManagerModule+Factory.swift
//  tealium-swift
//
//  Created by Den Guzov on 04/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

extension TraceManagerModule {
    class Factory: DefaultModuleFactory<TraceManagerModule> {
        init(forcingSettings block: ((_ enforcedSettings: CollectorSettingsBuilder) -> CollectorSettingsBuilder)? = nil) {
            super.init(enforcedSettings: block?(CollectorSettingsBuilder()).build())
        }
    }
}
