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

class ConfigProvider {
    
    init() {
        guard let data = defaultConfig.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data),
              let config = json as? [String: Any] else {
            return
        }
        _onConfigUpdate.publish(config)
    }
    
    @ToAnyObservable(TealiumReplaySubject<[String:Any]>())
    var onConfigUpdate: TealiumObservable<[String: Any]>
    
}


public class Tealium: TealiumProtocol {
    let configProvider = ConfigProvider()
    var bag = TealiumDisposeBag()
    required public init(_ config: CoreConfig) {
        self.trace = TealiumTrace()
        self.deepLink = TealiumDeepLink()
        self.dataLayer = TealiumDataLayer()
        self.timedEvents = TealiumTimedEvents()
        self.consent = TealiumConsent()
        self.modules = []
        let context = TealiumContext(self, config: config)
        configProvider.onConfigUpdate.subscribe { [weak self] updates in
            guard let self = self,
                  let coreConfig = updates["core"] as? [String: Any]
                else { return }
            context.config.updateConfig(coreConfig)
            self.modules = config.modules.compactMap({ Module in
                guard let moduleConfig = updates[Module.id] as? [String: Any] else {
                    return nil
                }
                return Module.init(context, config: moduleConfig) // TODO: module.init should only happen the first time, later should be config update
            })
        }.toDisposeBag(bag)
        
        _onReady.publish()
    }
    
    public func track(_ trackable: TealiumDispatch) {
        var trackable = trackable
        modules.compactMap { $0 as? Collector }
            .forEach { collector in
                trackable.enrich(data: collector.data)
            }
        // dispatch barries
        // queueing
        modules.compactMap { $0 as? Dispatcher }
            .forEach { dispatcher in
                dispatcher.dispatch(trackable)
            }
    }
    
    @ToAnyObservable(TealiumReplaySubject<Void>())
    public var onReady: TealiumObservable<Void>
    
    
    public func onReady(_ completion: @escaping () -> Void) {
        onReady.subscribeOnce(completion)
    }
    
    public var trace: TealiumTrace
    
    public var deepLink: TealiumDeepLink
    
    public var dataLayer: TealiumDataLayer
    
    public var timedEvents: TealiumTimedEvents
    
    public var consent: TealiumConsent
    
    public var modules: [TealiumModule]
    
    
}
