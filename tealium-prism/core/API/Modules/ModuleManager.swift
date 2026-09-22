//
//  ModuleManager.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 20/01/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * Manages the lifecycle and configuration of modules within the Tealium SDK.
 *
 * - Warning: This class is not thread safe. The methods that do the work, like `getModule`, must be
 * called from the Tealium queue - which is where a `Module` runs, so `context.moduleManager` can be
 * used directly from a module initialization or updateConfiguration methods.
 * The methods that only return an `Observable`, like `observeModule`, can be called from any queue,
 * but that `Observable` must be subscribed from the Tealium queue and emits from it: to consume it
 * elsewhere, chain `subscribeOn(_:)` with the Tealium queue followed by `observeOn(_:)` with yours.
 */
public class ModuleManager {
    private typealias SettingsFactoryPair = (moduleSettings: ModuleSettings, factory: any ModuleFactory)
    /**
     * The modules of the last settings pass, seeded with an empty array.
     *
     * - Warning: A synchronous read can't tell "no module of that type is enabled" from "the modules
     * haven't been created yet", so anything making a permanent decision out of a missing module has
     * to go through `observeModule`/`observeModules`/`getModule` instead, which withhold that
     * premature answer. Reading this directly is only safe once the modules have been created and
     * while no update is running - as it is at collect or dispatch time, which the `Tracker` only
     * reaches with the modules already enabled.
     */
    @StateSubject var modules: ObservableState<[Module]>

    /**
     * Emits once the modules of a settings pass have all been created, and is cleared while a pass is
     * running, so a subscriber arriving mid-pass waits for it to complete instead of being replayed
     * the answer of the previous one.
     *
     * `shutdown()` emits it again on an empty modules list: after a shutdown no module is ever
     * going to arrive, so waiting for one is the one answer that would never come.
     */
    private let onReady = ReplaySubject<Void>()

    init(initialModules: [Module] = []) {
        _modules = StateSubject(initialModules)
        // Modules provided upfront are ready without waiting for a settings pass.
        if !initialModules.isEmpty {
            onReady.onNext()
        }
    }

    func updateSettings(context: TealiumContext, settings: SDKSettings) {
        onReady.clear()
        let previous = _modules.value
        let updated = updateModules(context: context, settings: settings)
        /*
         Any module of the previous pass that didn't make it into this one is shut down here, whether
         it was disabled, failed to update, or simply removed from the settings entirely. This runs
         before publishing so no consumer ever observes a live list holding a module that is dead.
         */
        previous.diff(updated, by: ===).forEach { module in
            context.logger?.debug(category: module.id, "Module no longer enabled. Shutting down.")
            module.shutdown()
        }
        _modules.value = updated
        onReady.onNext()
    }

    private func updateModules(context: TealiumContext, settings: SDKSettings) -> [Module] {
        let modulesSettings = settings.modules.values.sorted { $0.order < $1.order }
        let initializedModules = Dictionary(modules.value.map { ($0.id, $0) }, prefersFirst: true)
        let factories = Dictionary(context.config.modules.map { ($0.moduleType, $0) }, prefersFirst: true)
        return modulesSettings
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
    }

