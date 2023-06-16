//
//  TealiumSignposter.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 20/03/23.
//

import Foundation
import os.signpost

@available(iOS 15.0, *)
public extension OSSignposter {
    static let tracking = OSSignposter(subsystem: "com.tealium.swift", category: "tracking")
}

public class SignpostStateWrapper {

    private let intervalState: Any
    @available(iOS 15.0, *)
    init(_ intervalState: OSSignpostIntervalState) {
        self.intervalState = intervalState
    }
    
    @available(iOS 15.0, *)
    func state() -> OSSignpostIntervalState? {
        intervalState as? OSSignpostIntervalState
    }
}

@available(iOS 15.0, *)
public extension OSSignpostIntervalState {
    func toWrapper() -> SignpostStateWrapper {
        SignpostStateWrapper(self)
    }
}

public class TealiumSignposter {
    /// Set this to true at the start of the app to make sure Signposting is enabled
    public static var enabled = false
    private let category: String
    @available(iOS 15.0, *)
    var signposter: OSSignposter {
        if TealiumSignposter.enabled {
            return OSSignposter(subsystem: "com.tealium.swift", category: category)
        } else {
            return OSSignposter.disabled
        }
    }
    init(category: String) {
        self.category = category
    }
    
    func beginInterval(_ name: StaticString) -> SignpostStateWrapper? {
        if #available(iOS 15.0, *) {
            // defer { Thread.sleep(forTimeInterval: 0.5) } // TODO: Remove, only here for testing now
            return signposter
                .beginInterval(name,
                               id: signposter.makeSignpostID())
                .toWrapper()
        }
        return nil
    }
    
    func beginInterval(_ name: StaticString, _ message: @autoclosure @escaping () -> String) -> SignpostStateWrapper? {
        if #available(iOS 15.0, *) {
            // defer { Thread.sleep(forTimeInterval: 0.5) } // TODO: Remove, only here for testing now
            return signposter
                .beginInterval(name,
                               id: signposter.makeSignpostID(),
                               "\(message(), privacy: .public)")
                .toWrapper()
        }
        return nil
    }
    
    func endInterval(_ name: StaticString, state: SignpostStateWrapper?) {
        if #available(iOS 15.0, *), let state = state?.state() {
            signposter.endInterval(name,
                                   state)
        }
    }
    
    func endInterval(_ name: StaticString, state: SignpostStateWrapper?, _ message: @autoclosure @escaping () -> String) {
        if #available(iOS 15.0, *), let state = state?.state() {
            signposter.endInterval(name,
                                   state,
                                   "\(message(), privacy: .public)")
        }
    }
    
    func event(_ name: StaticString) {
        if #available(iOS 15.0, *) {
            signposter.emitEvent(name,
                                 id: signposter.makeSignpostID())
        }
    }
    
    func event(_ name: StaticString, message: @autoclosure @escaping () -> String) {
        if #available(iOS 15.0, *) {
            signposter.emitEvent(name,
                                 id: signposter.makeSignpostID(),
                                 "\(message(), privacy: .public)")
        }
    }
}

extension TealiumSignposter {
    static let startup = TealiumSignposter(category: "Startup")
    static let tracking = TealiumSignposter(category: "Tracking")
    static let collecting = TealiumSignposter(category: "Collecting")
    static let dispatching = TealiumSignposter(category: "Dispatching")
    static let settings = TealiumSignposter(category: "Settings")
    
}

class TealiumSignpostInterval {
    let signposter: TealiumSignposter
    let name: StaticString
    private var state: SignpostStateWrapper?
    
    convenience init(category: String, name: StaticString) {
        self.init(signposter: TealiumSignposter(category: category),
                  name: name)
    }
    
    init(signposter: TealiumSignposter, name: StaticString) {
        self.signposter = signposter
        self.name = name
    }
    
    
    func begin() {
        state = signposter.beginInterval(name)
    }
    
    func begin(_ message: @autoclosure @escaping () -> String){
        state = signposter.beginInterval(name, message())
    }
    
    func end() {
        signposter.endInterval(name, state: state)
    }
    
    func end(_ message: @autoclosure @escaping () -> String) {
        signposter.endInterval(name, state: state, message())
    }
    
    func signpostedWork<Output>(_ work: @escaping () throws -> Output) rethrows -> Output {
        begin()
        defer { end() }
        return try work()
    }
    
    func signpostedWork<Output>(_ message: @autoclosure @escaping () -> String, _ work: @escaping () throws -> Output) rethrows -> Output {
        begin(message())
        defer { end() }
        return try work()
    }
}


