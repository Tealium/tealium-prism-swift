//
//  TraceModule+Factory.swift
//  tealium-swift
//
//  Created by Den Guzov on 04/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

extension TraceModule {
    class Factory: DefaultModuleFactory<TraceModule> {
        init(forcingSettings block: ((_ enforcedSettings: CollectorSettingsBuilder) -> CollectorSettingsBuilder)? = nil) {
            super.init(enforcedSettings: block?(CollectorSettingsBuilder()).build())
        }
    }
}
