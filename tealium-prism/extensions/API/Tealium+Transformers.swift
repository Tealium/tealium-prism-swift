//
//  Tealium+Transformers.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation
#if extensions
import TealiumPrismCore
#endif

public extension Modules.Types {
    /// The module type identifier for the SetDataValues transformer.
    static let setDataValuesTransformer = "SetDataValues"
    /// The module type identifier for the PersistDataValue transformer.
    static let persistDataValueTransformer = "PersistDataValue"
    /// The module type identifier for the Lowercase transformer.
    static let lowercaseTransformer = "Lowercase"
}
