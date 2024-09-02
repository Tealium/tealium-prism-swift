//
//  ModulesManager.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 20/01/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public class ModulesManager {
    @StateSubject([])
    var modules: ObservableState<[TealiumModule]>
    let queue: TealiumQueue
    init(queue: TealiumQueue) {
        self.queue = queue
    }

    func updateSettings(context: TealiumContext, settings: [String: Any]) {
        let oldModules = self.modules.value
        _modules.value = context.config.modules.compactMap({ moduleFactory in
            let updateInterval = TealiumSignpostInterval(signposter: .settings, name: "Module Update")
                .begin(moduleFactory.id)
            defer { updateInterval.end() }
            let moduleSettings = settings[moduleFactory.id] as? [String: Any] ?? [:]
            if let module = oldModules.first(where: { $0.id == moduleFactory.id }) {
                guard moduleFactory.shouldBeEnabled(by: moduleSettings),
                      let module = module.updateSettings(moduleSettings) else {
                    context.logger?.debug?.log(category: moduleFactory.id,
                                               message: "Module failed to update settings. Module will be shut down.")
                    module.shutdown()
                    return nil
                }
                context.logger?.trace?.log(category: moduleFactory.id, message: "Settings updated to \(moduleSettings)")
                return module
            } else {
                guard moduleFactory.shouldBeEnabled(by: moduleSettings),
                    let module = moduleFactory.create(context: context, moduleSettings: moduleSettings) else {
                    context.logger?.debug?.log(category: moduleFactory.id,
                                               message: "Module failed to initialize.")
                    return nil
                }
                return module
            }
        })
    }

    public func getModule<T: TealiumModule>(_ module: T.Type) -> T? {
        getModule()
    }

    public func getModule<T: TealiumModule>() -> T? {
        modules.value.compactMap { $0 as? T }.first
    }

    public func getModule<T: TealiumModule>(completion: @escaping (T?) -> Void) {
        queue.ensureOnQueue {
            completion(self.getModule())
        }
    }

    public func getAllModuleAs<T>() -> [T] {
        modules.value.compactMap { $0 as? T }
    }
}
