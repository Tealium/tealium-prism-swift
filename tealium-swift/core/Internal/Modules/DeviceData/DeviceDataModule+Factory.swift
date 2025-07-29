//
//  DeviceDataModule+Factory.swift
//  tealium-swift
//
//  Created by Den Guzov on 19/05/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

extension DeviceDataModule {
    class Factory: DefaultModuleFactory<DeviceDataModule> {
        init(forcingSettings block: ((_ enforcedSettings: DeviceDataSettingsBuilder) -> DeviceDataSettingsBuilder)? = nil) {
            super.init(enforcedSettings: block?(DeviceDataSettingsBuilder()).build())
        }
    }
}
