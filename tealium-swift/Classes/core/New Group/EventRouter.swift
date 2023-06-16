//
//  EventRouter.swift
//  Test
//
//  Created by Tyler Rister on 1/26/23.
//

import Foundation

public protocol ListenerProtocol: AnyObject {}

public protocol Messenger {
    associatedtype Listener
    func deliver(listener: Listener)
}

class AnotherTestMessage: Messenger {
    typealias Listener = ListenerProtocol

    let something: String
    init(something: String) {
        self.something = something
    }
//    typealias Listener = AnotherListener

    func deliver(listener: Listener) {
//        listener.onSomething(something: self.something)
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

public protocol DataLayerListener: ListenerProtocol {
    func onDataUpdated(data: [String: Any])
}

protocol AnotherListener: ListenerProtocol {
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
//        EventRouter().subscribe(listener: listener)
    }
}

public protocol VisitorProfileListener: ListenerProtocol {
    func onVisitorProfile()
}
class VisitorServiceModule: TealiumModule {
    static var id: String = "visitorservice"
    
    required init?(context: TealiumContext, moduleSettings: [String : Any]) {
        
    }
    
    let events = VisitorServiceEventPublishers()
    func subscribe(_ listener: VisitorProfileListener) {
//        EventRouter().subscribe(listener: listener)
    }
}


protocol SomeOtherProtocolThatDoesntComeFromRouter {
    func fromSomwhereElse()
}


//open class EventRouter<M: Messenger> where M.Listener == ListenerProtocol {
//    var listeners = [ListenerProtocol]()
//    open func subscribe<L: ListenerProtocol>(_ listener: L) {
//
//    }
//
//    func send(messenger: M) {
//
//    }
//}
//
//public class DataLayerRouter: EventRouter {
//
//
//    public func subscribe<L: DataLayerListener>(_ listener: L) {
//        super.subscribe(listener)
//    }
//}
//
//public class VisitorServiceRouter {
//
//
//    public func subscribe(_ listener: VisitorProfileListener) {
//
//    }
//}


public class EventRouter<M: Messenger> {
    public typealias Listener = M.Listener
    private var listeners: [Listener] = []

    public func subscribe(listener: Listener) {
        self.listeners.append(listener)
    }

    public func unsubscribe(listener: Listener) {
//        self.listeners.removeAll(where: { $0 === listener })
    }

    func unsubscribeAll() {
        self.listeners.removeAll()
    }

    public func send(messenger: M) {
        listeners
            .forEach { listener in
                messenger.deliver(listener: listener)
            }
    }
}


public class BufferedRouter<M: Messenger>: EventRouter<M> {
    var buffer = [M]()
    override public func send(messenger: M) {
        // buffer
        super.send(messenger: messenger)
    }
}

let dataLayerRouter = EventRouter<DataLayerMessenger>()
typealias DataLayerRouter = EventRouter<DataLayerMessenger>
//class DataLayerRouter<DataLayerMessenger> {
//
//}
let dlr = DataLayerRouter()


//public extension EventRouter {
//    /// Would we ever add something like this?
//    private class DataListener: DataLayerListener {
//        let handler: ([String: Any]) -> Void
//        init(handler: @escaping ([String: Any]) -> Void) {
//            self.handler = handler
//        }
//        func onDataUpdated(data: [String : Any]) {
//            handler(data)
//        }
//    }
//    func onDataUpdated(handler: @escaping ([String: Any]) -> Void) -> Listener {
//        let listener = DataListener(handler: handler)
//        subscribe(listener: listener)
//        return listener
//    }
//}

//protocol EventRouter {
//    associatedtype Listener
//    associatedtype Messenger
//    var listeners: [Listener] { get set }
//    func subscribe(listener: Listener)
//    func unsubscribe(listener: Listener)
//    func send(messenger: Messenger)
//}
//
//class DataLayerRouter: EventRouter {
//    var listeners: [Listener] = []
//
//    func subscribe(listener: Listener) {
//
//    }
//
//    func unsubscribe(listener: Listener) {
//
//    }
//
//    func send(messenger: DataLayerMessenger) {
//
//    }
//
//    typealias Listener = DataLayerListener
//
//    typealias Messenger = DataLayerMessenger
//
//
//}


//class DataLayerRouter2 {
//    
//    
//    let onDataUpdated: TealiumObservable<[String:Any]>
//    
//    enum Events {
//        
//    }
//    
//    
//    public func subscribeToAll(callback: @escaping (Events) -> ()) {
//        
//    }
//    
//}
