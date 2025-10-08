//
//  ModulesManager.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 20/01/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public class ModulesManager {
    private typealias SettingsFactoryPair = (moduleSettings: ModuleSettings, factory: any ModuleFactory)
    @StateSubject var modules: ObservableState<[Module]>
    let queue: TealiumQueue
    init(queue: TealiumQueue, initialModules: [Module] = []) {
        self.queue = queue
        _modules = StateSubject(initialModules)
    }

    func updateSettings(context: TealiumContext, settings: SDKSettings) {
        let modulesSettings = settings.modules.values.sorted { $0.order < $1.order }
        let initializedModules = Dictionary(modules.value.map { ($0.id, $0) }, prefersFirst: true)
        let factories = Dictionary(context.config.modules.map { ($0.moduleType, $0) }, prefersFirst: true)
        _modules.value = modulesSettings
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
         */
        _modules.value = []
    }
}
