//
//  CollectConfiguration.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 14/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// The settings used by the `TealiumCollect` module.
struct CollectConfiguration {
    enum Keys {
        /// The URL used to send single events
        static let url = "url"
        /// The URL used to send a batch of events
        static let batchUrl = "batch_url"
        /// The profile used to override the `TealiumConfig.profile` in the event data sent to the collect endpoint
        static let overrideProfile = "override_profile"
        /// The domain used to replace the default single event URL and default batch events URL domains.
        /// This won't override URL and batch URL that are provided in the settings.
        static let overrideDomain = "override_domain"
    }
    enum Defaults {
        /// The default collect URL
        static let url = "https://collect.tealiumiq.com/event"
        /// The default batch collect URL
        static let batchUrl = "https://collect.tealiumiq.com/bulk-event"
    }

    /// The URL to be used for the single event endpoint
    let url: URL
    /// The URL to be used for the batch events endpoint
    let batchUrl: URL
    /// The profile to override in the data layer events
    let overrideProfile: String?

    init?(configuration: DataObject, logger: LoggerProtocol?) {
        guard let url = Self.getURL(configuration: configuration),
              let batchUrl = Self.getBatchURL(configuration: configuration) else {
            logger?.error(category: LogCategory.collect,
                          "Unable to init settings due to invalid URL")
            return nil
        }
        self.url = url
        self.batchUrl = batchUrl
        overrideProfile = configuration.get(key: Keys.overrideProfile)
    }

    /// Extracts the event URL from the module settings
    static func getURL(configuration: DataObject) -> URL? {
        if let overrideUrl = configuration.get(key: Keys.url, as: String.self) {
            return URL(string: overrideUrl)
        }
        return overrideDomainURL(configuration: configuration, baseURL: Defaults.url)
    }

    /// Extracts the batch URL from the module settings
    static func getBatchURL(configuration: DataObject) -> URL? {
        if let overrideUrl = configuration.get(key: Keys.batchUrl, as: String.self) {
            return URL(string: overrideUrl)
        }
        return overrideDomainURL(configuration: configuration, baseURL: Defaults.batchUrl)
    }

    /// Applies the overrideDomain, if provided in the module settings, to a base URL
    static func overrideDomainURL(configuration: DataObject, baseURL: String) -> URL? {
        guard let url = URL(string: baseURL) else {
            return nil
        }
        guard let overrideDomain = configuration.get(key: Keys.overrideDomain, as: String.self),
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        components.host = overrideDomain
        return components.url ?? url
    }
}
