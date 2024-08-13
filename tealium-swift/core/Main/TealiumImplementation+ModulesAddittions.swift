//
//  TealiumImplementation+ModulesAddittions.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

extension TealiumImplementation {
    static func addMandatoryAndRemoveDuplicateModules(from config: inout TealiumConfig) {
        var moduleIdSet = Set<String>()
        let modules = (config.modules + [
            TealiumModules.dataLayer(),
            TealiumModules.tealiumCollector()
        ]).filter { moduleIdSet.insert($0.id).inserted }
        config.modules = modules
    }

    static func addQueueManager(_ queueManager: QueueManagerProtocol, toConsentInConfig config: inout TealiumConfig) {
        config.modules = config.modules.map { factory in
            guard var factoryWithQueueManager = factory as? ConsentModule.Factory else {
                 return factory
            }
            factoryWithQueueManager.setQueueManager(queueManager)
            return factoryWithQueueManager
        }
    }
}
