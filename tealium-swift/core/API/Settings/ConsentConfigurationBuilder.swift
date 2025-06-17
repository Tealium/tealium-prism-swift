//
//  ConsentConfigurationBuilder.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 26/05/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

/// A builder to create a `ConsentConfiguration` to be used with a specific `CMPAdapter`
public class ConsentConfigurationBuilder {
    typealias Keys = ConsentConfiguration.Keys
    private var _dataObject: DataObject = [:]

    init() { }

    var isEmpty: Bool {
        _dataObject.keys.isEmpty
    }

    /// Sets the purpose used to give consent to the entire SDK
    public func setTealiumPurposeId(_ tealiumPurposeId: String) -> Self {
        _dataObject.set(tealiumPurposeId, key: Keys.tealiumPurposeId)
        return self
    }

    /// Sets the list of purposes and the dispatchers that require them to be consented in order to track events.
    public func setPurposes(_ purposes: [ConsentPurpose]) -> Self {
        _dataObject.set(converting: purposes, key: Keys.purposes)
        return self
    }

    /// Sets the list of dispatcher IDs that are allowed to refire events after an explicit consent decision is made by the user.
    public func setRefireDispatchersIds(_ refireDispatchersIds: [String]) -> Self {
        _dataObject.set(converting: refireDispatchersIds, key: Keys.refireDispatchersIds)
        return self
    }

    func build() -> DataObject {
        _dataObject
    }
}
