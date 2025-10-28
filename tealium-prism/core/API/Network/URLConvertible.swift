//
//  URLConvertible.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 18/07/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// A protocol used to receive requests with String/URL/URLComponents intercheangebly
public protocol URLConvertible {
    /// Converts this object to a URL.
    /// - Returns: The URL representation.
    /// - Throws: An error if the conversion fails.
    func asUrl() throws -> URL
}

extension URL: URLConvertible {
    /// Returns this URL as-is.
    public func asUrl() throws -> URL {
        self
    }
}

extension String: URLConvertible {
    /// Converts this string to a URL.
    /// - Returns: The URL representation.
    /// - Throws: An error if the conversion fails.
    public func asUrl() throws -> URL {
        guard let url = URL(string: self) else {
            throw ParsingError.invalidUrl(self)
        }
        return url
    }
}

extension URLComponents: URLConvertible {
    /// Converts these URL components to a URL.
    /// - Returns: The URL representation.
    /// - Throws: An error if the conversion fails.
    public func asUrl() throws -> URL {
        guard let url = url else {
            throw ParsingError.invalidUrl(self)
        }
        return url
    }
}
