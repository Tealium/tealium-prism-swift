//
//  TealiumSubject.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 03/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

/// A protocol to provide all subject-like classes both Observable and Publisher functionality plus some utilities like subscribe.
public protocol TealiumSubjectProtocol: TealiumObservableProtocol, TealiumPublisherProtocol {
}

public extension TealiumSubjectProtocol {
    func subscribe(_ observer: @escaping Observer) -> TealiumDisposable {
        asObservable().subscribe(observer)
    }
}

/// A concrete implementation of the `TealiumSubjectProtocol` that allows to just publish and subscribe to events.
public class TealiumSubject<Element>: TealiumPublisher<Element>, TealiumSubjectProtocol {
}
