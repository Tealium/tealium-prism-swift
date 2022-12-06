//
//  TealiumCollect.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 06/12/22.
//

import Foundation


public class TealiumCollect: Dispatcher {
    public static var id: String = "collect"
    
    
    
    public required init(_ context: TealiumContext, config: [String: Any]) {
        
    }
    
    public func dispatch(_ data: TealiumDispatch) {
        print(data)
    }
}
