//
//  ConsentSettingsBuilder.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 10/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/// A builder used to enforce some of the `ConsentSettings`.
class ConsentSettingsBuilder {
    typealias Keys = ConsentSettings.Keys
    let vendorId: String
    private var _dataObject: DataObject = [:]

    /**
     * Create a ConsentSettingsBuilder with a fixed `vendorId`.
     *
     * Only one `CMPAdapter` is supported at the time of this writing, so there's no reason to provide multiple vendor IDs.
     */
    init(vendorId: String) {
        self.vendorId = vendorId
    }

    /**
     * Sets some of the `ConsentConfiguration` keys via the provided builder.
     *
     * This will be saved in the object at the `vendorId` key.
     *
     * If configuration is empty then we will only remove any potential previous values without adding an empty object.
     *
     * - Parameters:
     *      - configuration: The builder used to create the `ConsentConfiguration` object
     */
    func setConfiguration(_ configuration: ConsentConfigurationBuilder) -> Self {
        _dataObject.removeValue(forKey: Keys.configurations)
        guard !configuration.isEmpty else {
            return self
        }
        _dataObject.buildPath(JSONPath[Keys.configurations][vendorId],
                              andSet: configuration.build().toDataItem())
        return self
    }

    func build() -> DataObject {
        _dataObject
    }
}
