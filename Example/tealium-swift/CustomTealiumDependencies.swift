//
//  CustomTealiumDependencies.swift
//  tealium-swift_Example
//
//  Created by Enrico Zannini on 16/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumSwift

class CustomDispatcher: Dispatcher {
    let id: String = Factory.moduleType
    let version: String = "1.0.0"
    func dispatch(_ data: [Dispatch], completion: @escaping ([Dispatch]) -> Void) -> Disposable {
        print("CustomDispatcher dispatch: \(data.compactMap { $0.name })")
        completion(data)
        return Subscription { }
    }

    init(context: TealiumContext, moduleConfiguration: DataObject) { }

    struct Factory: ModuleFactory {
        let allowsMultipleInstances: Bool = false

        static let moduleType: String = "CustomDispatcher"
        var moduleType: String { Self.moduleType }

        func create(moduleId: String, context: TealiumContext, moduleConfiguration: DataObject) -> CustomDispatcher? {
            CustomDispatcher(context: context, moduleConfiguration: moduleConfiguration)
        }
    }
}

class CustomCollector: Collector {
    let id: String = Factory.moduleType
    let version: String = "1.0.0"
    func collect(_ dispatchContext: DispatchContext) -> DataObject {
        ["someKey": "someValue"]
    }

    init(context: TealiumContext, moduleConfiguration: DataObject) { }

    func updateConfiguration(_ configuration: DataObject) -> Self? {
        return self
    }

    struct Factory: ModuleFactory {
        let allowsMultipleInstances: Bool = false

        static let moduleType: String = "CustomCollector"
        var moduleType: String { Self.moduleType }

        func create(moduleId: String, context: TealiumContext, moduleConfiguration: DataObject) -> CustomDispatcher? {
            CustomDispatcher(context: context, moduleConfiguration: moduleConfiguration)
        }
    }
}

class ModuleWithExternalDependencies: Module {
    let version: String = "1.0.0"
    let id: String = Factory.moduleType
    init(otherDependencies: Any) { }

    func updateConfiguration(_ configuration: DataObject) -> Self? {
        return self
    }
    
    struct Factory: ModuleFactory {
        let allowsMultipleInstances: Bool = false
        static let moduleType: String = "ComplexModule"
        var moduleType: String { Self.moduleType }

        let object: Any
        init(otherDependencies: Any) {
            self.object = otherDependencies
        }
        func create(moduleId: String, context: TealiumContext, moduleConfiguration: DataObject) -> ModuleWithExternalDependencies? {
            ModuleWithExternalDependencies(otherDependencies: object)
        }
    }
}
