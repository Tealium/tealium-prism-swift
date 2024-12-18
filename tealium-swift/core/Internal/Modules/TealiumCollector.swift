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

    static let id: String = "TealiumCollector"

    let context: TealiumContext
    required init(context: TealiumContext, moduleSettings: DataObject) {
        self.context = context
    }

    func collect(_ dispatchContext: DispatchContext) -> DataObject {
        let config = context.config
        return [
            TealiumDataKey.account: config.account,
            TealiumDataKey.profile: config.profile,
            TealiumDataKey.environment: config.environment,
            TealiumDataKey.enabledModules: context.modulesManager?.modules.value.map { $0.id } ?? [],
            TealiumDataKey.visitorId: context.visitorId.value
        ]
    }
}
