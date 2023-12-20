//
//  CoreConfig.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 06/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

public struct CoreSettings {
    enum Keys {
        static let minLogLevel = "minLogLevel"
        static let barriers = "barriers"
        static let transformations = "transformations"
    }
    enum Defaults {
        static let minLogLevel = TealiumLogLevel.Minimum.debug // TODO: Change into .error later
    }
    public init(coreDictionary: [String: Any]) {
        if let logLevelString = coreDictionary[Keys.minLogLevel] as? String,
           let level = TealiumLogLevel.Minimum(from: logLevelString) {
                          minLogLevel = level
        } else {
            minLogLevel = Defaults.minLogLevel
        }
        if let barriers = coreDictionary[Keys.barriers] as? [[String: Any]] {
            scopedBarriers = barriers.compactMap { ScopedBarrier(from: $0) }
        } else {
            scopedBarriers = []
        }
        if let transformations = coreDictionary[Keys.transformations] as? [[String: Any]] {
            scopedTransformations = transformations.compactMap { ScopedTransformation(from: $0) }
        } else {
            scopedTransformations = []
        }
    }
    let minLogLevel: TealiumLogLevel.Minimum
    let scopedBarriers: [ScopedBarrier]
    let scopedTransformations: [ScopedTransformation]
}
