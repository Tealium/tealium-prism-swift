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
        let settings = context.coreSettings
        return TealiumDictionaryInput(removingOptionals: [
            TealiumDataKey.account: settings.account,
            TealiumDataKey.profile: settings.profile,
            TealiumDataKey.environment: settings.environment,
            TealiumDataKey.enabledModules: context.tealiumProtocol?.modules.map { type(of: $0).id }
        ])
    }

    public static let id: String = "tealiumcollector"

    let context: TealiumContext
    public required init(context: TealiumContext, moduleSettings: [String: Any]) {
        self.context = context
    }
}
