//
//  URLConvertible.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 18/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// A protocol used to receive requests with String/URL/URLComponents intercheangebly
public protocol URLConvertible {
    func asUrl() throws -> URL
}

extension URL: URLConvertible {
    public func asUrl() throws -> URL {
        self
    }
}

extension String: URLConvertible {
    public func asUrl() throws -> URL {
        guard let url = URL(string: self) else {
            throw ParsingError.invalidUrl(self)
        }
        return url
    }
}

extension URLComponents: URLConvertible {
    public func asUrl() throws -> URL {
        guard let url = url else {
            throw ParsingError.invalidUrl(self)
        }
        return url
    }
}
