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
    private let barrierCoordinator: BarrierCoordinator
    private let transformerCoordinator: TransformerCoordinator

    private var dispatchers: [Dispatcher] {
        modulesManager.modules.value.compactMap { $0 as? Dispatcher }
    }
    private var onDispatchers: Observable<[Dispatcher]> {
        modulesManager.modules.map { moduleList in moduleList.compactMap { $0 as? Dispatcher } }
    }
    private let modulesManager: ModulesManager
    private let queueManager: QueueManagerProtocol
    private var consentManager: ConsentManager? {
        modulesManager.modules.value.compactMap { $0 as? ConsentManager }.first
    }
    private let logger: TealiumLoggerProvider?
    @ToAnyObservable<BasePublisher<Void>>(BasePublisher<Void>())
    private var onQueuedEvents: Observable<Void>

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
            logger?.debug?.log(category: LogCategory.dispatchManager, message: "Tealium consent purpose is explicitly blocked. Event \(dispatch.logDescription()) will be dropped.")
            onTrackResult?(dispatch, .dropped)
            return
        }
        transformerCoordinator.transform(dispatch: dispatch, for: .afterCollectors) { [weak self] transformed in
            guard let self, let transformed else {
                self?.logger?.debug?.log(category: LogCategory.dispatchManager, message: "Event \(dispatch.logDescription()) dropped due to transformer")
                onTrackResult?(dispatch, .dropped)
                return
            }
            if let consentManager = self.consentManager {
                self.logger?.debug?.log(category: LogCategory.dispatchManager, message: "Event \(transformed.logDescription()) consent applied")
                consentManager.applyConsent(to: transformed, completion: onTrackResult)
            } else {
                self.logger?.debug?.log(category: LogCategory.dispatchManager, message: "Event \(transformed.logDescription()) accepted for processing")
                self.queueManager.storeDispatches([transformed], enqueueingFor: dispatchers.map { $0.id })
                onTrackResult?(transformed, .accepted)
            }
        }
    }

    private var managerContainer = AutomaticDisposer()

    func stopDispatchLoop() {
        managerContainer = AutomaticDisposer()
    }

    func startDispatchLoop() {
        onDispatchers.flatMapLatest { dispatchers in
            Observable.From(dispatchers)
        }.flatMap { [weak self, coordinator = barrierCoordinator] dispatcher in
            coordinator.onBarrierState(for: dispatcher.id)
                .flatMapLatest { [weak self] barriersState in
                    self?.logger?.debug?.log(category: LogCategory.dispatchManager, message: "BarrierState changed for \(dispatcher.id): \(barriersState)")
                    if barriersState == .open,
                       let newLoop = self?.startDequeueLoop(for: dispatcher) {
                        return newLoop
                    } else {
                        return .Empty()
                    }
                }.flatMap { [weak self] dispatches in
                    Observable.Callback { [weak self] observer in
                        guard let self = self else {
                            return Subscription { }
                        }
                        self.logger?.debug?.log(category: LogCategory.dispatchManager,
                                                message: "Sending events to dispatcher \(dispatcher.id): \(dispatches.shortDescription())")
                        return self.transformAndDispatch(dispatches: dispatches, for: dispatcher) { processedDispatches in
                            observer((dispatcher, processedDispatches))
                        }
                    }
                }
        }
        .subscribe { [weak self] dispatcher, processedDispatches in
            self?.queueManager.deleteDispatches(processedDispatches.map { $0.id }, for: dispatcher.id)
            self?.logger?.debug?.log(category: LogCategory.dispatchManager,
                                     message: "Dispatcher: \(dispatcher.id) processed events: \(processedDispatches.shortDescription())")
        }.addTo(self.managerContainer)
    }

    private func startDequeueLoop(for dispatcher: Dispatcher) -> Observable<[TealiumDispatch]> {
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
                    .map { _ in queueManager.getQueuedDispatches(for: dispatcher.id,
                                                                 limit: min(dispatcher.dispatchLimit, Self.MAXIMUM_INFLIGHT_EVENTS_PER_DISPATCHER))
                    }
                    .filter { !$0.isEmpty }
                    .resubscribingWhile { $0.count >= dispatcher.dispatchLimit } // Loops the `getQueuedDispatches` as long as we pull `dispatchLimit` items from the queue
            }
    }

    private func transformAndDispatch(dispatches: [TealiumDispatch], for dispatcher: Dispatcher, onProcessedDispatches: @escaping ([TealiumDispatch]) -> Void) -> Disposable {
        let container = DisposeContainer()
        self.transformerCoordinator.transform(dispatches: dispatches, for: .dispatcher(dispatcher.id)) { transformedDispatches in
            guard !container.isDisposed else { return }
            let missingDispatchesAfterTransformations = dispatches.filter { oldDispatch in
                !transformedDispatches.contains { transformedDispatch in oldDispatch.id == transformedDispatch.id }
            }
            if !missingDispatchesAfterTransformations.isEmpty {
                onProcessedDispatches(missingDispatchesAfterTransformations)
            }
            dispatcher.dispatch(transformedDispatches) { processedDispatches in
                guard !container.isDisposed else { return }
                onProcessedDispatches(processedDispatches)
            }.addTo(container)
        }
        return container
    }
}

private extension Array where Element == TealiumDispatch {
    func shortDescription() -> String {
        "\(map { $0.logDescription() })"
    }
}
