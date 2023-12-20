//
//  TealiumModule.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 24/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol TealiumModule {
    static var id: String { get }
    init?(context: TealiumContext, moduleSettings: [String: Any])

    func updateSettings(_ settings: [String: Any]) -> Self?
}
public extension TealiumModule {
    var id: String {
        type(of: self).id
    }
}

public extension TealiumModule {
    func updateSettings(_ settings: [String: Any]) -> Self? {
        return self
    }
}

public protocol Collector: TealiumModule {
    var data: TealiumDictionaryInput { get }
}

public protocol Dispatcher: TealiumModule {
    var dispatchLimit: Int { get }
    func dispatch(_ data: [TealiumDispatch], completion: @escaping ([TealiumDispatch]) -> Void) -> TealiumDisposable
}

public extension Dispatcher {
    var dispatchLimit: Int { 1 }
}
