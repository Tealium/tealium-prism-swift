//
//  EventRouter.swift
//  Test
//
//  Created by Tyler Rister on 1/26/23.
//

import Foundation

public protocol Listener: AnyObject {}

public protocol Messenger {
    associatedtype Listener
    func deliver(listener: Listener)
}


class AnotherTestMessage: Messenger {
    let something: String
    init(something: String) {
        self.something = something
    }
    typealias Listener = AnotherListener
    
    func deliver(listener: Listener) {
        listener.onSomething(something: self.something)
    }
}

class DataLayerMessenger: Messenger {
    let data: [String: Any]
    init(data: [String: Any]) {
        self.data = data
    }
    typealias Listener = DataLayerListener
    
    func deliver(listener: Listener) {
        listener.onDataUpdated(data: self.data)
    }
    
}

protocol DataLayerListener: Listener {
    func onDataUpdated(data: [String: Any])
}

protocol AnotherListener: Listener {
    func onSomething(something: String)
}

class AnotherListenerTest: AnotherListener {
    func onSomething(something: String) {
        print(something)
    }
}

class ATestListener: DataLayerListener {
    func onDataUpdated(data: [String : Any]) {
        print(data)
    }
}


extension DataLayerModule {
    
    
    func subscribe(_ listener: DataLayerListener) {
        EventRouter().subscribe(listener: listener)
    }
}

protocol VisitorProfileListener: Listener {
    func onVisitorProfile()
}
class VisitorServiceModule {
    
    func subscribe(_ listener: VisitorProfileListener) {
        EventRouter().subscribe(listener: listener)
    }
}


protocol SomeOtherProtocolThatDoesntComeFromRouter {
    func fromSomwhereElse()
}



public class EventRouter {
    private var listeners: [Listener] = []

    public func subscribe(listener: Listener) {
        self.listeners.append(listener)
    }

    public func unsubscribe(listener: Listener) {
        self.listeners.removeAll(where: { $0 === listener })
    }
    
    func unsubscribeAll() {
        self.listeners.removeAll()
    }
    
    public func send<T: Messenger>(messenger: T) {
        listeners.compactMap { $0 as? T.Listener }
            .forEach { listener in
                messenger.deliver(listener: listener)
            }
    }
}



public extension EventRouter {
    /// Would we ever add something like this?
    private class DataListener: DataLayerListener {
        let handler: ([String: Any]) -> Void
        init(handler: @escaping ([String: Any]) -> Void) {
            self.handler = handler
        }
        func onDataUpdated(data: [String : Any]) {
            handler(data)
        }
    }
    func onDataUpdated(handler: @escaping ([String: Any]) -> Void) -> Listener {
        let listener = DataListener(handler: handler)
        subscribe(listener: listener)
        return listener
    }
}
