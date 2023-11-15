//
//  DispatchManager.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/10/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

class DispatchManager {
    static let MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER = 50
    let barrierCoordinator: BarrierCoordinator
    let transformerCoordinator: TransformerCoordinator
    let dispatchers: [Dispatcher] = []
    let queueManager: QueueManager
    let consentManager: ConsentManager
    @ToAnyObservable<TealiumPublisher<Void>>(TealiumPublisher<Void>())
    var onQueuedEvents: TealiumObservable<Void>

    init(consentManager: ConsentManager, queueManager: QueueManager, barrierCoordinator: BarrierCoordinator, transformerCoordinator: TransformerCoordinator) {
        self.consentManager = consentManager
        self.queueManager = queueManager
        self.barrierCoordinator = barrierCoordinator
        self.transformerCoordinator = transformerCoordinator
        registerConsentTransformation()
        startDispatchLoop()
    }

    // TODO: this can in future be done when creating the dispatch manager and the coordinators, no need to do it in here
    func registerConsentTransformation() {
        transformerCoordinator.registeredTransformers.append(consentManager.consentTransformer)
        transformerCoordinator.scopedTransformations
            .append(ScopedTransformation(id: "verify_consent",
                                         transformerId: consentManager.consentTransformer.id,
                                         scope: [TransformationScope.onAllDispatchers]))
    }

    func tealiumPurposeExplicitlyBlocked() -> Bool {
        guard consentManager.enabled else {
            return false
        }
        guard let decision = consentManager.getConsentDecision(),
              decision.decisionType == .explicit else {
            return false
        }
        return !consentManager.tealiumConsented(forPurposes: decision.purposes)
    }

    func track(_ dispatch: TealiumDispatch) {
        guard !tealiumPurposeExplicitlyBlocked() else {
            return
        }
        transformerCoordinator.transformAfterCollectors(dispatch: dispatch) { [weak self] dispatch in
            guard let self = self,
                let dispatch = dispatch else {
                return
            }
            if self.consentManager.enabled {
                self.consentManager.applyConsent(to: dispatch)
            } else {
                self.queueManager.storeDispatch(dispatch, for: dispatchers.map { $0.id })
            }
        }
    }

    private var managerContainer = TealiumAutomaticDisposer()

    private func stopDispatchLoop() {
        managerContainer = TealiumAutomaticDisposer()
    }

    private func startDispatchLoop() {
        for dispatcher in dispatchers {
            barrierCoordinator.onBarriersState(forScope: .all)
                .combineLatest(barrierCoordinator.onBarriersState(forScope: .perDispatcher(dispatcher.id)))
                .map { genericState, dispatcherState in genericState == .open && dispatcherState == .open }
                .distinct()
                .flatMapLatest { [weak self] dispatchLoopActive in
                    if dispatchLoopActive, let newLoop = self?.startTransformAndDispatchLoop(for: dispatcher) {
                        return newLoop
                    } else {
                        return .Empty()
                    }
                }.subscribe { dispatches in
                    print("Dispatched and deleted from Queue/inflight: \(dispatches)")
                }.addTo(managerContainer)
        }
    }

    private func startTransformAndDispatchLoop(for dispatcher: Dispatcher) -> TealiumObservable<[TealiumDispatch]> {
        self.queueManager.onEnqueuedEvents.startWith(())
            .combineLatest(self.queueManager.onInflightEventsCount(for: dispatcher))
            .filter { $1 < Self.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER }
            .observeOn(tealiumQueue) // added to delay subsequent events after getQueuedEvents changes the inflightEventsCount and therefore preserve the order of dispatches
            .compactMap { [weak self] _ in self?.queueManager.getQueuedEvents(for: dispatcher, limit: dispatcher.dispatchLimit) }
            .filter { $0.count > 0 }
            .flatMap { dispatches in
                TealiumObservable.Callback { [weak self] observer in
                    self?.transformAndDispatch(dispatches: dispatches, for: dispatcher) { completedDispatches in
                        observer(completedDispatches)
                    }
                }
            }
    }

    private func transformAndDispatch(dispatches: [TealiumDispatch], for dispatcher: Dispatcher, completion: @escaping ([TealiumDispatch]) -> Void) {
        self.transformerCoordinator.transform(dispatches: dispatches, for: dispatcher) { [weak self] transformedDispaches in
            let missingDispatchesAfterTransformations = dispatches.filter { oldDispatch in
                !transformedDispaches.contains { transformedDispatch in oldDispatch.id == transformedDispatch.id }
            }
            self?.queueManager.deleteDispatches(missingDispatchesAfterTransformations, for: dispatcher)
            dispatcher.dispatch(transformedDispaches) { [weak self] dispatches in
                self?.queueManager.deleteDispatches(dispatches, for: dispatcher)
                completion(dispatches)
            }
        }
    }
}