    private func updateModule(context: TealiumContext,
                              module: Module,
                              moduleSettings: ModuleSettings,
                              moduleFactory: any ModuleFactory) -> Module? {
        guard moduleFactory.shouldBeEnabled(by: moduleSettings),
              let module = module.updateConfiguration(moduleSettings.configuration) else {
            context.logger?.debug(category: module.id,
                                  "Module no longer enabled or failed to update configuration. Module will be shut down.")
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

    /*
     The gate only holds back a subscription until the first pass has finished: `first` completes on
     the first emission, so the later ones - end of each pass, and shutdown - don't open a second
     subscription to `modules` and replay the same list twice.
     A subscriber that is already through is protected by `updateSettings` instead, which assigns
     `_modules.value` exactly once per pass, after every module of that pass has been created - so
     there is no intermediate list for it to be handed while a pass is running.
     */
    private func _observeModules() -> Observable<[Module]> {
        onReady.asObservable()
            .first()
            .flatMap { [modules] in
                modules.asObservable()
                    .distinct { $0.count == $1.count && $0.elementsEqual($1, by: ===) }
            }
    }

    /**
     * Observes the objects created by the successful transformations of each module, regardless of whether that module is currently enabled.
     *
     * While the modules are still being created, or updated, a subscriber receives no value at all rather than a
     * premature empty array `[]`. Once the modules are ready, the `transform` block will be called with every `Module`,
     * in order.
     * The returned `Observable`, per modules array change, emits a compact map of all the transformations succeeded.
     *
     * The array is only emitted again when the set of modules whose transformation succeeded changes, by identity or
     * order. A value that varies over time for the same module is not re-emitted: observe it through the module itself.
     *
     * Comparison is by identity rather than `id` because `updateConfiguration` may mutate a module in place and
     * return the same instance - which must not be re-emitted - while a module replaced by a new instance with the
     * same `id` must be. It is order-sensitive because module order is significant.
     *
     * Casting to a protocol is the basic use-case for this method.
     *
     * ```swift
     *  moduleManager.observeModules { $0 as? SomeProtocol }
     *      .subscribe { myProtocols in
     *          for myProtocol in myProtocols {
     *              myProtocol.protocolMethod()
     *          }
     *      }
     * ```
     *
     * - Parameter transform: The transformation to be applied to each module.
     * - Returns: An `Observable` of the transformed modules, emitting after every modules update
     * with the objects of all the transformations that succeeded, in order, or an empty array when
     * none of them did.
     */
    public func observeModules<T>(_ transform: @escaping (Module) -> T?) -> Observable<[T]> {
        _observeModules()
            .map { modules in
                modules.compactMap { module in transform(module).map { (module: module, value: $0) } }
            }
            .distinct { $0.count == $1.count && $0.elementsEqual($1) { $0.module === $1.module } }
            .map { $0.map(\.value) }
    }

    /**
     * Observes the object created by the transformation of a module, regardless of whether that module is currently enabled.
     *
     * While the modules are still being created, or updated, a subscriber receives no value at all rather than a
     * premature `nil`. Once the modules are ready, the `transform` block will be called with every `Module`,
     * in order, until one of them returns a non-nil `T`.
     * The returned `Observable`, per modules array change, emits `nil` when none of the transformations succeeded, or the first object
     * successfully returned by a transformation block.
     *
     * The object is only emitted again when the module whose transformation succeeded changes, by identity.
     * A value that varies over time for the same module is not re-emitted: observe it through the module itself.
     *
     * Casting to a protocol is the basic use-case for this method.
     *
     * ```swift
     *  moduleManager.observeModule { $0 as? SomeProtocol }
     *      .subscribe { myProtocol in
     *          myProtocol.protocolMethod()
     *      }
     * ```
     *
     * - Parameter transform: The transformation to be applied to each module, until one succeeds.
     * - Returns: An `Observable` of the module, emitting after every modules update with the resolved object if one transformation succeeds,
     * or `nil` when no transformation succeeds.
     */
    public func observeModule<T>(_ transform: @escaping (Module) -> T?) -> Observable<T?> {
        _observeModules()
            .map { modules in
                // lazy so that we only perform the transformation until we get a valid T at most once
                modules.lazy
                    .compactMap { module in transform(module).map { (module: module, value: $0) } }
                    .first
            }
            .distinct { $0?.module === $1?.module }
            .map { $0?.value }
    }

    /**
     * Observes the module of the given type, regardless of whether it is currently enabled.
     *
     * While the modules are still being created, or updated, a subscriber receives no value at all rather than a
     * premature `nil`. Once this starts emitting, `nil` means the module is not enabled - it never
     * means that the modules are still being created.
     *
     * In case multiple modules of this type are enabled at the same time, the first one,
     * ordered by `[`ModuleSettings.order`](doc:ModuleSettings/order), will be returned.
     *
     * Upon changes of the modules list this `Observable` won't emit again unless the actual `Module`
     * instance is different from the last returned one.
     *
     * - Parameter module: The type used to match the module.
     * - Returns: An `Observable` of the module, emitting after every modules update whenever
     * the resolved module changes by identity.
     */
    public func observeModule<T: Module>(_ module: T.Type = T.self) -> Observable<T?> {
        observeModule { $0 as? T }
    }

    /**
     * Asynchronously retrieves the object created by the transformation of a module. The completion is called once, after the modules are ready.
     *
     * The transformation is applied in order by `[`ModuleSettings.order`](doc:ModuleSettings/order) and upon first successful transformation, the completion is called
     * immediately and no other transformation is applied.
     *
     * Casting to a protocol is the basic use-case for this method.
     *
     * ```swift
     *  moduleManager.getModule(transform: { $0 as? SomeProtocol },
     *                          completion: { $0?.protocolMethod() })
     * ```
     *
     * - Parameter transform: The transformation to be applied to each module, until one succeeds. If not provided, it will just try to cast the `Module` as `T`.
     * - Parameter completion: Called, once the modules are ready, with the transformed module instance or nil if no transformation succeeds.
     * - Returns: A `Disposable` that can be disposed to avoid the completion being called.
     */
    @discardableResult
    public func getModule<T>(transform: @escaping (Module) -> T? = { $0 as? T },
                             completion: @escaping (T?) -> Void) -> any Disposable {
        observeModule(transform)
            .subscribeOnce(completion)
    }

    func shutdown() {
        onReady.clear()
        modules.value.forEach {
            $0.shutdown()
        }
        /*
         Clearing the modules list in the observable will propagate the event
         to any StateObserver created from it,
         therefore removing all of the references to the modules and avoiding retain cycles.
         */
        _modules.value = []
        // Only once that empty list is in place, or a waiter would be handed the modules being shut down.
        onReady.onNext()
    }
}
