//
//  ModuleManager.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 20/01/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// Manages the lifecycle and configuration of modules within the Tealium SDK.
public class ModuleManager {
    private typealias SettingsFactoryPair = (moduleSettings: ModuleSettings, factory: any ModuleFactory)
    @StateSubject var modules: ObservableState<[Module]>
    let queue: TealiumQueue

    /**
     * `modules`, gated so that nothing is emitted before a module-creation settings pass has run.
     *
     * `modules` is a `StateSubject` seeded with an empty array, so a synchronous read can't tell
     * "no module of that type is enabled" from "the modules haven't been created yet". Anything
     * making a permanent decision out of a missing module has to observe this instead.
     *
     * An empty pass counts as ready: it means nothing was configured, not that a pass is pending.
     *
     * TODO: MT-2154 - `modules` itself shouldn't emit before the first pass; this gate is the
     *  targeted fix for the modules that make decisions out of a missing module.
     */
    private let modulesOnReady = ReplaySubject<[Module]>()
    private let disposables = Disposables.composite()

    init(queue: TealiumQueue, initialModules: [Module] = []) {
        self.queue = queue
        _modules = StateSubject(initialModules)
        /*
         `updates()` and not `asObservable()`: the latter replays the seeded value on subscription,
         which is the "no modules yet" answer the gate exists to withhold. Feeding the gate from here
         keeps it in sync with every write to `modules`, with no separate publishing path to forget.
         */
        _modules.updates()
            .subscribe { [modulesOnReady] modules in modulesOnReady.onNext(modules) }
            .addTo(disposables)
        // Modules provided upfront are ready without waiting for a settings pass.
        if !initialModules.isEmpty {
            modulesOnReady.onNext(initialModules)
        }
    }

    func updateSettings(context: TealiumContext, settings: SDKSettings) {
        /*
         The pass about to run invalidates the previous answer, so it must not be replayed: a module
         created by this pass would be told that the modules of this same pass don't exist, which is
         the very thing the gate exists to prevent. Existing subscribers keep their subscription and
         simply receive the result of this pass.
         */
        modulesOnReady.clear()
        let modulesSettings = settings.modules.values.sorted { $0.order < $1.order }
        let initializedModules = Dictionary(modules.value.map { ($0.id, $0) }, prefersFirst: true)
        let factories = Dictionary(context.config.modules.map { ($0.moduleType, $0) }, prefersFirst: true)
        let createdModules = modulesSettings
            .compactMap { moduleSettings in
                guard let factory = factories[moduleSettings.moduleType] else {
                    context.logger?.warn(category: moduleSettings.moduleId,
                                         """
                                         Module Factory missing. \(moduleSettings.moduleId) can't be initialized.
                                         To initialize it make sure to provide a \(moduleSettings.moduleType) \
                                         factory on the TealiumConfig.
                                         """)
                    return nil
                }
                return (moduleSettings, factory)
            }
            .removingDuplicates(by: \SettingsFactoryPair.moduleSettings.moduleType, and: { _, factory in
                let shouldBeDiscarded = !factory.allowsMultipleInstances
                if shouldBeDiscarded {
                    context.logger?.warn(category: factory.moduleType,
                                         """
                                         Attempted to create an additional module instance; \
                                         but an instance already exists and multiple instances \
                                         for \(factory.moduleType) are not allowed.
                                         """)
                }
                return shouldBeDiscarded
            })
            .removingDuplicates(by: \SettingsFactoryPair.moduleSettings.moduleId)
            .compactMap { moduleSettings, moduleFactory in
                let updateInterval = TealiumSignpostInterval(signposter: .settings, name: "Module Update")
                    .begin(moduleSettings.moduleType)
                defer { updateInterval.end() }

                let moduleId = moduleFactory.allowsMultipleInstances ? moduleSettings.moduleId : moduleFactory.moduleType
                if let module = initializedModules[moduleId] {
                    return updateModule(context: context,
                                        module: module,
                                        moduleSettings: moduleSettings,
                                        moduleFactory: moduleFactory)
                } else {
                    return createModule(context: context,
                                        moduleId: moduleId,
                                        moduleSettings: moduleSettings,
                                        moduleFactory: moduleFactory)
                }
            }
        _modules.value = createdModules
    }

    private func updateModule(context: TealiumContext,
                              module: Module,
                              moduleSettings: ModuleSettings,
                              moduleFactory: any ModuleFactory) -> Module? {
        guard moduleFactory.shouldBeEnabled(by: moduleSettings),
              let module = module.updateConfiguration(moduleSettings.configuration) else {
            context.logger?.debug(category: module.id,
                                  "Module failed to update configuration. Module will be shut down.")
            module.shutdown()
            return nil
        }
        context.logger?.trace(category: module.id, "Configuration updated to \(moduleSettings.configuration)")
        return module
    }

    private func createModule(context: TealiumContext,
                              moduleId: String,
                              moduleSettings: ModuleSettings,
                              moduleFactory: any ModuleFactory) -> Module? {
        guard moduleFactory.shouldBeEnabled(by: moduleSettings),
              let module = moduleFactory.create(moduleId: moduleId,
                                                context: context,
                                                moduleConfiguration: moduleSettings.configuration) else {
            context.logger?.debug(category: moduleId, "Module failed to initialize.")
            return nil
        }
        return module
    }

    func getModule<T: Module>(_ module: T.Type = T.self) -> T? {
        modules.value.compactMap { $0 as? T }.first
    }

    /**
     * Observes the module of the given type, regardless of whether it is currently enabled.
     *
     * While the modules are still being created, a subscriber receives no value at all rather than a
     * premature `nil`. Once this starts emitting, `nil` means the module is not enabled - it never
     * means that the modules are still being created.
     *
     * - Parameter module: The type used to match the module.
     * - Returns: An `Observable` of the module, emitting whenever the resolved module changes by
     * identity - a modules update that leaves it unchanged, `nil` included, emits nothing.
     */
    func observeModule<T: Module>(_ module: T.Type = T.self) -> Observable<T?> {
        modulesOnReady.asObservable()
            .map { modules in
                modules.compactMap { $0 as? T }.first
            }
            .distinct { $0 === $1 }
            .subscribeOn(queue)
    }

    /// Asynchronously retrieves a module of the specified type.
    /// - Parameter completion: Called with the module instance or nil if not found.
    public func getModule<T: Module>(completion: @escaping (T?) -> Void) {
        queue.ensureOnQueue { [weak self] in
            completion(self?.getModule())
        }
    }

    func shutdown() {
        modules.value.forEach {
            $0.shutdown()
        }
        /*
         Clearing the modules list in the observable will propagate the event
         to any StateObserver created from it,
         therefore removing all of the references to the modules and avoiding retain cycles.
         Publishing also releases anything still waiting for a module: after a shutdown it is never
         going to arrive.
         */
        _modules.value = []
        // Only once that empty list has reached the gate, or the waiters would never be released.
        disposables.dispose()
    }
}
