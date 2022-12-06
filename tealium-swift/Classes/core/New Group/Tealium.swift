//
//  Tealium.swift
//  tealium-swift
//
//  Created by Tyler Rister on 12/5/22.
//

import Foundation

class Tealium: TealiumProtocol {
    
    required init(_ config: TealiumConfig) {
        
        
        self.trace = TealiumTrace()
        self.deepLink = TealiumDeepLink()
        self.dataLayer = TealiumDataLayer()
        self.timedEvents = TealiumTimedEvents()
        self.consent = TealiumConsent()
        self.modules = []
    }
    
    func track(_ trackable: TealiumDispatch) {
        
    }
    
    func onReady(_ completion: @escaping () -> Void) {
        
    }
    
    var trace: TealiumTrace
    
    var deepLink: TealiumDeepLink
    
    var dataLayer: TealiumDataLayer
    
    var timedEvents: TealiumTimedEvents
    
    var consent: TealiumConsent
    
    var modules: [TealiumModule]
    
    
}
