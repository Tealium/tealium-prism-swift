//
//  VisitorIdManagerWrapper.swift
//  tealium-prism
//
//  Created by Den Guzov on 25/09/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

class VisitorIdManagerWrapper: VisitorIdManager {
    typealias Element = Result<String, ModuleError<Error>>

    private let moduleProxy: ModuleProxy<VisitorIdModule, Error>
    private let onVisitorId: any Subscribable<Element>

    init(moduleProxy: ModuleProxy<VisitorIdModule, Error>) {
        self.moduleProxy = moduleProxy
        self.onVisitorId = moduleProxy.observeModuleResult(transform: \.visitorId)
    }

    func current() -> SingleResult<String, ModuleError<Error>> {
        moduleProxy.executeModuleTask(\.visitorId.value)
    }

    @discardableResult
    func regenerate() -> SingleResult<String, ModuleError<Error>> {
        moduleProxy.executeModuleTask { module in
            try module.regenerate()
        }
    }

    @discardableResult
    func eraseLocalHistory() -> SingleResult<String, ModuleError<Error>> {
        moduleProxy.executeModuleTask { module in
            try module.eraseLocalHistory()
        }
    }

    func subscribe<O: Observer<Element>>(_ observer: O) -> any Disposable {
        onVisitorId.subscribe(observer)
    }
}
