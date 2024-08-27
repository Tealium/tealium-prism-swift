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
        private let enforcedSettings: [String: Any]?
        private let queueManager: QueueManagerProtocol?
        init(cmpIntegration: CMPIntegration, forcingSettings block: ((_ enforcedSettings: ConsentSettingsBuilder) -> ConsentSettingsBuilder)? = nil) {
            self.init(cmpIntegration: cmpIntegration,
                      queueManager: nil,
                      enforcedSettings: block?(ConsentSettingsBuilder()).build())
        }

        private init(cmpIntegration: CMPIntegration, queueManager: QueueManagerProtocol?, enforcedSettings: [String: Any]?) {
            self.cmpIntegration = cmpIntegration
            self.queueManager = queueManager
            self.enforcedSettings = enforcedSettings
        }

        func create(context: TealiumContext, moduleSettings: [String: Any]) -> ConsentModule? {
            guard let queueManager else { return nil }
            return ConsentModule(context: context, cmpIntegration: cmpIntegration, queueManager: queueManager, moduleSettings: moduleSettings)
        }

        func getEnforcedSettings() -> [String: Any]? {
            enforcedSettings
        }

        func copy(queueManager: QueueManagerProtocol) -> Self {
            Factory(cmpIntegration: cmpIntegration,
                    queueManager: queueManager,
                    enforcedSettings: enforcedSettings)
        }
    }
}
