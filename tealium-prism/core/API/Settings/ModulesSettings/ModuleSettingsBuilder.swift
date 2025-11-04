//
//  ModuleSettingsBuilder.swift
//  tealium-prism
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
    /// Creates a new module settings builder.
    public init() { }

    /// Set the enabled flag for these settings.
    public func setEnabled(_ enabled: Bool) -> Self {
        _dataObject.set(enabled, key: Keys.enabled)
        return self
    }

    /// Set the order in which the `Module` needs to be initialized.
    public func setOrder(_ order: Int) -> Self {
        _dataObject.set(order, key: Keys.order)
        return self
    }

    /// - Returns: the `DataObject` representing the `ModuleSettings` object.
    public func build() -> DataObject {
        _dataObject.set(converting: _configurationObject, key: Keys.configuration)
        return _dataObject
    }
}

/// A settings builder for a module that supports multiple instances.
public protocol MultipleInstancesModuleSettingsBuilder {
    /**
     * Set the `moduleId`. If you don't set it, `Module.moduleType` will be used later as a default.
     *
     * The module ID must be unique among all the modules provided in a single `Tealium` instance.
     * When configuring a module multiple times with different settings, make sure to set a unique ID to each one other than the first to avoid clashing.
     */
    func setModuleId(_ moduleId: String) -> Self
}

public extension MultipleInstancesModuleSettingsBuilder where Self: ModuleSettingsBuilder {
    func setModuleId(_ moduleId: String) -> Self {
        _dataObject.set(moduleId, key: Keys.moduleId)
        return self
    }
}

/// A settings builder that can be updated with a specific `Rule<String>`.
public protocol RuleModuleSettingsBuilder {
    /**
     * Set the rules that this module needs to match to collect or dispatch an event.
     *
     * The `String`s contained in the `Rule` correspond to a `LoadRule` ID
     * and will be used to lookup for those `LoadRule`s as defined in the `SDKSettings`
     * and then apply them according to the `Rule` specified as the method's parameter.
     *
     * - parameter rules: A `Rule` of `LoadRule` IDs, composed by AND, OR and NOT.
     */
    func setRules(_ rules: Rule<String>) -> Self
}

public extension RuleModuleSettingsBuilder where Self: ModuleSettingsBuilder {
    func setRules(_ rules: Rule<String>) -> Self {
        _dataObject.set(converting: rules, key: Keys.rules)
        return self
    }
}

/// A builder for Collector Settings which adds the possibility to set `Rule`s.
open class CollectorSettingsBuilder: ModuleSettingsBuilder, RuleModuleSettingsBuilder {

}

/// A builder for Dispatcher Settings which adds the possibility to set `Rule`s and `JSONOperation<MappingParameters>`.
open class DispatcherSettingsBuilder: ModuleSettingsBuilder, RuleModuleSettingsBuilder {

    /**
     * Set the mappings for this module.
     *
     * Mappings will only be used if the module is a `Dispatcher`.
     * When defined only mapped variables will be passed to the `Dispatcher`.
     *
     * Basic usage is very simple:
     * ```swift
     * DispatcherSettingsBuilder().setMappings([
     *  .from("input1", to: "destination1"),
     *  .constant("value", to: "destination2"),
     *  .keep("input2)
     * ])
     * ```
     *
     * For more complex use cases you can leverage the `Mappings` methods and the `JSONObjectPath` constructor:
     * ```swift
     * DispatcherSettingsBuilder().setMappings([
     *  .from(JSONPath["container"]["input1"],
     *        to: JSONPath["resultContainer"]["destination"])
     *      .ifValueEquals("value"),
     *  .constant("value": to: JSONPath["resultContainer"]["destination"])
     *      .ifValueIn(JSONPath["container"]["input2"]), equals: "targetValue"),
     *  .keep(JSONPath["container"]["inputToMapAsIs"]
     * ])
     * ```
     * - parameter mappings: A list of `Mapping`s to be applied to each `Dispatch` before sending it to the `Dispatcher`.
     */
    public func setMappings(_ mappings: [Mappings]) -> Self {
        _dataObject.set(converting: mappings.map { $0.build() }, key: Keys.mappings)
        return self
    }
}
