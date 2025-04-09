//
//  TraceManagerModule+Factory.swift
//  tealium-swift
//
//  Created by Den Guzov on 04/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

extension TraceManagerModule {
    class Factory: TealiumModuleFactory {
        typealias Module = TraceManagerModule

        func create(context: TealiumContext, moduleConfiguration: DataObject) -> Module? {
            guard let dataStore = try? context.moduleStoreProvider.getModuleStore(name: TraceManagerModule.id) else {
                return nil
            }
            return TraceManagerModule(dataStore: dataStore, tracker: context.tracker)
        }
    }
}
