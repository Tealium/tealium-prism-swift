//
//  TransformerCoordinator.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 03/08/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A class that takes an observable state of registered `Transformer`s and an observable state of transformations
 * and can be used to transform the events after they have been enriched by the `Collector`s
 * or before being sent to each individual `Dispatcher`.
 *
 * The `transformations` are used to select the right transformer when we are transforming each event
 * and then are sent to the transformers.
 */
class TransformerCoordinator: TransformerRegistrar {
    private var transformers: ObservableState<[Transformer]>
    /// The `TransformationSettings` defined in the `SDKSettings`.
    private let transformations: ObservableState<[TransformationSettings]>
    /// The `TransformationSettings` added internally by other modules.
    private let additionalTransformations = StateSubject<[TransformationSettings]>([])
    /// Pre-sorted cache of all transformations, rebuilt whenever either source changes.
    private var sortedAllTransformations: [TransformationSettings] = []
    private let disposeBag = AutomaticDisposer()
    private let queue: TealiumQueue
    private let logger: LoggerProtocol?
    typealias TransformationCompletion = (Dispatch?) -> Void
    typealias DispatchesTransformationCompletion = ([Dispatch]) -> Void
    init(transformers: ObservableState<[Transformer]>,
         transformations: ObservableState<[TransformationSettings]>,
         queue: TealiumQueue,
         logger: LoggerProtocol?) {
        self.transformers = transformers
        self.transformations = transformations
        self.queue = queue
        self.logger = logger
        transformations.asObservable()
            .combineLatest(additionalTransformations.asObservable())
            .subscribe { [weak self] configuredTransformations, additionalTransformations in
                self?.sortedAllTransformations = (configuredTransformations + additionalTransformations)
                    .sorted { $0.order < $1.order }
            }.addTo(disposeBag)
    }

    func getTransformations(for scope: DispatchScope) -> [TransformationSettings] {
        sortedAllTransformations.filter { $0.matchesScope(scope) }
    }

    private func match(transformation: TransformationSettings, dispatch: Dispatch) -> Bool {
        do {
            return try transformation.matchesDispatch(dispatch)
        } catch {
            logger?.warn(category: LogCategory.transformations,
                         """
                         Transformation conditions evaluation failed for Dispatch(\(dispatch.logDescription())) \
                         and Transformation(\(transformation.compositeKey())). Cause: \(error)
                         """)
            return false
        }
    }

    /**
     * Transforms a single `Dispatch`, intended to be mainly used on a dispatch after it's been enriched by the collectors.
     */
    func transform(dispatch: Dispatch, for scope: DispatchScope, completion: @escaping TransformationCompletion) {
        recursiveSerialApply(transformations: getTransformations(for: scope),
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
        let transformation = transformations.removeFirst()
        guard match(transformation: transformation, dispatch: dispatch) else {
            recursiveSerialApply(transformations: transformations, to: dispatch, scope: scope, completion: completion)
            return
        }
        apply(singleTransformation: transformation, to: dispatch, scope: scope) { [weak self] newDispatch in
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

    func registerTransformation(_ transformation: TransformationSettings) {
        if !additionalTransformations.value.contains(where: { self.transformation($0, matchesIdsOf: transformation) }) {
            additionalTransformations.value.append(transformation)
        }
    }
    func unregisterTransformation(_ transformation: TransformationSettings) {
        additionalTransformations.value.removeAll { self.transformation($0, matchesIdsOf: transformation) }
    }

    func transformation(_ transformation: TransformationSettings, matchesIdsOf otherTransformation: TransformationSettings) -> Bool {
        transformation.id == otherTransformation.id && transformation.transformerId == otherTransformation.transformerId
    }
}
