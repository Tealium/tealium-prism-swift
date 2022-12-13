//
//  Tealium.swift
//  tealium-swift
//
//  Created by Tyler Rister on 12/5/22.
//

import Foundation

let defaultConfig = """
{
    "core": {
        "account":"tealiummobile",
        "profile":"finance",
        "environment":"dev"
    },
    "collect": {
    }
}
"""

class SettingsProvider {
    
    init(config: TealiumConfig) {
        guard let path = (Bundle.main).path(forResource: config.configFile, ofType: "json"),
            let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe),
            let settings = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
            let settings = settings else {
            return
        }
        _onConfigUpdate.publish(settings)
    }
    
    @ToAnyObservable(TealiumReplaySubject<[String:Any]>())
    var onConfigUpdate: TealiumObservable<[String: Any]>
    
}


public class Tealium: TealiumProtocol {
    let settingsProvider: SettingsProvider
    var bag = TealiumDisposeBag()
    var context: TealiumContext?
    required public init(_ config: TealiumConfig) {
        var config = config
        config.modules += [
            TealiumDataLayer.self,
            TealiumTrace.self,
            TealiumDeepLink.self,
            TealiumCollector.self
        ]
        self.timedEvents = TealiumTimedEvents()
        self.consent = TealiumConsent()
        self.modules = []
        self.settingsProvider = SettingsProvider(config: config)
        context = TealiumContext(self, config: config, coreSettings: CoreSettings(coreDictionary: [:]))
        settingsProvider.onConfigUpdate.subscribe { [weak self] settings in
            guard let self = self, let context = self.context else {
                return
            }
            if self.modules.isEmpty {
                self.setupModules(config, context: context, settings: settings)
            } else {
                self.updateModules(context: context, settings: settings)
            }
        }.toDisposeBag(bag)
        _onReady.publish()
    }
    
    private func setupModules(_ config: TealiumConfig, context: TealiumContext, settings: [String: Any]) {
        if let coreSettings = settings["core"] as? [String: Any] {
            context.coreSettings.updateSettings(coreSettings)
        }
        self.modules = config.modules.compactMap({ Module in
            let moduleSettings = settings[Module.id] as? [String: Any]
            return Module.init(context: context, moduleSettings: moduleSettings ?? [:])
        })
        _onReady.publish()
    }
    
    private func updateModules(context: TealiumContext, settings: [String: Any]) {
        context.coreSettings.updateSettings(settings)
        modules.forEach { module in
            let moduleSettings = settings[type(of: module).id] as? [String: Any]
            module.updateSettings(moduleSettings ?? [:])
        }
    }
    
    public func track(_ trackable: TealiumDispatch) {
        var trackable = trackable
        let modules = enabledModules
        modules.compactMap { $0 as? Collector }
            .forEach { collector in
                trackable.enrich(data: collector.data)
            }
        // dispatch barries
        // queueing
        // batching
        modules.compactMap { $0 as? Dispatcher }
            .forEach { dispatcher in
                dispatcher.dispatch([trackable])
            }
    }
    
    @ToAnyObservable(TealiumReplaySubject<Void>())
    public var onReady: TealiumObservable<Void>
    
    
    public func onReady(_ completion: @escaping () -> Void) {
        onReady.subscribeOnce(completion)
    }
    
    public var trace: TealiumTrace? {
        getModule()
    }
    
    public var deepLink: TealiumDeepLink? {
        getModule()
    }
    
    public var dataLayer: TealiumDataLayer? {
        getModule()
    }
    
    public var timedEvents: TealiumTimedEvents
    
    public var consent: TealiumConsent
    
    public var modules: [TealiumModule]
    
    public var enabledModules: [TealiumModule] {
        modules.filter { $0.enabled }
    }
    
    private func getModule<T: TealiumModule>() -> T? {
        modules.compactMap { $0 as? T }.first
    }
}
