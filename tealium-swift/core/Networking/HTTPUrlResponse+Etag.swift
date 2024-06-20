//
//  HTTPUrlResponse+Etag.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/06/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

extension HTTPURLResponse {
    private static let etagKey = "Etag"
    var etag: String? {
        if #available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, macCatalyst 13.1, *) {
            return value(forHTTPHeaderField: Self.etagKey)
        } else {
            return headerString(field: Self.etagKey)
        }
    }

    func headerString(field: String) -> String? {
        return (self.allHeaderFields as NSDictionary)[field] as? String
    }
}
