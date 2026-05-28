//
//  JavaScriptTransformer+JSContextSetup.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 18/12/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

#if !os(watchOS)
import Foundation
import JavaScriptCore
#if jstransformer
import TealiumPrismCore
#endif

extension JavaScriptTransformer {

    func setupConsole() {
        guard let logger, let console: JSValue = jsContext["console"] else {
            return
        }
        func createHandler(level: LogLevel) -> (@convention(block) (String) -> Void) {
            { [logger] string in
                logger.log(level: level, category: LogCategory.javaScriptTransformer, string)
            }
        }
        console["debug"] = createHandler(level: .trace)
        console["log"] = createHandler(level: .debug)
        console["info"] = createHandler(level: .info)
        console["warn"] = createHandler(level: .warn)
        console["error"] = createHandler(level: .error)
    }

    func setupTrack() {
        let track: @convention(block) (
            _ event: String,
            _ eventType: String,
            _ stringifiedPayload: String
        ) -> Void = { [tracker] event, type, payload in
            var dataObject = (try? DataObject(jsonString: payload)) ?? [:]
            dataObject.set(true, key: "js_tracking")
            tracker.track(Dispatch(name: event,
                                   type: DispatchType(rawValue: type) ?? .event,
                                   data: dataObject),
                          source: .module(JavaScriptTransformer.self))
        }
        jsContext["_track"] = track
        jsContext.evaluateScript(
            """
            let track = function(event, type, payload) {
                if (typeof type == "object" && type !== null && !Array.isArray(type)) {
                    // type is actually a payload -> track(event, payload)
                    _track(event, null, JSON.stringify(type))
                } else {
                    _track(event, type, JSON.stringify(payload))
                }
            }
            """
        )
    }

// TODO: Re-implement network support once async/await or promises are properly supported for async JS transformations
//    func setupNetworkHelper() {
//        guard let jsNetwork = JSValue(newObjectIn: jsContext) else { return }
//        func complete(result: NetworkResult, completion: JSValue) {
//            guard completion.isObject else { return }
//            switch result {
//            case let .success(response):
//                guard let json = try? JSONSerialization.jsonObject(with: response.data) else {
//                    guard let string = String(data: response.data, encoding: .utf8) else {
//                        completion.call(withArguments: [
//                            response.urlResponse.statusCode, "undefined", response.urlResponse.allHeaderFields
//                        ])
//                        return
//                    }
//                    completion.call(withArguments: [
//                        response.urlResponse.statusCode, string, response.urlResponse.allHeaderFields
//                    ])
//                    return
//                }
//                completion.call(withArguments: [
//                    response.urlResponse.statusCode, json, response.urlResponse.allHeaderFields
//                ])
//            case let .failure(error):
//                completion.call(withArguments: [error.localizedDescription])
//            }
//        }
//        let get: @convention(block) (_ url: String, _ completion: JSValue) -> Void = { [weak self, networkHelper] url, completion in
//            guard let self else { return }
//            networkHelper.get(url: url) { result in
//                complete(result: result, completion: completion)
//            }.addTo(self.automaticDisposer)
//        }
//        jsNetwork["get"] = get
//        let _post: @convention(block) (
//            _ url: String,
//            _ stringifiedPayload: String,
//            _ completion: JSValue
//        ) -> Void = { [weak self, networkHelper] url, payload, completion in
//            guard let self else { return }
//            let body = (try? DataObject(jsonString: payload)) ?? [:]
//            networkHelper.post(url: url, body: body) { result in
//                complete(result: result, completion: completion)
//            }.addTo(self.automaticDisposer)
//        }
//        jsNetwork["_post"] = _post
//        jsContext["network"] = jsNetwork
//        jsContext.evaluateScript("""
//        network.post = function(url, payload, completion) {
//            this._post(url, JSON.stringify(payload), completion)
//        }
//        """)
//    }

    func setupDataLayer() {
        guard let jsDataLayer = JSValue(newObjectIn: jsContext) else {
            return
        }
        let get: @convention(block) (_ key: String) -> Any = { [dataLayer] key in
            dataLayer.getDataItem(key: key)?.toDataInput() ?? NSNull()
        }
        jsDataLayer["get"] = get
        let getAll: @convention(block) () -> Any = { [dataLayer] in
            dataLayer.getAll().toDataInput()
        }
        jsDataLayer["getAll"] = getAll
        let put: @convention(block) (_ key: String, _ value: Any, _ expiryMilliseconds: Int) -> Void = { [dataLayer] key, value, expiryMilliseconds in
            guard let item = try? DataItem(jsonValue: value) else {
                return
            }
            let expiry = if expiryMilliseconds == 0 {
                Expiry.forever
            } else {
                Expiry(timestamp: Int64(expiryMilliseconds))
            }
            try? dataLayer.edit()
                .put(key: key,
                     value: item.toDataInput(),
                     expiry: expiry)
                .commit()
        }
        jsDataLayer["put"] = put
        let remove: @convention(block) (_ key: String) -> Void = { [dataLayer] key in
            try? dataLayer.edit().remove(key: key).commit()
        }
        jsDataLayer["remove"] = remove
        let clear: @convention(block) () -> Void = { [dataLayer] in
            try? dataLayer.edit().clear().commit()
        }
        jsDataLayer["clear"] = clear
        jsContext["dataLayer"] = jsDataLayer
    }

    func setupExpiry() {
        guard let expiry = JSValue(newObjectIn: jsContext) else {
            return
        }
        expiry["forever"] = Expiry.forever.expiryTime()
        expiry["session"] = Expiry.session.expiryTime()
        expiry["untilRestart"] = Expiry.untilRestart.expiryTime()
        jsContext["Expiry"] = expiry
    }
}
#endif
