//
//  MockDispatcher.swift
//  tealium-prism_Tests
//
//  Created by Enrico Zannini on 01/12/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumPrism

class MockModule: Module {
    var version = "1.0.0"

    class var moduleType: String { String(describing: Self.self) }

    class func factory(allowsMultipleInstances: Bool = false,
                       enforcedSettings builder: ModuleSettingsBuilder? = ModuleSettingsBuilder()) -> any ModuleFactory {
        Self.Factory<Self>(allowsMultipleInstances: allowsMultipleInstances,
                           enforcedSettings: [builder].compactMap { $0?.build() })
    }

    class func factory(allowsMultipleInstances: Bool = false,
                       enforcedSettings builder: ModuleSettingsBuilder,
                       _ otherBuilders: ModuleSettingsBuilder...) -> any ModuleFactory {
        Self.Factory<Self>(allowsMultipleInstances: allowsMultipleInstances,
                           enforcedSettings: ([builder] + otherBuilders).map { $0.build() })
    }
    let id: String
    @StateSubject<DataObject>([:])
    var moduleConfiguration: ObservableState<DataObject>

    @ToAnyObservable<BasePublisher<Void>>(BasePublisher<Void>())
    static var onShutdown: Observable<Void>
    @ToAnyObservable<BasePublisher<Void>>(BasePublisher<Void>())
    var onShutdown: Observable<Void>
    let disposer = AutomaticDisposer()
    required init(moduleId: String = MockModule.factory().moduleType) {
        self.id = moduleId
        onShutdown.subscribe { Self._onShutdown.publish() }
            .addTo(disposer)
    }
    required init?(moduleId: String, context: TealiumContext, moduleConfiguration: DataObject) {
        _moduleConfiguration.value = moduleConfiguration
        self.id = moduleId
        onShutdown.subscribe { Self._onShutdown.publish() }
            .addTo(disposer)
    }

    func updateConfiguration(_ configuration: DataObject) -> Self? {
        _moduleConfiguration.value = configuration
        return self
    }

    func shutdown() {
        _onShutdown.publish()
    }

    class Factory<SpecificModule: MockModule>: ModuleFactory {
        let allowsMultipleInstances: Bool
        let moduleType: String

        let enforcedSettings: [DataObject]
        init(moduleType: String? = nil, allowsMultipleInstances: Bool = true, enforcedSettings: [DataObject]) {
            self.allowsMultipleInstances = allowsMultipleInstances
            self.moduleType = moduleType ?? String(describing: SpecificModule.self)
            self.enforcedSettings = enforcedSettings
        }
        func create(moduleId: String, context: TealiumContext, moduleConfiguration: DataObject) -> SpecificModule? {
            SpecificModule(moduleId: moduleId, context: context, moduleConfiguration: moduleConfiguration)
        }
        func getEnforcedSettings() -> [DataObject] {
            enforcedSettings
        }
    }

}

class MockDispatcher: MockModule, Dispatcher {
    var dispatchLimit: Int = 1
    var delay: Int?
    var queue = DispatchQueue.main

    required init(moduleId: String = MockDispatcher.moduleType) {
        super.init(moduleId: moduleId)
        self.onDispatch.subscribe { dispatches in
            Self._onDispatch.publish(dispatches)
        }.addTo(disposer)
    }

    required init?(moduleId: String, context: TealiumContext, moduleConfiguration: DataObject) {
        super.init(moduleId: moduleId, context: context, moduleConfiguration: moduleConfiguration)
        self.onDispatch.subscribe { dispatches in
            Self._onDispatch.publish(dispatches)
        }.addTo(disposer)
    }

    @ToAnyObservable<BasePublisher<[Dispatch]>>(BasePublisher())
    static var onDispatch: Observable<[Dispatch]>

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
    required init?(moduleId: String, context: TealiumContext, moduleConfiguration: DataObject) {
        super.init(moduleId: moduleId, context: context, moduleConfiguration: moduleConfiguration)
    }

    required init(moduleId: String = MockDispatcher1.moduleType) {
        super.init(moduleId: moduleId)
    }
}

class MockDispatcher2: MockDispatcher {
    required init?(moduleId: String, context: TealiumContext, moduleConfiguration: DataObject) {
        super.init(moduleId: moduleId, context: context, moduleConfiguration: moduleConfiguration)
        self.dispatchLimit = 3
    }

    required convenience init(moduleId: String = MockDispatcher2.moduleType) {
        self.init(moduleId: moduleId, dispatchLimit: 3)
    }

    init(moduleId: String = MockDispatcher.moduleType, dispatchLimit: Int = 3) {
        super.init(moduleId: moduleId)
        self.dispatchLimit = dispatchLimit
    }
}
