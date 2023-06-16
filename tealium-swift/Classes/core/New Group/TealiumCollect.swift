//
//  TealiumCollect.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 06/12/22.
//

import Foundation

public class TealiumCollect: Dispatcher {
    public static var id: String = "collect"
    
    public required init(context: TealiumContext, moduleSettings: [String: Any]) {
        
    }
    
    public func updateSettings(_ settings: [String : Any]) -> Self? {
        print("Collect settings")
        return self
    }
    
    public func dispatch(_ data: [TealiumDispatch]) {
        guard let url = URL(string: "https://collect.tealiumiq.com/event/") else {
            return
        }
        print(data)
        for event in data {
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"
            if let jsonString = try? event.eventData.asDictionary().toJSONString() {
                request.httpBody = jsonString.data(using: .utf8)
            }
            _ = NetworkClient.default.sendRequest(request) { result in
                print("URL Request \(request) completed with \(result)")
            }
            
        }
    }
}

extension TealiumCollect {
    struct Settings {
        enum Keys {
            static let overrideUrl = "override_url"
            static let overrideBatchUrl = "override_batch_url"
            static let overrideProfile = "override_profile"
            static let overrideDomain = "override_domain"
        }
        
        var options: [String: Any]
        /// Overrides the default Collect endpoint URL￼.
        /// NOTE: the Batch URL must be overridden separately. See `overrideCollectBatchURL`.
        /// The full URL must be provided, including protocol and path.
        /// If using Tealium with a CNAMEd domain, the format would be: https://collect.mydomain.com/event  (the path MUST be `/event`).
        /// If using your own custom endpoint, the URL can be any valid URL.
        var overrideURL: String? {
            get {
                options[Keys.overrideUrl] as? String
            }
            set {
                guard let newValue = newValue else {
                    return
                }
                options[Keys.overrideUrl] = newValue
            }
        }

        /// Overrides the default Collect endpoint URL￼.
        /// The full URL must be provided, including protocol and path.
        /// If using Tealium with a CNAMEd domain, the format would be: https://collect.mydomain.com/bulk-event (the path MUST be `/bulk-event`).
        /// If using your own custom endpoint, the URL can be any valid URL. Your endpoint must be prepared to accept batched events in Tealium's proprietary gzipped format.
        var overrideBatchURL: String? {
            get {
                options[Keys.overrideBatchUrl] as? String
            }
            set {
                guard let newValue = newValue else {
                    return
                }
                options[Keys.overrideBatchUrl] = newValue
            }
        }

        /// Overrides the default Collect endpoint profile￼.
        var overrideProfile: String? {
            get {
                options[Keys.overrideProfile] as? String
            }
            set {
                options[Keys.overrideProfile] = newValue
            }
        }

        /// Overrides the default Collect domain only.
        /// Only the hostname should be provided, excluding the protocol, e.g. `my-company.com`
        var overrideDomain: String? {
            get {
                options[Keys.overrideDomain] as? String
            }
            set {
                options[Keys.overrideDomain] = newValue
            }
        }
    }
    
    
}
