//
//  TransformerCoordinator.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 03/08/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// An object that will apply different transformations, selected by `transformationId`, to a dispatch.
public protocol Transformer {
    /// The Transformer ID used to match it with the `ScopedTransformation` in the settings
    var id: String { get }
    /// Applies a transformation, identified by a `transformationId`, to a `TealiumDispatch` for the `DispatchScope` in which this transformation is called.
    func applyTransformation(_ transformationId: String,
                             to dispatch: TealiumDispatch,
                             scope: DispatchScope,
                             completion: @escaping (TealiumDispatch?) -> Void)
}

/**
 * A class that takes a constant list of registered transformers and an observable state of scopedTransformers and can be used to transform the events after they have been enriched by the collectors or before being sent to each individual dispatcher.
 *
 * The `scopedTransformations` are used to select the right transformer when we are transforming each event.
 */
class TransformerCoordinator {
    let registeredTransformers: [Transformer]
    let scopedTransformations: TealiumObservableState<[ScopedTransformation]>
    let queue: DispatchQueue
    typealias TransformationCompletion = (TealiumDispatch?) -> Void
    typealias DispatchesTransformationCompletion = ([TealiumDispatch]) -> Void
    init(registeredTransformers: [Transformer], scopedTransformations: TealiumObservableState<[ScopedTransformation]>, queue: DispatchQueue = tealiumQueue) {
        self.registeredTransformers = registeredTransformers
        self.scopedTransformations = scopedTransformations
        self.queue = queue
    }

    func getTransformations(for scope: DispatchScope) -> [ScopedTransformation] {
        scopedTransformations.value.filter { $0.matchesScope(scope) }
    }

    /**
     * Transforms a single `TealiumDispatch`, intended to be used on a dispatch after it's been enriched by the collectors.
     */
    func transformAfterCollectors(dispatch: TealiumDispatch, completion: @escaping TransformationCompletion) {
        transform(dispatch: dispatch, for: .afterCollectors, completion: completion)
    }

    private func transform(dispatch: TealiumDispatch, for scope: DispatchScope, completion: @escaping TransformationCompletion) {
        recursiveSerialApply(transformations: getTransformations(for: scope),
                             to: dispatch,
                             scope: scope,
                             completion: completion)
    }

    /**
     * Transforms an array of  `TealiumDispatch`, intended to be used when one or more events are dequeued and are about to be sent to a single dispatcher.
     */
    func transform(dispatches: [TealiumDispatch], for scope: DispatchScope, completion: @escaping DispatchesTransformationCompletion) {
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

    private func recursiveSerialApply(transformations: [ScopedTransformation], to dispatch: TealiumDispatch?, scope: DispatchScope, completion: @escaping TransformationCompletion) {
        guard !transformations.isEmpty, let dispatch = dispatch else {
            completion(dispatch)
            return
        }
        var transformations = transformations
        apply(singleTransformation: transformations.removeFirst(), to: dispatch, scope: scope) { [weak self] newDispatch in
            self?.recursiveSerialApply(transformations: transformations, to: newDispatch, scope: scope, completion: completion)
        }
    }

    private func apply(singleTransformation transformation: ScopedTransformation, to dispatch: TealiumDispatch, scope: DispatchScope, completion: @escaping TransformationCompletion) {
        guard let transformer = registeredTransformers.first(where: { $0.id == transformation.transformerId }) else {
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
