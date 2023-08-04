//
//  TealiumCollector.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

public class TealiumCollector: Collector {
    public var data: TealiumDictionary {
        let settings = context.coreSettings
        return TealiumDictionary(removingOptionals: [
            "account": settings.account,
            "profile": settings.profile,
            "environment": settings.environment,
            "modules": context.tealiumProtocol?.modules.map { type(of: $0).id },
            "enabled_modules": context.tealiumProtocol?.modules.map { type(of: $0).id }
        ])
    }

    public static var id: String = "tealiumcollector"

    let context: TealiumContext
    public required init(context: TealiumContext, moduleSettings: [String: Any]) {
        self.context = context
    }
}
