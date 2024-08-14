//
//  MockDispatcher.swift
//  tealium-swift_Tests
//
//  Created by Enrico Zannini on 01/12/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumSwift

class MockModule: TealiumBasicModule {
    class var id: String { "MockModule" }
    class var factory: any TealiumModuleFactory { DefaultModuleFactory(module: Self.self) }

    @StateSubject<[String: Any]>([:])
    var moduleSettings: ObservableState<[String: Any]>

    @ToAnyObservable<BasePublisher<Void>>(BasePublisher<Void>())
    var onShutdown: Observable<Void>

    init() { }
    required init?(context: TealiumContext, moduleSettings: [String: Any]) {
        _moduleSettings.value = moduleSettings
    }

    func updateSettings(_ settings: [String: Any]) -> Self? {
        _moduleSettings.value = settings
        return self
    }

    func shutdown() {
        _onShutdown.publish()
    }
}

class MockDispatcher: MockModule, Dispatcher {
    var dispatchLimit: Int = 1
    class override var id: String { "MockDispacher" }
    var delay: Int?
    var queue = DispatchQueue.main

    @ToAnyObservable<BasePublisher<[TealiumDispatch]>>(BasePublisher())
    var onDispatch: Observable<[TealiumDispatch]>

    func dispatch(_ data: [TealiumDispatch], completion: @escaping ([TealiumDispatch]) -> Void) -> Disposable {
        let subscription = Subscription { }
        let completion: ([TealiumDispatch]) -> Void = { data in
            guard !subscription.isDisposed else { return }
            self._onDispatch.publish(data)
            completion(data)
        }
        if let delay = delay {
            if delay > 0 {
                queue.asyncAfter(deadline: .now() + .milliseconds(delay)) {
                    completion(data)
                }
            } else {
                queue.async {
                    completion(data)
                }
            }
        } else {
            completion(data)
        }
        return subscription
    }
}

class MockDispatcher1: MockDispatcher {
    override class var id: String { "MockDispatcher1" }
    override init() {
        super.init()
    }
    required init?(context: TealiumContext, moduleSettings: [String: Any]) {
        super.init(context: context, moduleSettings: moduleSettings)
    }
}
class MockDispatcher2: MockDispatcher {
    override class var id: String { "MockDispatcher2" }
    override init() {
        super.init()
        dispatchLimit = 3
    }
    required init?(context: TealiumContext, moduleSettings: [String: Any]) {
        super.init(context: context, moduleSettings: moduleSettings)
        dispatchLimit = 3
    }
}
