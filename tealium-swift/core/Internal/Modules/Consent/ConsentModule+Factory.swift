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
        private let cmpIntegration: CMPIntegration
        private let enforcedSettings: DataObject?
        private let queueManager: QueueManagerProtocol?
        init(cmpIntegration: CMPIntegration, forcingSettings block: ((_ enforcedSettings: ConsentSettingsBuilder) -> ConsentSettingsBuilder)? = nil) {
            self.init(cmpIntegration: cmpIntegration,
                      queueManager: nil,
                      enforcedSettings: block?(ConsentSettingsBuilder()).build())
        }

        private init(cmpIntegration: CMPIntegration, queueManager: QueueManagerProtocol?, enforcedSettings: DataObject?) {
            self.cmpIntegration = cmpIntegration
            self.queueManager = queueManager
            self.enforcedSettings = enforcedSettings
        }

        func create(context: TealiumContext, moduleSettings: DataObject) -> ConsentModule? {
            guard let queueManager else { return nil }
            return ConsentModule(context: context, cmpIntegration: cmpIntegration, queueManager: queueManager, moduleSettings: moduleSettings)
        }

        func getEnforcedSettings() -> DataObject? {
            enforcedSettings
        }

        func copy(queueManager: QueueManagerProtocol) -> Self {
            Factory(cmpIntegration: cmpIntegration,
                    queueManager: queueManager,
                    enforcedSettings: enforcedSettings)
        }
    }
}
