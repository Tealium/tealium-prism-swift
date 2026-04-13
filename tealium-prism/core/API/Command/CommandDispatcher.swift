//
//  CommandDispatcher.swift
//  tealium-prism
//
//  Created by Sebastian Krajna on 23/03/2026.
//  Copyright © 2026 Tealium. All rights reserved.
//

import Foundation

/// Base class for command-based dispatchers that route dispatches through a `CommandRegistry`.
///
/// Provides a concrete implementation for `dispatch()` that supports async commands
/// with cancellation via `Disposable`, calling completion once per `Dispatch` as it finishes.
///
/// ## Usage
///
/// ```swift
/// class MyVendorDispatcher: CommandDispatcher {
///     private let vendorInstance: VendorInterface
///
///     init(context: TealiumContext, vendorInstance: VendorInterface) {
///         self.vendorInstance = vendorInstance
///         super.init(
///             id: "MyVendor",
///             version: "1.0.0",
///             commands: [...],
///             logCategory: "MyVendor",
///             queue: context.queue,
///             logger: context.logger
///         )
///     }
/// }
/// ```
open class CommandDispatcher: Dispatcher {

    // MARK: - Module Properties

    public let id: String
    public let version: String
    open var dispatchLimit: Int { 10 }

    // MARK: - Command Infrastructure

    private let commandRegistry: CommandRegistry
    private let queue: TealiumQueue
    public let logger: LoggerProtocol?
    public let logCategory: String

    // MARK: - Initialization

    /// Designated initializer for subclasses.
    public init(id: String,
                version: String,
                commands: [CommandProtocol],
                logCategory: String,
                queue: TealiumQueue,
                logger: LoggerProtocol?) {
        self.id = id
        self.version = version
        self.commandRegistry = CommandRegistry(commands: commands)
        self.queue = queue
        self.logCategory = logCategory
        self.logger = logger
    }

    // MARK: - Dispatcher

    open func dispatch(_ data: [Dispatch], completion: @escaping ([Dispatch]) -> Void) -> Disposable {
        let container = DisposableContainer()

        for dispatch in data {
            processDispatch(dispatch) {
                completion([dispatch])
            }.addTo(container)
        }

        return container
    }

    // MARK: - Private

    private func processDispatch(_ dispatch: Dispatch, completion: @escaping () -> Void) -> Disposable {
        let commands = dispatch.getCommands()
        guard !commands.isEmpty else {
            logger?.debug(category: logCategory,
                          "No command in dispatch \(dispatch.logDescription())")
            completion()
            return Disposables.disposed()
        }
        logger?.debug(category: logCategory, "Processing dispatch \(dispatch.logDescription()) with commands: \(commands)")
        return TealiumDispatchGroup(queue: queue)
            .parallelExecution(commands.map { [commandRegistry] name in
                { singleCommandCompletion in
                    commandRegistry.execute(commandName: name, payload: dispatch.payload, completion: singleCommandCompletion)
                }
            }) { [weak self] results in
                guard let self else { return }
                for (index, error) in results.enumerated() {
                    if let error {
                        self.logger?.warn(category: self.logCategory,
                                          "Command '\(commands[index])' failed: \(error.message)")
                    } else {
                        self.logger?.debug(category: self.logCategory,
                                           "Command '\(commands[index])' executed successfully")
                    }
                }
                completion()
            }
    }
}
