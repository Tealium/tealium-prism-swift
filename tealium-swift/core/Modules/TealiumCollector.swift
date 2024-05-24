//
//  TealiumCollector.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

public class TealiumCollector: Collector {
    public var data: TealiumDictionaryInput {
        let config = context.config
        return TealiumDictionaryInput(removingOptionals: [
            TealiumDataKey.account: config.account,
            TealiumDataKey.profile: config.profile,
            TealiumDataKey.environment: config.environment,
            TealiumDataKey.enabledModules: context.modulesManager.modules.value.map { $0.id }
        ])
    }

    public static let id: String = "tealiumcollector"

    let context: TealiumContext
    public required init(context: TealiumContext, moduleSettings: [String: Any]) {
        self.context = context
    }
}
