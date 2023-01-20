//
//  TealiumTrace.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/12/22.
//

import Foundation

let tealiumQueue = DispatchQueue(label: "tealium queue")

public class TealiumTrace {
    let modulesManager: ModulesManager
    init(modulesManager: ModulesManager) {
        self.modulesManager = modulesManager
    }
    
    func getTraceModule(completion: @escaping (TraceModule?) -> Void) {
        modulesManager.getModule(completion: completion)
    }
    
    public func join(id: String) {
        getTraceModule { module in
            module?.join(id: id)
        }
    }
    
    public func leave() {
        getTraceModule { module in
            module?.leave()
        }
    }
    
    public func killVisitorSession() {
        getTraceModule { module in
            module?.killVisitorSession()
        }
    }
    
}

public class TraceModule: TealiumModule {
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
    
    var dataLayer: DataLayerModule? {
        context.modulesManager.getModule()
    }
    
    public func join(id: String) {
        dataLayer?.add(key: "trace_id", value: id)
    }
    public func leave() {
        dataLayer?.delete(key: "trace_id")
    }
}
