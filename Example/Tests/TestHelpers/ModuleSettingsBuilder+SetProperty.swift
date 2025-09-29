//
//  ModuleSettingsBuilder+SetProperty.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 17/09/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism

extension ModuleSettingsBuilder {
    func setProperty(_ value: any DataInput, key: String) -> Self {
        _configurationObject.set(value, key: key)
        return self
    }

    func build(withModuleType moduleType: String) -> DataObject {
        self.build() + [Keys.moduleType: moduleType]
    }
}
