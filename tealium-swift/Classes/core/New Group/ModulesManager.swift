//
//  ModulesManager.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 20/01/23.
//

import Foundation
public let tealiumQueue = DispatchQueue(label: "tealium.queue") // TODO: change this
public class ModulesManager {
    var modules = [TealiumModule]()
    
    func updateSettings(context: TealiumContext, settings: [String: Any]) {
        if self.modules.isEmpty {
            self.setupModules(context: context, settings: settings)
        } else {
            self.updateModules(context: context, settings: settings)
        }
    }
    
    private func setupModules(context: TealiumContext, settings: [String: Any]) {
        self.modules = context.config.modules.compactMap({ ModuleClass in
            let updateInterval = TealiumSignpostInterval(signposter: .settings, name: "Module Update")
                .begin(ModuleClass.id)
            defer { updateInterval.end() }
            let moduleSettings = settings[ModuleClass.id] as? [String: Any] ?? [:]
            return ModuleClass.init(context: context, moduleSettings: moduleSettings)
        })
    }
    
    private func updateModules(context: TealiumContext, settings: [String: Any]) {
        let oldModules = self.modules
        self.modules = context.config.modules.compactMap({ ModuleClass in
            let updateInterval = TealiumSignpostInterval(signposter: .settings, name: "Module Update")
                .begin(ModuleClass.id)
            defer { updateInterval.end() }
            let moduleSettings = settings[ModuleClass.id] as? [String: Any] ?? [:]
            if let module = oldModules.first(where: { type(of: $0) == ModuleClass }) {
                return module.updateSettings(moduleSettings)
            } else {
                return ModuleClass.init(context: context, moduleSettings: moduleSettings)
            }
        })
    }
    
    public func getModule<T: TealiumModule>(_ module: T.Type) -> T? {
        getModule()
    }
    
    public func getModule<T: TealiumModule>() -> T? {
        modules.compactMap { $0 as? T }.first
    }
    
    public func getModule<T: TealiumModule>(completion: @escaping (T?) -> Void) {
        tealiumQueue.async {
            completion(self.getModule())
        }
    }
    
    public func getAllModuleAs<T>() -> [T] {
        modules.compactMap { $0 as? T }
    }
}
