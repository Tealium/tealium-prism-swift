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
        _onCollect.publish(dispatchContext.initialData)
        return dispatchContext.initialData + dataToAdd
    }
}
