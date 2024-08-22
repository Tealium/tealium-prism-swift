//
//  ConsentModule+Factory.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

extension ConsentModule {
    struct Factory: TealiumModuleFactory {
        typealias Module = ConsentModule
        let cmpIntegration: CMPIntegration
        let enforcedSettings: [String: Any]?
        private var queueManager: QueueManagerProtocol?
        init(cmpIntegration: CMPIntegration, forcingSettings block: ((_ enforcedSettings: ConsentSettingsBuilder) -> ConsentSettingsBuilder)? = nil) {
            self.cmpIntegration = cmpIntegration
            enforcedSettings = block?(ConsentSettingsBuilder()).build()
        }
        func create(context: TealiumContext, moduleSettings: [String: Any]) -> ConsentModule? {
            guard let queueManager else { return nil }
            return ConsentModule(context: context, cmpIntegration: cmpIntegration, queueManager: queueManager, moduleSettings: moduleSettings)
        }
        func getEnforcedSettings() -> [String: Any]? {
            enforcedSettings
        }
        mutating func setQueueManager(_ queueManager: QueueManagerProtocol) {
            self.queueManager = queueManager
        }
    }
}
