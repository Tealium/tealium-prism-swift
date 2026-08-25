//
//  String+Interpolations.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 24/08/2026.
//  Copyright © 2026 Tealium, Inc. All rights reserved.
//

import Foundation

extension String {
    func with<T>(_ value: T?, appending block: (T) -> String) -> String {
        guard let value else { return self }
        return self + block(value)
    }
}

extension String.StringInterpolation {

    mutating func appendInterpolation(body: Data) {
        let interpolation = if let string = String(data: body, encoding: .utf8) {
            if string.isEmpty {
                "Empty body"
            } else {
                "Body: \(string)"
            }
        } else {
            "Non UTF8 encoded body: \(body.debugDescription)"
        }
        appendInterpolation(interpolation)
    }

    mutating func appendInterpolation(response: HTTPURLResponse) {
        let interpolation = """
        URL: \(response.url?.absoluteString ?? "")
        Status Code: \(response.statusCode)
        Headers: \(response.allHeaderFields.map { "\($0.key.base): \($0.value)" })
        """
        appendInterpolation(interpolation)
    }
}
