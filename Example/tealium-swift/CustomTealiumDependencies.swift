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
    let version: String = "1.0.0"
    func dispatch(_ data: [Dispatch], completion: @escaping ([Dispatch]) -> Void) -> Disposable {
        print("CustomDispatcher dispatch: \(data.compactMap { $0.name })")
        completion(data)
        return Subscription { }
    }

    static let id: String = "CustomDispatcher"
    
    required init?(context: TealiumContext, moduleConfiguration: [String : Any]) {

    }
}

class SomeModule: TealiumBasicModule, Collector {
    let version: String = "1.0.0"
    func collect(_ dispatchContext: DispatchContext) -> DataObject {
        ["someKey": "someValue"]
    }
    
    
    static var id: String = "someModule"
    
    required init?(context: TealiumContext, moduleConfiguration: DataObject) {

    }
    
    func updateConfiguration(_ configuration: DataObject) -> Self? {
        return self
    }
}

class ModuleWithExternalDependencies: TealiumModule {
    let version: String = "1.0.0"
    static var id: String = "complexModule"
    init(otherDependencies: Any) {
        
    }
    func updateConfiguration(_ configuration: DataObject) -> Self? {
        return self
    }
    
    struct Factory: TealiumModuleFactory {
        typealias Module = ModuleWithExternalDependencies
        let object: Any
        init(otherDependencies: Any) {
            self.object = otherDependencies
        }
        func create(context: TealiumContext, moduleConfiguration: DataObject) -> ModuleWithExternalDependencies? {
            ModuleWithExternalDependencies(otherDependencies: object)
        }
    }
}
