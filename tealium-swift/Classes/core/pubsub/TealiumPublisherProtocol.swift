//
//  Publisher.swift
//  TealiumCore
//
//  Created by Enrico Zannini on 03/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol TealiumPublisherProtocol: TealiumObservableConvertibleProtocol {
    func publish(_ element: Element)
}
