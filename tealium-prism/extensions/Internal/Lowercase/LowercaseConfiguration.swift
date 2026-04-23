//
//  LowercaseConfiguration.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 17/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

#if extensions
import TealiumPrismCore
#endif

struct LowercaseConfiguration: DataObjectConvertible {
    enum Keys {
        static let variables = "variables"
    }

    enum PolicyValue {
        static let allVariables = "allvariables"
    }

    let policy: LowercasePolicy

    init(policy: LowercasePolicy = .allVariables) {
        self.policy = policy
    }

    init?(dataObject: DataObject) {
        guard let policy = dataObject.getConvertible(key: Keys.variables, converter: LowercasePolicy.converter) else {
            return nil
        }
        self.init(policy: policy)
    }

    func toDataObject() -> DataObject {
        [Keys.variables: policy]
    }
}
