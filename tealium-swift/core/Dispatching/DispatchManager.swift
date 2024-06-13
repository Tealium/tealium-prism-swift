//
//  DispatchManager.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/10/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
/**
 * The class containing the core logic of the library, taking `TealiumDispatch`es from the queue, transforming and dispatching them to each individual `Dispatcher` when they are ready.
 */
class DispatchManager {
    static let MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER = 50
    let barrierCoordinator: BarrierCoordinator
    let transformerCoordinator: TransformerCoordinator

    var dispatchers: [Dispatcher] {
        modulesManager.modules.value.compactMap { $0 as? Dispatcher }
    }
    var onDispatchers: TealiumObservable<[Dispatcher]> {
        modulesManager.modules.map { moduleList in moduleList.compactMap { $0 as? Dispatcher } }
    }
    let modulesManager: ModulesManager
    let queueManager: QueueManagerProtocol
    var consentManager: ConsentManager? {
        modulesManager.modules.value.compactMap { $0 as? ConsentManager }.first
    }
    let logger: TealiumLoggerProvider?
    @ToAnyObservable<TealiumPublisher<Void>>(TealiumPublisher<Void>())
    var onQueuedEvents: TealiumObservable<Void>

    init(modulesManager: ModulesManager,
         queueManager: QueueManagerProtocol,
         barrierCoordinator: BarrierCoordinator,
         transformerCoordinator: TransformerCoordinator,
         logger: TealiumLoggerProvider? = nil) {
        self.modulesManager = modulesManager
        self.queueManager = queueManager
        self.barrierCoordinator = barrierCoordinator
        self.transformerCoordinator = transformerCoordinator
        self.logger = logger
        startDispatchLoop()
    }

    func tealiumPurposeExplicitlyBlocked() -> Bool {
        guard let consentManager = consentManager else {
            return false
        }
        guard let decision = consentManager.getConsentDecision(),
              decision.decisionType == .explicit else {
            return false
        }
        return !consentManager.tealiumConsented(forPurposes: decision.purposes)
    }

    func track(_ dispatch: TealiumDispatch) {
        track(dispatch, onTrackResult: nil)
    }

    func track(_ dispatch: TealiumDispatch, onTrackResult: TrackResultCompletion?) {
        guard !tealiumPurposeExplicitlyBlocked() else {
            logger?.info?.log(category: TealiumLibraryCategories.dispatching,
                              message: "Tealium purpose was explicitly declined, discarding this dispatch!")
            onTrackResult?(dispatch, .dropped)
            return
        }
        transformerCoordinator.transform(dispatch: dispatch, for: .afterCollectors) { [weak self] transformed in
            guard let self, let transformed else {
                onTrackResult?(dispatch, .dropped)
                return
            }
            if let consentManager = self.consentManager {
                consentManager.applyConsent(to: transformed, completion: onTrackResult)
            } else {
                self.queueManager.storeDispatches([transformed], enqueueingFor: dispatchers.map { $0.id })
                onTrackResult?(transformed, .accepted)
            }
        }
    }

    private var managerContainer = TealiumAutomaticDisposer()

    func stopDispatchLoop() {
        managerContainer = TealiumAutomaticDisposer()
    }

    func startDispatchLoop() {
        onDispatchers.flatMapLatest { dispatchers in
            TealiumObservable.From(dispatchers)
        }.flatMap { [weak self, coordinator = barrierCoordinator] dispatcher in
            coordinator.onBarrierState(for: dispatcher.id)
                .flatMapLatest { [weak self] barriersState in
                    self?.logger?.trace?.log(category: TealiumLibraryCategories.dispatching, message: "BarrierState changed \(barriersState)")
                    if barriersState == .open,
                       let newLoop = self?.startDequeueLoop(for: dispatcher) {
                        return newLoop
                    } else {
                        return .Empty()
                    }
                }.flatMap { [weak self] dispatches in
                    TealiumObservable.Callback { [weak self] observer in
                        guard let self = self else {
                            return TealiumSubscription { }
                        }
                        self.logger?.debug?.log(category: TealiumLibraryCategories.dispatching,
                                                message: "Dispatching events to dispatcher \(dispatcher.id): \(dispatches.shortDescription())")
                        return self.transformAndDispatch(dispatches: dispatches, for: dispatcher) { completedDispatches in
                            observer(completedDispatches)
                        }
                    }
                }
        }
        .subscribe { [weak self] dispatches in
            self?.logger?.debug?.log(category: TealiumLibraryCategories.dispatching,
                                     message: "Dispatched and deleted from Queue/inflight: \(dispatches.shortDescription())")
        }.addTo(self.managerContainer)
    }

    private func startDequeueLoop(for dispatcher: Dispatcher) -> TealiumObservable<[TealiumDispatch]> {
        let onInflightLower = queueManager.onInflightDispatchesCount(for: dispatcher.id)
            .map { $0 < Self.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER }
            .distinct()
        let queueManager = self.queueManager
        return queueManager.onEnqueuedDispatchesForProcessors
            .filter { processors in processors.contains { $0 == dispatcher.id } }
            .startWith([])
            .flatMapLatest { _ in
                onInflightLower
                    .filter { $0 }
                    .map { _ in queueManager.getQueuedDispatches(for: dispatcher.id, limit: dispatcher.dispatchLimit) }
                    .filter { !$0.isEmpty }
                    .resubscribingWhile { $0.count >= dispatcher.dispatchLimit } // Loops the `getQueuedDispatches` as long as we pull `dispatchLimit` items from the queue
            }
    }

    private func transformAndDispatch(dispatches: [TealiumDispatch], for dispatcher: Dispatcher, completion: @escaping ([TealiumDispatch]) -> Void) -> TealiumDisposable {
        let container = TealiumDisposeContainer()
        self.transformerCoordinator.transform(dispatches: dispatches, for: .dispatcher(dispatcher.id)) { [weak self] transformedDispaches in
            guard !container.isDisposed else { return }
            let missingDispatchesAfterTransformations = dispatches.filter { oldDispatch in
                !transformedDispaches.contains { transformedDispatch in oldDispatch.id == transformedDispatch.id }
            }
            if !missingDispatchesAfterTransformations.isEmpty {
                self?.queueManager.deleteDispatches(missingDispatchesAfterTransformations.map { $0.id }, for: dispatcher.id)
            }
            dispatcher.dispatch(transformedDispaches) { [weak self] dispatches in
                guard !container.isDisposed else { return }
                self?.queueManager.deleteDispatches(dispatches.map { $0.id }, for: dispatcher.id)
                completion(dispatches)
            }.addTo(container)
        }
        return container
    }
}

private extension Array where Element == TealiumDispatch {
    func shortDescription() -> String {
        "\(map { $0.name ?? "" })"
    }
}
