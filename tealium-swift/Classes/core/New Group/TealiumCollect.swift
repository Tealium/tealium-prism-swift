//
//  TealiumCollect.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 06/12/22.
//

import Foundation


public class TealiumCollect: Dispatcher {
    public static var id: String = "collect"
    
    public required init(context: TealiumContext, moduleSettings: [String: Any]) {
        
    }
    
    public func updateSettings(_ settings: [String : Any]) -> Self? {
        print("Collect settings")
        return self
    }
    
    public func dispatch(_ data: [TealiumDispatch]) {
        print(data)
    }
}
