//
//  ExtensionsBaseTests.swift
//  tealium-prism
//
//  Created by Den Guzov on 10/04/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

@testable import TealiumPrism
import XCTest

class ExtensionsBaseTests: XCTestCase {
    func makeSettings(
        _ builder: TransformationSettingsBuilder
    ) throws -> TransformationSettings {
        if builder.scopes.isEmpty {
            _ = builder.addScope(.afterCollectors)
        }
        guard let settings = builder.build().getConvertible(converter: TransformationSettings.converter) else {
            throw NSError(domain: "Transformation Settings malformed", code: 1)
        }
        return settings
    }

    func configDataObject(from transformationSettings: DataObject) -> DataObject {
        transformationSettings
            .getDataDictionary(key: TransformationSettings.Keys.configuration)?.toDataObject() ?? [:]
    }
}
