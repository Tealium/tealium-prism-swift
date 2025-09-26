//
//  TealiumDataModule.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

class TealiumDataModule: BasicModule, Collector {
    let version: String = TealiumConstants.libraryVersion
    static let canBeDisabled: Bool = false
    let context: TealiumContext
    private let baseData: DataObject
    let id: String = Modules.Types.tealiumData

    /// - Returns: `String` format of random 16 digit number
    private var random: String {
        (0..<16).reduce(into: "") { string, _ in string += String(Int.random(in: 0..<10)) }
    }

    required init(context: TealiumContext, moduleConfiguration: DataObject) {
        self.context = context
        let config = context.config
        baseData = DataObject(compacting: [
            TealiumDataKey.account: config.account,
            TealiumDataKey.profile: config.profile,
            TealiumDataKey.environment: config.environment,
            TealiumDataKey.dataSource: config.dataSource,
            TealiumDataKey.libraryName: TealiumConstants.libraryName,
            TealiumDataKey.libraryVersion: TealiumConstants.libraryVersion
        ])
    }

    func collect(_ dispatchContext: DispatchContext) -> DataObject {
        let modules = context.modulesManager.modules.value
        return [
            TealiumDataKey.enabledModules: modules.map { $0.id },
            TealiumDataKey.enabledModulesVersions: modules.map { $0.version },
            TealiumDataKey.visitorId: context.visitorId.value,
            TealiumDataKey.random: random
        ] + baseData
    }
}
