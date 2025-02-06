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

    func updateSettings(context: TealiumContext, settings: SDKSettings) {
        let oldModules = self.modules.value
        _modules.value = context.config.modules.compactMap({ moduleFactory -> TealiumModule? in
            let updateInterval = TealiumSignpostInterval(signposter: .settings, name: "Module Update")
                .begin(moduleFactory.id)
            defer { updateInterval.end() }
            let moduleSettings = settings.modulesSettings[moduleFactory.id] ?? DataObject()
            if let module = oldModules.first(where: { $0.id == moduleFactory.id }) {
                guard moduleFactory.shouldBeEnabled(by: moduleSettings),
                      let module = module.updateSettings(moduleSettings) else {
                    context.logger?.debug(category: moduleFactory.id,
                                          "Module failed to update settings. Module will be shut down.")
                    module.shutdown()
                    return nil
                }
                context.logger?.trace(category: moduleFactory.id, "Settings updated to \(moduleSettings)")
                return module
            } else {
                guard moduleFactory.shouldBeEnabled(by: moduleSettings),
                    let module = moduleFactory.create(context: context, moduleSettings: moduleSettings) else {
                    context.logger?.debug(category: moduleFactory.id,
                                          "Module failed to initialize.")
                    return nil
                }
                return module
            }
        })
    }

    public func getModule<T: TealiumModule>(_ module: T.Type = T.self) -> T? {
        modules.value.compactMap { $0 as? T }.first
    }

    public func getModule<T: TealiumModule>(completion: @escaping (T?) -> Void) {
        queue.ensureOnQueue { [weak self] in
            completion(self?.getModule())
        }
    }
    deinit {
        modules.value.forEach {
            $0.shutdown()
        }
    }
}
