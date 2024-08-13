//
//  TealiumCollector.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

class TealiumCollector: TealiumBasicModule, Collector {
    static var canBeDisabled: Bool { false }
    var data: TealiumDictionaryInput {
        let config = context.config
        return TealiumDictionaryInput(removingOptionals: [
            TealiumDataKey.account: config.account,
            TealiumDataKey.profile: config.profile,
            TealiumDataKey.environment: config.environment,
            TealiumDataKey.enabledModules: context.modulesManager?.modules.value.map { $0.id } ?? []
        ])
    }

    static let id: String = "TealiumCollector"

    let context: TealiumContext
    required init(context: TealiumContext, moduleSettings: [String: Any]) {
        self.context = context
    }
}
