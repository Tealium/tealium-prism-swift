//
//  TealiumCollectSettings.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 14/11/23.
//  Copyright © 2023 Tealium, Inc. All rights reserved.
//

import Foundation

/// The settings used by the `TealiumCollect` module.
struct TealiumCollectSettings {
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

    init?(moduleSettings: [String: Any], logger: TealiumLoggerProvider? = nil) {
        guard let url = Self.getURL(moduleSettings: moduleSettings),
              let batchUrl = Self.getBatchURL(moduleSettings: moduleSettings) else {
            logger?.error?.log(category: LogCategory.collect,
                               message: "Unable to init settings due to invalid URL")
            return nil
        }
        self.url = url
        self.batchUrl = batchUrl
        overrideProfile = moduleSettings[Keys.overrideProfile] as? String
    }

    /// Extracts the event URL from the module settings
    static func getURL(moduleSettings: [String: Any]) -> URL? {
        if let overrideUrl = moduleSettings[Keys.url] as? String {
            return URL(string: overrideUrl)
        }
        return overrideDomainURL(moduleSettings: moduleSettings, baseURL: Defaults.url)
    }

    /// Extracts the batch URL from the module settings
    static func getBatchURL(moduleSettings: [String: Any]) -> URL? {
        if let overrideUrl = moduleSettings[Keys.batchUrl] as? String {
            return URL(string: overrideUrl)
        }
        return overrideDomainURL(moduleSettings: moduleSettings, baseURL: Defaults.batchUrl)
    }

    /// Applies the overrideDomain, if provided in the module settings, to a base URL
    static func overrideDomainURL(moduleSettings: [String: Any], baseURL: String) -> URL? {
        guard let url = URL(string: baseURL) else {
            return nil
        }
        guard let overrideDomain = moduleSettings[Keys.overrideDomain] as? String,
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        components.host = overrideDomain
        return components.url ?? url
    }
}
