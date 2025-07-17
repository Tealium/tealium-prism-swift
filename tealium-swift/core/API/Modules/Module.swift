//
//  Module.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// A module used by the Tealium SDK to provide some plugin functionality.
public protocol Module: AnyObject {
    /// The version of this module
    var version: String { get }
    /// The unique id for this module, used to uniquely identify each module.
    static var id: String { get }
    /// Returns true if the module is optional and can be disabled, or false otherwise. Default is true.
    static var canBeDisabled: Bool { get }
    /// Updates the configuration and, if the configuration is valid, return the same class otherwise return nil and the module is considered disabled.
    func updateConfiguration(_ configuration: DataObject) -> Self?
    /// Called when a previously created module needs to shut down, to allow it to perform some final cleanup before removing it form the available modules.
    func shutdown()
}

/// A restricted `Module` that can be created with some default parameters.
public protocol BasicModule: Module {
    /**
     *  Initializes the module with a `TealiumContext` and this module's specific configuration.
     *
     * - Parameters:
     *      - context: The `TealiumContext` shared among all the modules
     *      - moduleConfiguration: The `DataObject` containing the configuration for this specific module. It should be empty if the module uses no configuration.
     */
    init?(context: TealiumContext, moduleConfiguration: DataObject)
}

public extension Module {
    var id: String {
        type(of: self).id
    }
    static var canBeDisabled: Bool { true }
    func updateConfiguration(_ configuration: DataObject) -> Self? {
        return self
    }
    func shutdown() { }
}

/// A `Module` that implements the functionality of collecting data to enrich the data layer of each track request.
public protocol Collector: Module {
    /// Returns data used to enrich the data layer of a track request.
    func collect(_ dispatchContext: DispatchContext) -> DataObject
}

/// A `Module` that implements the functionality of dispatching some track requests towards some entity that can handle the events.
public protocol Dispatcher: Module {
    /// The maximum amount of `Dispatch`es that are accepted in a single dispatch call. Default is 1.
    var dispatchLimit: Int { get }
    /**
     * Sends the provided `Dispatch`es to some specific entity to handle them.
     *
     * - Parameters:
     *    - data: The `Dispatch`es that have to be sent. They will always be less then or equal to the `dispatchLimit`.
     *    - completion: The callback that needs to be called when one or more `Dispatch`es have completed. Completed in this case means both if it succeeded, or if it failed and won't be retried. This callback can be called multiple times, but must contain each `Dispatch` exactly once. All `TealiumDisaptches` provided in the data parameter need to be passed back in the completion block at some point to allow for it to be cleared from the queue and avoid multiple dispatches of the same events.
     *
     * - Returns: A `Disposable` that can be used to cancel the dispatch process if still in progress.
     */
    func dispatch(_ data: [Dispatch], completion: @escaping ([Dispatch]) -> Void) -> Disposable
}

public extension Dispatcher {
    var dispatchLimit: Int { 1 }
}
