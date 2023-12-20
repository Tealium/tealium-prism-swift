//
//  MockDispatcher.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 01/12/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumSwift

class MockDispatcher: Dispatcher {
    var dispatchLimit: Int { 1 }
    class var id: String { "mockDispacher" }
    var delay: Int?
    var queue = DispatchQueue.main

    @ToAnyObservable<TealiumPublisher<[TealiumDispatch]>>(TealiumPublisher())
    var onDispatch: TealiumObservable<[TealiumDispatch]>

    required init?(context: TealiumContext, moduleSettings: [String: Any]) {
        let enabled = moduleSettings["enabled"] as? Bool ?? true
        if !enabled {
            return nil
        }
    }

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

    func updateSettings(_ settings: [String: Any]) -> Self? {
        let enabled = settings["enabled"] as? Bool ?? true
        if !enabled {
            return nil
        }
        return self
    }
}

class MockDispatcher1: MockDispatcher {
    override class var id: String { "mockDispatcher1" }
}
class MockDispatcher2: MockDispatcher {
    override var dispatchLimit: Int { 3 }
    override class var id: String { "mockDispatcher2" }
}
