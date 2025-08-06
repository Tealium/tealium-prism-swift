//
//  MockCollector.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 26/03/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import TealiumSwift

class MockCollector: MockModule, Collector {
    @ToAnyObservable(BasePublisher())
    var onCollect: Observable<DataObject>

    override class var id: String { "MockCollector" }

    var dataToAdd: DataObject

    override init() {
        dataToAdd = [Self.id: "value"]
        super.init()
    }
    required init?(context: TealiumContext, moduleConfiguration: DataObject) {
        dataToAdd = [Self.id: "value"]
        super.init(context: context, moduleConfiguration: moduleConfiguration)
    }

    func collect(_ dispatchContext: DispatchContext) -> DataObject {
        _onCollect.publish(dispatchContext.initialData)
        return dispatchContext.initialData + dataToAdd
    }
}

class MockCollector1: MockCollector {
    override class var id: String { "collector1" }
}

class MockCollector2: MockCollector {
    override class var id: String { "collector2" }
}
