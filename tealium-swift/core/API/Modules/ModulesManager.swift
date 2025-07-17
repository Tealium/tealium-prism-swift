//
//  ModulesManager.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 20/01/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public class ModulesManager {
    @StateSubject var modules: ObservableState<[Module]>
    let queue: TealiumQueue
    init(queue: TealiumQueue, initialModules: [Module] = []) {
        self.queue = queue
        _modules = StateSubject(initialModules)
    }

    func updateSettings(context: TealiumContext, settings: SDKSettings) {
        let oldModules = self.modules.value
        _modules.value = context.config.modules.compactMap({ moduleFactory -> Module? in
            let updateInterval = TealiumSignpostInterval(signposter: .settings, name: "Module Update")
                .begin(moduleFactory.id)
            defer { updateInterval.end() }
            let moduleSettings = settings.modules[moduleFactory.id] ?? ModuleSettings()
            if let module = oldModules.first(where: { $0.id == moduleFactory.id }) {
                guard moduleFactory.shouldBeEnabled(by: moduleSettings),
                      let module = module.updateConfiguration(moduleSettings.configuration) else {
                    context.logger?.debug(category: moduleFactory.id,
                                          "Module failed to update settings. Module will be shut down.")
                    module.shutdown()
                    return nil
                }
                context.logger?.trace(category: moduleFactory.id, "Settings updated to \(moduleSettings)")
                return module
            } else {
                guard moduleFactory.shouldBeEnabled(by: moduleSettings),
                      let module = moduleFactory.create(context: context, moduleConfiguration: moduleSettings.configuration) else {
                    context.logger?.debug(category: moduleFactory.id,
                                          "Module failed to initialize.")
                    return nil
                }
                return module
            }
        })
    }

    public func getModule<T: Module>(_ module: T.Type = T.self) -> T? {
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
