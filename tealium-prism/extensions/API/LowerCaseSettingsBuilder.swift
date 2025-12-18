//
//  LowerCaseSettingsBuilder.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 17/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

#if extensions
    import TealiumPrismCore
#endif

public class LowerCaseSettingsBuilder: TransformationSettingsBuilder {
    var allVariables: Bool = true
    var operations: [TransformationOperation<LowerCaseInput>] = []

    public init(id: String) {
        super.init(id: id, transformerId: Modules.Types.lowerCaseTransformer)
    }

    /// Sets whether to lowercase all variables or only specific ones
    public func setAllVariables(_ all: Bool) -> Self {
        self.allVariables = all
        return self
    }

    /// Adds a variable to be lowercased in place
    public func addVariable(_ reference: ReferenceContainer) -> Self {
        operations.append(
            .init(
                destination: reference,
                parameters: .init(input: reference)
            )
        )
        return self
    }

    override public func build() -> TransformationSettings {
        _ = _setConfiguration(
            LowerCaseConfiguration(
                allVariables: allVariables,
                operations: operations
            )
            .toDataObject()
        )
        return super.build()
    }
}
