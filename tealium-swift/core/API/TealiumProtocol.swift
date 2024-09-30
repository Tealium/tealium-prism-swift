//
//  TealiumProtocol.swift
//  tealium-swift
//
//  Created by Tyler Rister on 5/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

public class TealiumTimedEvents {
    func start(event name: String, with data: DataObject = DataObject()) {}
    func stop(event name: String) {}
    func cancel(event name: String) {}
    func cancelAll() {}
}

public class TealiumConsent {
    // func grant(withPurpose: )
}
