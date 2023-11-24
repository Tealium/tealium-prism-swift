//
//  DispatchUtilities.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 03/08/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol Transformer {
    var id: String { get }
    func applyTransformation(_ transformationId: String, to dispatch: TealiumDispatch, scope: DispatchScope, completion: @escaping (TealiumDispatch?) -> Void)
}

public enum TransformationScope: RawRepresentable, Codable {
    public typealias RawValue = String

    case afterCollectors
    case onAllDispatchers
    case onDispatcher(String)

    public var rawValue: String {
        switch self {
        case .afterCollectors:
            return "aftercollectors"
        case .onAllDispatchers:
            return "onalldispatchers"
        case .onDispatcher(let dispatcher):
            return dispatcher
        }
    }

    public init?(rawValue: String) {
        let lowercasedScope = rawValue.lowercased()
        switch lowercasedScope {
        case "aftercollectors":
            self = .afterCollectors
        case "onalldispatchers":
            self = .onAllDispatchers
        default:
            self = .onDispatcher(lowercasedScope)
        }
    }
}

public enum DispatchScope: RawRepresentable, Codable {
    public typealias RawValue = String

    case afterCollectors
    case onDispatcher(String)

    public var rawValue: String {
        switch self {
        case .afterCollectors:
            return "aftercollectors"
        case .onDispatcher(let dispatcher):
            return dispatcher
        }
    }

    public init?(rawValue: String) {
        let lowercasedScope = rawValue.lowercased()
        switch lowercasedScope {
        case "aftercollectors":
            self = .afterCollectors
        default:
            self = .onDispatcher(lowercasedScope)
        }
    }
}

public struct ScopedTransformation: Codable {
    let id: String
    let transformerId: String
    let scope: [TransformationScope]

    func matchesScope(_ dispatchScope: DispatchScope) -> Bool {
        self.scope.contains { transformationScope in
            switch (transformationScope, dispatchScope) {
            case (.afterCollectors, .afterCollectors):
                return true
            case (.onAllDispatchers, .onDispatcher):
                return true
            case let (.onDispatcher(requiredDispatcher), .onDispatcher(selectedDispatcher)):
                return requiredDispatcher == selectedDispatcher
            default:
                return false
            }
        }
    }
}

class TransformerCoordinator {
    var registeredTransformers = [Transformer]() // Provided by the config
    var scopedTransformations = [ScopedTransformation]() // Provided and updated by the Core settings

    func getTransformations(for scope: DispatchScope) -> [ScopedTransformation] {
        scopedTransformations.filter { $0.matchesScope(scope) }
    }

    func transformAfterCollectors(dispatch: TealiumDispatch, completion: @escaping (TealiumDispatch?) -> Void) {
        apply(transformations: getTransformations(for: .afterCollectors),
              to: dispatch,
              scope: .afterCollectors,
              completion: completion)
    }

    func transform(dispatch: TealiumDispatch, for dispatcher: Dispatcher, completion: @escaping (TealiumDispatch?) -> Void) {
        let scope = DispatchScope.onDispatcher(dispatcher.id)
        apply(transformations: getTransformations(for: scope), // This will return onDispatcher + onDispatch scoped transformations!
              to: dispatch,
              scope: scope,
              completion: completion)
    }

    func transform(dispatches: [TealiumDispatch], for dispatcher: Dispatcher, completion: @escaping ([TealiumDispatch]) -> Void) {
        let group = DispatchGroup()
        // make sure all enter() are called before the first leave() is completed, otherwise if the count goes back to 0 notify will be called immediately, before completing all the barrier checks.
        // Maybe create a TealiumDispatchGroup that calls one extra enter on creation and one extra leave when notify is called. So we don't have to remember calling all enters before the first leave.
        for _ in dispatches {
            group.enter()
        }
        var dispatchesResult = [TealiumDispatch]()
        for dispatch in dispatches {
            transform(dispatch: dispatch, for: dispatcher) { dispatchResult in
                guard let dispatchResult = dispatchResult else {
                    return
                }
                dispatchesResult.append(dispatchResult)
            }
        }
        group.notify(queue: tealiumQueue) {
            completion(dispatchesResult)
        }
    }

    private func apply(transformations: [ScopedTransformation], to dispatch: TealiumDispatch?, scope: DispatchScope, completion: @escaping (TealiumDispatch?) -> Void) {
        var transformations = transformations
        guard !transformations.isEmpty && dispatch != nil else {
            completion(dispatch)
            return
        }
        apply(transformation: transformations.removeFirst(), to: dispatch, scope: scope) { [weak self] newDispatch in
            self?.apply(transformations: transformations, to: newDispatch, scope: scope, completion: completion)
        }
    }

    private func apply(transformation: ScopedTransformation, to dispatch: TealiumDispatch?, scope: DispatchScope, completion: @escaping (TealiumDispatch?) -> Void) {
        guard let dispatch = dispatch,
            let transformer = registeredTransformers.first(where: { $0.id == transformation.transformerId }) else {
            completion(dispatch)
            return
        }
        return transformer.applyTransformation(transformation.id, to: dispatch, scope: scope, completion: completion)
    }
}

/**
 * Just an example of what a Transformer is. The javascript transformer should be generic enough as it allows for everything we could ever want to do with a transformer.
 *
 * Other transformers might be a generic class that does some speicifc transformations:
 * - like a DispatchValidator that has a blacklist of events to stop
 * - or a specific mapper transformers that takes the data tracked in the "tealium" way and sends it to a specific dispatcher with some specific changes (like the current RemoteCommands)
 * - some JSON backed API that triggers some operations like concatenations/additions/other for people that don't want to use the javascript engine but prefer some "safer" approach.
 */
class JavascriptTransformer: Transformer {
    var id: String = "javascript_transformer"
    let transformations = [String: String]() // ID : javascript code
    init() {
        // download a list of all possible transformations, they will later be searched by ID
        // Transformer initialization might be async, but for the first event we will wait, and later will transform synchronously.
    }

    func applyTransformation(_ transformationId: String, to dispatch: TealiumDispatch, scope: DispatchScope, completion: (TealiumDispatch?) -> Void) {
        // run transformations[transformationId] with the dispatch
    }
}
