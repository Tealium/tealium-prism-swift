//
//  BaseSubject.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 03/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

/// A protocol to provide all subject-like classes both Observable and Publisher functionality plus some utilities like subscribe.
public protocol Subject: Subscribable, Publisher {
}

public extension Subject {
    func subscribe(_ observer: @escaping Observer) -> Disposable {
        asObservable().subscribe(observer)
    }
}

/// A concrete implementation of the `Subject` that allows to just publish and subscribe to events.
public class BaseSubject<Element>: BasePublisher<Element>, Subject {
}
