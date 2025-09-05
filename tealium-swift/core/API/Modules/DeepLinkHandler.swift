//
//  DeepLinkHandler.swift
//  tealium-swift
//
//  Created by Den Guzov on 15/04/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 The `Referrer` allows the `DeepLinkHandler` to track the origin of a deep link, whether it came from a URL or another app.
 This can be passed as an optional parameter to the `handle(link:referrer:)` method for further processing.
 */
public enum Referrer {
    case url(_ url: URL)
    case app(_ identifier: String)

    public static func fromUrl(_ url: URL?) -> Self? {
        guard let url = url else { return nil }
        return .url(url)
    }

    public static func fromAppId(_ identifier: String?) -> Self? {
        guard let id = identifier else { return nil }
        return .app(id)
    }
}

/**
 The `DeepLinkHandler` is responsible for tracking incoming deep links,
 managing attribution, and handling trace parameters when present in the URL.
 - Attention: The handler is automatically called on iOS unless explicitly disabled.
 */
public protocol DeepLinkHandler {
    /**
     Handles a deep link for various purposes, such as attribution or trace management.
     - Parameters:
        - link: The `URL` representing the deep link to be handled.
        - referrer: An optional `Referrer` indicating the source of the deep link (e.g., a URL or app identifier).
     - Returns: A `Single` containing a `Result` that indicates success (`Void`) or failure (`Error`).
     */
    @discardableResult
    func handle(link: URL, referrer: Referrer?) -> SingleResult<Void>
}
