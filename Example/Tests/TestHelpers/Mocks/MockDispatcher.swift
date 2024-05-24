//
//  MockDispatcher.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 01/12/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumSwift

class MockModule: TealiumModule {
    class var id: String { "mockModule" }
    init() { }
    required init?(context: TealiumContext, moduleSettings: [String: Any]) {
        let enabled = moduleSettings["enabled"] as? Bool ?? true
        if !enabled {
            return nil
        }
    }

    func updateSettings(_ settings: [String: Any]) -> Self? {
        let enabled = settings["enabled"] as? Bool ?? true
        if !enabled {
            return nil
        }
        return self
    }
}

class MockDispatcher: MockModule, Dispatcher {
    var dispatchLimit: Int { 1 }
    class override var id: String { "mockDispacher" }
    var delay: Int?
    var queue = DispatchQueue.main

    @ToAnyObservable<TealiumPublisher<[TealiumDispatch]>>(TealiumPublisher())
    var onDispatch: TealiumObservable<[TealiumDispatch]>

    func dispatch(_ data: [TealiumDispatch], completion: @escaping ([TealiumDispatch]) -> Void) -> TealiumDisposable {
        let subscription = TealiumSubscription { }
        if let delay = delay {
            queue.asyncAfter(deadline: .now() + .milliseconds(delay)) {
                guard !subscription.isDisposed else { return }
                self._onDispatch.publish(data)
                completion(data)
            }
        } else {
            _onDispatch.publish(data)
            completion(data)
        }
        return subscription
    }
}

class MockDispatcher1: MockDispatcher {
    override class var id: String { "mockDispatcher1" }
    override init() {
        super.init()
    }
    required init?(context: TealiumContext, moduleSettings: [String: Any]) {
        super.init(context: context, moduleSettings: moduleSettings)
    }
}
class MockDispatcher2: MockDispatcher {
    override var dispatchLimit: Int { 3 }
    override class var id: String { "mockDispatcher2" }
    override init() {
        super.init()
    }
    required init?(context: TealiumContext, moduleSettings: [String: Any]) {
        super.init(context: context, moduleSettings: moduleSettings)
    }
}
