//
//  JavaScriptTransformer.swift
//  tealium-prism
//
//  Created by Enrico Zannini on 16/12/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

#if !os(watchOS)
import Foundation
import JavaScriptCore
#if jstransformer
import TealiumPrismCore
#endif

extension LogCategory {
    static let javaScriptTransformer = "JavaScriptTransformer"
}

class JavaScriptTransformer: Transformer, BasicModule {
    let id: String = Modules.Types.javaScriptTransformer
    let version: String = TealiumConstants.libraryVersion
    let jsContext: JSContext
    let tracker: Tracker
    let dataLayer: any DataStore
    let logger: LoggerProtocol?
    convenience required init?(context: TealiumContext, moduleConfiguration: DataObject) {
        self.init(tracker: context.tracker,
                  dataLayer: context.dataLayer,
                  logger: context.logger)
    }

    init?(tracker: Tracker,
          dataLayer: any DataStore,
          logger: LoggerProtocol?) {
        guard let jsContext = JSContext() else {
            return nil
        }
        self.jsContext = jsContext
        self.tracker = tracker
        self.dataLayer = dataLayer
        self.logger = logger
        setupConsole()
        setupTrack()
        setupDataLayer()
        setupExpiry()
        // setupNetworkHelper() — re-enable when async/await or promises are properly supported
    }

    func applyTransformation(_ transformation: TransformationSettings, to dispatch: Dispatch, scope: DispatchScope, completion: @escaping (Dispatch?) -> Void) {
        let completion = SelfDestructingCompletion(completion: completion)
        guard let code = transformation.configuration.get(key: "js_code", as: String.self),
              !StringUtils.isBlank(code),
              let serializedPayload = try? dispatch.payload.serialize() else {
            completion.complete(result: dispatch)
            return
        }
        jsContext.exceptionHandler = { [logger] _, value in
            guard let error = value?.toString() else {
                return
            }
            logger?.error(category: LogCategory.javaScriptTransformer, "JS execution error: \(error)")
            var dispatch = dispatch
            dispatch.enrich(data: ["js_error": error])
            completion.complete(result: dispatch)
        }

        let dispatchWasTrackedByJS = dispatch.payload.get(key: "js_tracking", as: Bool.self) ?? false
        let eventualOverrideTrack = dispatchWasTrackedByJS ? """
                    let _track = function(event, type, payload) {
                        console.warn("Track " + event + " suppressed to avoid recursion")
                    }
                    let track = _track
                    """ : ""
        let dropFunction = "let drop = function() { payload = undefined }"
        jsContext.setObject(scope.rawValue, forKeyedSubscript: "scope" as NSString)
        let jsPayload = jsContext.evaluateScript("""
            ((payload, scope) => {
                \(eventualOverrideTrack)
                \(dropFunction)
                ;(() => {
                    \(code)
                })()
                return JSON.stringify(payload)
            })(\(serializedPayload), scope)
            """
        )
        guard let jsPayload,
              let dataObject = try? DataObject(jsonString: jsPayload.toString()) else {
            completion.complete(result: nil)
            return
        }
        var updatedDispatch = dispatch
        updatedDispatch.replace(payload: dataObject)
        completion.complete(result: updatedDispatch)
    }
}

#endif
