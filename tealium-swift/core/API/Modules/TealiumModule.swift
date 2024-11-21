//
//  TealiumModule.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// A module used by the Tealium SDK to provide some plugin functionality.
public protocol TealiumModule: AnyObject {
    /// The unique id for this module, used to uniquely identify each module.
    static var id: String { get }
    /// Returns true if the module is optional and can be disabled, or false otherwise. Default is true.
    static var canBeDisabled: Bool { get }
    /// Updates the settings and, if the settings are valid, return the same class otherwise return nil and the module is considered disabled.
    func updateSettings(_ settings: DataObject) -> Self?
    /// Called when a previously created module needs to shut down, to allow it to perform some final cleanup before removing it form the available modules.
    func shutdown()
}

/// A restricted `TealiumModule` that can be created with some default parameters.
public protocol TealiumBasicModule: TealiumModule {
    /**
     *  Initializes the module with a `TealiumContext` and this module's specific settings.
     *
     * - Parameters:
     *      - context: The `TealiumContext` shared among all the modules
     *      - moduleSettings: The `DataObject` containing the settings for this specific module. It should be empty if the module uses no settings.
     */
    init?(context: TealiumContext, moduleSettings: DataObject)
}

public extension TealiumModule {
    var id: String {
        type(of: self).id
    }
    static var canBeDisabled: Bool { true }
    func updateSettings(_ settings: DataObject) -> Self? {
        return self
    }
    func shutdown() { }
}

/// A `TealiumModule` that implements the functionality of collecting data to enrich the data layer of each track request.
public protocol Collector: TealiumModule {
    /// The data used to enrich the data layer of a track request.
    var data: DataObject { get }
}

/// A `TealiumModule` that implements the functionality of dispatching some track requests towards some entity that can handle the events.
public protocol Dispatcher: TealiumModule {
    /// The maximum amount of `TealiumDispatch`es that are accepted in a single dispatch call. Default is 1.
    var dispatchLimit: Int { get }
    /**
     * Sends the provided `TealiumDispatch`es to some specific entity to handle them.
     *
     * - Parameters:
     *    - data: The `TealiumDispatch`es that have to be sent. They will always be less then or equal to the `dispatchLimit`.
     *    - completion: The callback that needs to be called when one or more `TealiumDispatch`es have completed. Completed in this case means both if it succeded, or if it failed and won't be retried. This callback can be called multiple times, but must contain each `TealiumDispatch` exactly once. All `TealiumDisaptches` provided in the data parameter need to be passed back in the completion block at some point to allow for it to be cleared from the queue and avoid multiple dispatches of the same events.
     *
     * - Returns: A `Disposable` that can be used to cancel the dispatch process if still in progress.
     */
    func dispatch(_ data: [TealiumDispatch], completion: @escaping ([TealiumDispatch]) -> Void) -> Disposable
}

public extension Dispatcher {
    var dispatchLimit: Int { 1 }
}
