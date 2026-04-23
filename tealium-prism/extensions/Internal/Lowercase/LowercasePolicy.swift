//
//  LowercasePolicy.swift
//  tealium-prism
//
//  Created by Den Guzov on 17/04/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

#if extensions
import TealiumPrismCore
#endif

enum LowercasePolicy {
    case allVariables
    case variables([ReferenceContainer])
}

extension LowercasePolicy: DataInputConvertible {
    func toDataInput() -> DataInput {
        switch self {
        case .allVariables:
            return LowercaseConfiguration.PolicyValue.allVariables
        case .variables(let refs):
            return refs.map { $0.toDataObject() }.toDataInput()
        }
    }

    struct Converter: DataItemConverter {
        typealias Convertible = LowercasePolicy
        func convert(dataItem: DataItem) -> LowercasePolicy? {
            if let string = dataItem.get(as: String.self) {
                guard string.lowercased() == LowercaseConfiguration.PolicyValue.allVariables else { return nil }
                return .allVariables
            } else if let items = dataItem.getDataArray() {
                let variables = items.compactMap { $0.getConvertible(converter: ReferenceContainer.converter) }
                return .variables(variables)
            }
            return nil
        }
    }

    static let converter: any DataItemConverter<LowercasePolicy> = Converter()
}
