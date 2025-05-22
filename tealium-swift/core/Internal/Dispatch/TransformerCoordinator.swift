//
//  TransformerCoordinator.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 03/08/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// An object that will apply different transformations, selected by `transformationId`, to a dispatch.
public protocol Transformer: TealiumModule {
    /// Applies a transformation, identified by a `transformationId`, to a `Dispatch` for the `DispatchScope` in which this transformation is called.
    func applyTransformation(_ transformation: TransformationSettings,
                             to dispatch: Dispatch,
                             scope: DispatchScope,
                             completion: @escaping (Dispatch?) -> Void)
}

public protocol TransformerRegistry {
    func registerTransformation(_ transformation: TransformationSettings)
    func unregisterTransformation(_ transformation: TransformationSettings)
}

/**
 * A class that takes a observable state of registered transformers and an observable state of transformations 
 * and can be used to transform the events after they have been enriched by the collectors 
 * or before being sent to each individual dispatcher.
 *
 * The `transformations` are used to select the right transformer when we are transforming each event
 * and then are sent to the transformers.
 */
public class TransformerCoordinator: TransformerRegistry {
    private var transformers: ObservableState<[Transformer]>
    /// The `TransformationSettings` defined in the `SDKSettings`.
    private let transformations: ObservableState<[TransformationSettings]>
    /// The `TransformationSettings` added internally by other modules.
    private let additionalTransformations = StateSubject<[TransformationSettings]>([])
    private var allTransformations: [TransformationSettings] {
        transformations.value + additionalTransformations.value
    }
    private let queue: TealiumQueue
    typealias TransformationCompletion = (Dispatch?) -> Void
    typealias DispatchesTransformationCompletion = ([Dispatch]) -> Void
    init(transformers: ObservableState<[Transformer]>,
         transformations: ObservableState<[TransformationSettings]>,
         moduleMappings: ObservableState<[String: TransformationSettings]>,
         queue: TealiumQueue) {
        self.transformers = transformers
        self.transformations = transformations
        self.queue = queue
    }

    func getTransformations(for dispatch: Dispatch, _ scope: DispatchScope) -> [TransformationSettings] {
        allTransformations.filter {
            $0.matchesScope(scope) && $0.matchesDispatch(dispatch)
        }
    }

    /**
     * Transforms a single `Dispatch`, intended to be mainly used on a dispatch after it's been enriched by the collectors.
     */
    func transform(dispatch: Dispatch, for scope: DispatchScope, completion: @escaping TransformationCompletion) {
        recursiveSerialApply(transformations: getTransformations(for: dispatch, scope),
                             to: dispatch,
                             scope: scope,
                             completion: completion)
    }

    /**
     * Transforms an array of  `Dispatch`, intended to be used when one or more events are dequeued and are about to be sent to a single dispatcher.
     */
    func transform(dispatches: [Dispatch], for scope: DispatchScope, completion: @escaping DispatchesTransformationCompletion) {
        TealiumDispatchGroup(queue: queue)
            .parallelExecution(dispatches.map { dispatch in
                return { completion in
                    self.transform(dispatch: dispatch, for: scope) { dispatch in
                        completion(dispatch)
                    }
                }
            }) { results in
                completion(results.compactMap { $0 })
            }
    }

    private func recursiveSerialApply(transformations: [TransformationSettings], to dispatch: Dispatch?, scope: DispatchScope, completion: @escaping TransformationCompletion) {
        guard !transformations.isEmpty, let dispatch = dispatch else {
            completion(dispatch)
            return
        }
        var transformations = transformations
        apply(singleTransformation: transformations.removeFirst(), to: dispatch, scope: scope) { [weak self] newDispatch in
            self?.recursiveSerialApply(transformations: transformations, to: newDispatch, scope: scope, completion: completion)
        }
    }

    private func apply(singleTransformation transformation: TransformationSettings, to dispatch: Dispatch, scope: DispatchScope, completion: @escaping TransformationCompletion) {
        guard let transformer = transformers.value.first(where: { $0.id == transformation.transformerId }) else {
            completion(dispatch)
            return
        }
        return transformer.applyTransformation(transformation, to: dispatch, scope: scope, completion: completion)
    }

    public func registerTransformation(_ transformation: TransformationSettings) {
        if !additionalTransformations.value.contains(where: { self.transformation($0, matchesIdsOf: transformation) }) {
            additionalTransformations.value.append(transformation)
        }
    }
    public func unregisterTransformation(_ transformation: TransformationSettings) {
        additionalTransformations.value.removeAll { self.transformation($0, matchesIdsOf: transformation) }
    }

    func transformation(_ transformation: TransformationSettings, matchesIdsOf otherTransformation: TransformationSettings) -> Bool {
        transformation.id == otherTransformation.id && transformation.transformerId == otherTransformation.transformerId
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
    let version: String = TealiumConstants.libraryVersion
    static let id: String = "JavascriptTransformer"
    let transformations = [String: String]() // ID : javascript code
    init() {
        // download a list of all possible transformations, they will later be searched by ID
        // Transformer initialization might be async, but for the first event we will wait, and later will transform synchronously.
    }

    func applyTransformation(_ transformation: TransformationSettings, to dispatch: Dispatch, scope: DispatchScope, completion: (Dispatch?) -> Void) {
        // run transformations[transformationId] with the dispatch
    }
}
