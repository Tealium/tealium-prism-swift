//
//  TealiumCollect.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 06/12/22.
//

import Foundation


public class TealiumCollect: Dispatcher {
    public var enabled: Bool = true
    
    public func updateSettings(settings: [String : Any]) {
        // TODO: Add Settings stuff
    }
    
    public static var id: String = "collect"
    
    
    
    public required init(context: TealiumContext, moduleSettings: [String: Any]) {
        
    }
    
    public func dispatch(_ data: TealiumDispatch) {
        print(data)
    }
}
