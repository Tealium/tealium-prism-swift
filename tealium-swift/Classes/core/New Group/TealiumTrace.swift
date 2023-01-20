//
//  TealiumTrace.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/12/22.
//

import Foundation

public class TealiumTrace: TealiumModule {
    public static var id: String = "trace"
    
    let context: TealiumContext
    public required init(context: TealiumContext, moduleSettings: [String : Any]) {
        self.context = context
    }
    
    public func killVisitorSession() {
        let dispatch = TealiumDispatch(name: TealiumKey.killVisitorSession,
                                    data: [
                                        TealiumDataKey.killVisitorSessionEvent: TealiumKey.killVisitorSession
                                    ])
        context.tealiumProtocol?.track(dispatch)
    }
    public func join(id: String) {
        context.tealiumProtocol?.dataLayer?.add(key: "trace_id", value: id)
    }
    public func leave() {
        context.tealiumProtocol?.dataLayer?.delete(key: "trace_id")
    }
}
