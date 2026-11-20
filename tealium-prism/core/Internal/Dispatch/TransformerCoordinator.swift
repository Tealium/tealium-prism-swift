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
    /**
     * The registered `Transformer`s, emitting only once the modules are ready.
     */
    private let onTransformers: Observable<[Transformer]>
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
    init(onTransformers: Observable<[Transformer]>,
         transformations: ObservableState<[TransformationSettings]>,
         queue: TealiumQueue,
         logger: LoggerProtocol?) {
        self.onTransformers = onTransformers
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
    @discardableResult
    func transform(dispatch: Dispatch, for scope: DispatchScope, completion: @escaping TransformationCompletion) -> any Disposable {
        // Asynchronously apply the transformations from the transformers when they are ready.
        return onTransformers.first()
            // `self` is captured strongly on purpose: a chain in flight must always reach `completion`, and the
            // coordinator only goes away at shutdown. A weak capture would drop the dispatch silently.
            .callback(fromDisposable: { [self] transformers, callbackCompletion -> any Disposable in
                // A single container per dispatch: disposing it cancels whichever step is in flight.
                let container = Disposables.composite()
                func applyNext(_ transformations: ArraySlice<TransformationSettings>, to dispatch: Dispatch?) {
                    guard !container.isDisposed else { return }
                    guard let transformation = transformations.first, let dispatch else {
                        callbackCompletion(dispatch)
                        return
                    }
                    let remaining = transformations.dropFirst()
                    guard match(transformation: transformation, dispatch: dispatch) else {
                        applyNext(remaining, to: dispatch)
                        return
                    }
                    apply(transformers: transformers, singleTransformation: transformation, to: dispatch, scope: scope) { newDispatch in
                        applyNext(remaining, to: newDispatch)
                    }.addTo(container)
                }
                applyNext(getTransformations(for: scope)[...], to: dispatch)
                return container
            })
            .subscribe(completion)
    }

    /**
     * Transforms an array of  `Dispatch`, intended to be used when one or more events are dequeued and are about to be sent to a single dispatcher.
     */
    @discardableResult
    func transform(dispatches: [Dispatch], for scope: DispatchScope, completion: @escaping DispatchesTransformationCompletion) -> any Disposable {
        TealiumDispatchGroup(queue: queue)
            .parallelExecution(dispatches.map { dispatch in
                { completion in
                    self.transform(dispatch: dispatch, for: scope, completion: completion)
                }
            }) { results in
                completion(results.compactMap { $0 })
            }
    }

    private func apply(transformers: [Transformer],
                       singleTransformation transformation: TransformationSettings,
                       to dispatch: Dispatch,
                       scope: DispatchScope,
                       completion: @escaping TransformationCompletion) -> any Disposable {
        guard let transformer = transformers.first(where: { $0.id == transformation.transformerId }) else {
            completion(dispatch)
            return Disposables.disposed()
        }
        let completion = SelfDestructingCompletion(completion: completion)
        let transformerId = transformer.id
        return transformer.applyTransformation(transformation, to: dispatch, scope: scope) { [queue, logger] dispatch in
            queue.ensureOnQueue {
                guard !completion.isCompleted else {
                    logger?.warn(category: LogCategory.transformations,
                                 "Transformer(\(transformerId)) completed Transformation(\(transformation.id)) more than once; ignoring.")
                    return
                }
                completion.complete(result: dispatch)
            }
        }
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
