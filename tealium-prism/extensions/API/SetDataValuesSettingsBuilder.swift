//
//  SetDataValuesSettingsBuilder.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

#if extensions
import TealiumPrismCore
#endif

public class SetDataValuesSettingsBuilder: TransformationSettingsBuilder {
    var operations: [TransformationOperation<SetDataValuesInput>] = []

    public init(id: String) {
        super.init(id: id, transformerId: Modules.Types.setDataValuesTransformer)
    }

    public func addOperation(input: ReferenceContainer, destination: ReferenceContainer) -> Self {
        operations.append(.init(destination: destination, parameters: .init(input: .reference(input))))
        return self
    }

    public func addOperation(input: ValueContainer, destination: ReferenceContainer) -> Self {
        operations.append(.init(destination: destination, parameters: .init(input: .constant(input))))
        return self
    }

    override public func build() -> TransformationSettings {
        _ = _setConfiguration(SetDataValuesConfiguration(operations: operations)
            .toDataObject())
        return super.build()
    }
}
