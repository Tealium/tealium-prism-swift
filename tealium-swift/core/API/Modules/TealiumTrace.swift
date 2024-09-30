//
//  TealiumTrace.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

public class TealiumTrace {
    typealias Module = TraceModule
    private let modulesManager: ModulesManager
    init(modulesManager: ModulesManager) {
        self.modulesManager = modulesManager
    }
    private func getModule(completion: @escaping (Module?) -> Void) {
        modulesManager.getModule(completion: completion)
    }
    public func join(id: String) {
        getModule { module in
            module?.join(id: id)
        }
    }

    public func leave() {
        getModule { module in
            module?.leave()
        }
    }

    public func killVisitorSession(completion onTrackResult: TrackResultCompletion?) {
        getModule { module in
            module?.killVisitorSession(completion: onTrackResult)
        }
    }
}

class TraceModule: TealiumBasicModule {
    static let id: String = "Trace"

    let context: TealiumContext
    required init(context: TealiumContext, moduleSettings: DataObject) {
        self.context = context
    }

    func killVisitorSession(completion onTrackResult: TrackResultCompletion? = nil) {
        let dispatch = TealiumDispatch(name: TealiumKey.killVisitorSession,
                                       data: [
                                        TealiumDataKey.killVisitorSessionEvent: TealiumKey.killVisitorSession
                                       ])
        context.tracker?.track(dispatch, onTrackResult: onTrackResult)
    }

    var dataLayer: DataLayerModule? {
        context.modulesManager?.getModule()
    }

    func join(id: String) {
        dataLayer?.add(key: "trace_id", value: id)
    }
    func leave() {
        dataLayer?.delete(key: "trace_id")
    }
}
