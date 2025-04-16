//
//  ModuleSettingsBuilder.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

/// A base class that adds the enabled setter for SettingsBuilders that are Optional and therefore can be disabled.
open class ModuleSettingsBuilder {
    typealias Keys = ModuleSettings.Keys
    fileprivate var _dataObject = DataObject()

    /// A custom dictionary that holds the configuration for this module.
    /// Do not use this one directly unless you are subclassing this class.
    public var _configurationObject = DataObject()
    public init() { }

    /// Set the enabled flag for these settings.
    public func setEnabled(_ enabled: Bool) -> Self {
        _dataObject.set(enabled, key: Keys.enabled)
        return self
    }

    /// Returns the `DataObject` representing the `ModuleSettings` object.
    public func build() -> DataObject {
        _dataObject.set(converting: _configurationObject, key: ModuleSettings.Keys.configuration)
        return _dataObject
    }
}

/// A builder for Collector Settings which adds the possibility to set `Rule`s.
open class CollectorSettingsBuilder: ModuleSettingsBuilder {
    /**
     * Set the rules that this module needs to match to collect or dispatch an event.
     *
     * The `String`s contained in the `Rule` correspond to a `LoadRule` ID
     * and will be used to lookup for those `LoadRule`s as defined in the `SDKSettings`
     * and then apply them according to the `Rule` specified as the method's parameter.
     *
     * - parameter rules: A `Rule` of `LoadRule` IDs, composed by AND, OR and NOT.
     */
    public func setRules(_ rules: Rule<String>) -> Self {
        _dataObject.set(rules.toDataInput(), key: Keys.rules)
        return self
    }
}

/// A builder for Dispatcher Settings which adds the possibility to set `Rule`s and `JSONOperation<MappingParameters>`.
open class DispatcherSettingsBuilder: ModuleSettingsBuilder {
    /**
     * Set the rules that this module needs to match to collect or dispatch an event.
     *
     * The `String`s contained in the `Rule` correspond to a `LoadRule` ID
     * and will be used to lookup for those `LoadRule`s as defined in the `SDKSettings`
     * and then apply them according to the `Rule` specified as the method's parameter.
     *
     * - parameter rules: A `Rule` of `LoadRule` IDs, composed by AND, OR and NOT.
     */
    public func setRules(_ rules: Rule<String>) -> Self {
        _dataObject.set(rules.toDataInput(), key: Keys.rules)
        return self
    }

    /**
     * Set the mappings for this module.
     *
     * Mappings will only be used if the module is a `Dispatcher`.
     * When defined only mapped variables will be passed to the `Dispatcher`.
     *
     * - parameter mappings: A list of `Mapping`s to be applied to each `TealiumDispatch` before sending it to the `Dispatcher`.
     */
    public func setMappings(_ mappings: [TransformationOperation<MappingParameters>]) -> Self {
        _dataObject.set(mappings.toDataInput(), key: Keys.mappings)
        return self
    }
}
