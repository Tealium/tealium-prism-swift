//
//  MockModuleFactory.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/07/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import TealiumSwift

class MockModuleFactory<SpecificModule: Module>: ModuleFactory {
    let module: SpecificModule
    init(module: SpecificModule) {
        self.module = module
    }

    func create(context: TealiumContext, moduleConfiguration: DataObject) -> SpecificModule? {
        module
    }

    func getEnforcedSettings() -> DataObject? {
        nil
    }
}
