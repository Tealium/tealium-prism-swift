//
//  BarrierManager.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 23/04/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

typealias ScopedBarrier = (barrier: Barrier, scopes: [BarrierScope])

/**
 * A class that holds a list of `ConfigurableBarrier`s and a list of `ScopedBarrier`s.
 *
 * This class is responsible to handle the configuration of the `ConfigurableBarrier`s and of registering and unregistering the `ScopedBarrier`s.
 *
 * It exposes one `Observable` for all of the barriers along with their specific scopes, merging both of the arrays it manages.
 */
class BarrierManager: BarrierRegistry {
    @StateSubject([])
    var nonConfigBarriers: ObservableState<[ScopedBarrier]>

    @StateSubject([])
    var configBarriers: ObservableState<[ConfigurableBarrier]>

    private let sdkBarrierSettings: ObservableState<[String: BarrierSettings]>
    private var defaultBarrierScopes: [String: [BarrierScope]] = [:]

    /// An `Observable` for the configuration and registered barriers, along with their specific scopes.
    /// This emits a new array every time the settings change, or a new barrier is registered/unregistered.
    lazy private(set) var onScopedBarriers: Observable<[ScopedBarrier]> = nonConfigBarriers
        .combineLatest(scopedConfigBarriers())
        .map { $0 + $1 }

    let disposer = AutomaticDisposer()

    init(sdkBarrierSettings: ObservableState<[String: BarrierSettings]>) {
        self.sdkBarrierSettings = sdkBarrierSettings

        sdkBarrierSettings.subscribe { [weak self] barrierSettings in
            self?.configBarriers.value.forEach {
                $0.updateConfiguration(barrierSettings[$0.id]?.configuration ?? [:])
            }
        }.addTo(disposer)
    }

    /// Initializes the barriers from a list of factories and the context that the factories are going to use to initialize them.
    func initializeBarriers(factories: [any BarrierFactory], context: TealiumContext) {
        defaultBarrierScopes = factories.reduce(into: [:]) { partialResult, factory in
            partialResult[factory.id] = factory.defaultScopes()
        }
        _configBarriers.value = factories.map {
            $0.create(context: context, configuration: sdkBarrierSettings.value[$0.id]?.configuration ?? [:])
        }
    }

    /// An observable for the configuration barriers along with their scopes, updated every time new settings arrive.
    func scopedConfigBarriers() -> Observable<[ScopedBarrier]> {
        configBarriers.combineLatest(sdkBarrierSettings)
            .map { [ weak self] barriers, barrierSettings in
                barriers.map {
                    (barrier: $0,
                     scopes: barrierSettings[$0.id]?.scopes ?? self?.defaultBarrierScopes[$0.id] ?? [.all])
                }
            }
    }

    /// Register a barrier to some specific scopes, overriding the scopes in case the same barrier was already added.
    /// The barrier added in this way won't receive update settings and won't override the same barrier if added via the `TealiumConfig`.
    func registerScopedBarrier(_ barrier: any Barrier, scopes: [BarrierScope]) {
        let scopedBarrier: ScopedBarrier = (barrier, scopes)
        var barriers = nonConfigBarriers.value
        if let index = barriers.firstIndex(where: { $0.barrier === barrier }) {
            barriers[index] = scopedBarrier
        } else {
            barriers.append(scopedBarrier)
        }
        _nonConfigBarriers.value = barriers
    }

    /// Unregister a barrier that was previously register via `registerScopedBarrier`.
    func unregisterScopedBarrier(_ barrier: any Barrier) {
        _nonConfigBarriers.value = _nonConfigBarriers.value.filter { $0.barrier !== barrier }
    }
}
