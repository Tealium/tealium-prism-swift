//
//  MockCollector.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 26/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import TealiumPrism

class MockCollector: MockModule, Collector {
    @Subject<DataObject> var onCollect

    override class var moduleType: String { "MockCollector" }

    var dataToAdd: DataObject

    required init(moduleId: String = MockCollector.moduleType) {
        dataToAdd = [moduleId: "value"]
        super.init(moduleId: moduleId)
    }
    required init?(moduleId: String, context: TealiumContext, moduleConfiguration: DataObject) {
        dataToAdd = [moduleId: "value"]
        super.init(moduleId: moduleId, context: context, moduleConfiguration: moduleConfiguration)
    }

    func collect(_ dispatchContext: DispatchContext) -> DataObject {
        _onCollect.onNext(dispatchContext.initialData)
        return dispatchContext.initialData + dataToAdd
    }
}

// No `moduleType` override: `MockModule.factory()` derives it from the class name, and a settings
// key has to match the factory's.
class MockCollector2: MockCollector {
    required init(moduleId: String = MockCollector2.moduleType) {
        super.init(moduleId: moduleId)
    }
    required init?(moduleId: String, context: TealiumContext, moduleConfiguration: DataObject) {
        super.init(moduleId: moduleId, context: context, moduleConfiguration: moduleConfiguration)
    }
}
