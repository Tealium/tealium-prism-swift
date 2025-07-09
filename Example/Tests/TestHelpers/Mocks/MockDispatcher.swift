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
    var version = "1.0.0"
    class var id: String { "MockModule" }
    class var factory: any TealiumModuleFactory { DefaultModuleFactory<Self>() }

    @StateSubject<DataObject>([:])
    var moduleConfiguration: ObservableState<DataObject>

    @ToAnyObservable<BasePublisher<Void>>(BasePublisher<Void>())
    var onShutdown: Observable<Void>

    init() { }
    required init?(context: TealiumContext, moduleConfiguration: DataObject) {
        _moduleConfiguration.value = moduleConfiguration
    }

    func updateConfiguration(_ configuration: DataObject) -> Self? {
        _moduleConfiguration.value = configuration
        return self
    }

    func shutdown() {
        _onShutdown.publish()
    }
}

class MockDispatcher: MockModule, Dispatcher {
    var dispatchLimit: Int = 1
    class override var id: String { "MockDispatcher" }
    var delay: Int?
    var queue = DispatchQueue.main

    @ToAnyObservable<BasePublisher<[Dispatch]>>(BasePublisher())
    var onDispatch: Observable<[Dispatch]>

    func dispatch(_ data: [Dispatch], completion: @escaping ([Dispatch]) -> Void) -> Disposable {
        let subscription = Subscription { }
        let completion: ([Dispatch]) -> Void = { data in
            guard !subscription.isDisposed, !data.isEmpty else { return }
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
    required init?(context: TealiumContext, moduleConfiguration: DataObject) {
        super.init(context: context, moduleConfiguration: moduleConfiguration)
    }
}
class MockDispatcher2: MockDispatcher {
    override class var id: String { "MockDispatcher2" }
    override init() {
        super.init()
        dispatchLimit = 3
    }
    required init?(context: TealiumContext, moduleConfiguration: DataObject) {
        super.init(context: context, moduleConfiguration: moduleConfiguration)
        dispatchLimit = 3
    }
    init(dispatchLimit: Int) {
        super.init()
        self.dispatchLimit = dispatchLimit
    }
}
