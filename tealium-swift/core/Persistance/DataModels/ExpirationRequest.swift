//
//  ExpirationRequest.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 18/09/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

enum ExpirationRequest {
    case restart
    case sessionChange

    var expiryTime: Double {
        switch self {
        case .restart:
            return Expiry.untilRestart.expiryTime()
        case .sessionChange:
            return Expiry.session.expiryTime()
        }
    }
}
