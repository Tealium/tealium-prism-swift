//
//  StubModuleFactory.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 24/07/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import TealiumPrism

class StubModuleFactory<SpecificModule: Module>: ModuleFactory {
    let allowsMultipleInstances: Bool = false
    let moduleType: String
    let module: SpecificModule
    init(module: SpecificModule) {
        self.module = module
        self.moduleType = String(describing: type(of: module))
    }

    func create(moduleId: String, context: TealiumContext, moduleConfiguration: DataObject) -> SpecificModule? {
        module
    }

    func getEnforcedSettings() -> [DataObject] {
        [ModuleSettingsBuilder().build()]
    }
}
