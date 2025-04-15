//
//  TealiumDeepLink.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 12/12/22.
//  Copyright © 2022 Tealium, Inc. All rights reserved.
//

import Foundation

public class TealiumDeepLink {
    typealias Module = DeepLinkModule
    private let moduleProxy: ModuleProxy<Module>

    init(moduleProxy: ModuleProxy<Module>) {
        self.moduleProxy = moduleProxy
    }

    private func getModule(completion: @escaping (Module?) -> Void) {
        moduleProxy.getModule(completion: completion)
    }
    public func handle(link: URL, referrer: Referrer? = nil) {
        getModule { deepLinkModule in
            deepLinkModule?.handle(link: link, referrer: referrer)
        }
    }
}

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

class DeepLinkModule: TealiumBasicModule {
    let version: String = TealiumConstants.libraryVersion
    static let id: String = "Deeplink"

    let context: TealiumContext
    required init(context: TealiumContext, moduleConfiguration: DataObject) {
        self.context = context
    }

    func handle(link: URL, referrer: Referrer? = nil) {
        let queryItems = URLComponents(string: link.absoluteString)?.queryItems

        if let queryItems = queryItems,
           let traceId = self.extractTraceId(from: queryItems) {
            // Kill visitor session to trigger session end events
            // Session can be killed without needing to leave the trace
            if link.query?.contains(TealiumKey.killVisitorSession) == true {
                self.killTraceVisitorSession()
            }
            // Leave the trace and return - do not rejoin trace
            if link.query?.contains(TealiumKey.leaveTraceQueryParam) == true {
                self.leaveTrace()
                return
            }
            // Call join trace so long as this wasn't a leave trace request.
            self.joinTrace(id: traceId)
        }
//        self.zz_internal_modulesManager?.config.deepLinkTrackingEnabled == true
        guard let dataLayer = self.dataLayer else { return }
        let deeplinkTrackingEnabled = true
        if deeplinkTrackingEnabled {
            // TODO: replace the whole thing with custom storage (since deeplink is module with its own storage)
            let oldQueryParamKeys: [String] = dataLayer.getAll().keys.filter { $0.starts(with: TealiumDataKey.deepLinkQueryPrefix) }
            try? dataLayer.remove(keys: oldQueryParamKeys + [TealiumDataKey.deepLinkReferrerUrl, TealiumDataKey.deepLinkReferrerApp])
            switch referrer {
            case .url(let url):
                try? dataLayer.put(key: TealiumDataKey.deepLinkReferrerUrl, value: url.absoluteString, expiry: .session)
            case .app(let identifier):
                try? dataLayer.put(key: TealiumDataKey.deepLinkReferrerApp, value: identifier, expiry: .session)
            default:
                break
            }
            try? dataLayer.put(key: TealiumDataKey.deepLinkURL, value: link.absoluteString, expiry: .session)
            queryItems?.forEach {
                guard let value = $0.value else {
                    return
                }
                try? dataLayer.put(key: "\(TealiumDataKey.deepLinkQueryPrefix)_\($0.name)", value: value, expiry: .session)
            }
        }
    }

    fileprivate func extractTraceId(from queryItems: [URLQueryItem]) -> String? {
        for item in queryItems {
            if item.name == TealiumKey.traceIdQueryParam, let value = item.value {
                return value
            }
        }
        return nil
    }

    var trace: TraceManagerModule? {
        self.context.modulesManager.getModule()
    }

    var dataLayer: DataLayerModule? {
        self.context.modulesManager.getModule()
    }

    /// Sends a request to modules to initiate a trace with a specific Trace ID￼.
    ///
    /// - Parameter id: String representing the Trace ID
    func joinTrace(id: String) {
        try? trace?.join(id: id)
    }

    /// Sends a request to modules to leave a trace, and end the trace session￼.
    ///
    func leaveTrace() {
        try? trace?.leave()
    }

    /// Ends the current visitor session. Trace remains active, but visitor session is terminated.
    func killTraceVisitorSession(completion: ErrorHandlingCompletion? = nil) {
//        trace?.killVisitorSession(completion: completion)
    }

}
