//
//  SetDataValuesTransformer.swift
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
    let networkHelper: any NetworkHelperProtocol
    let automaticDisposer = AutomaticDisposer()

    required init?(context: TealiumContext, moduleConfiguration: DataObject) {
        guard let jsContext = JSContext() else {
            return nil
        }
        self.jsContext = jsContext
        self.tracker = context.tracker
        self.dataLayer = context.dataLayer
        self.logger = context.logger
        self.networkHelper = context.networkHelper
        setupConsole()
        setupTrack()
        setupDataLayer()
        setupExpiry()
        setupNetworkHelper()
    }

    func applyTransformation(_ transformation: TransformationSettings, to dispatch: Dispatch, scope: DispatchScope, completion: @escaping (Dispatch?) -> Void) {
        let completion = SelfDestructingCompletion(completion: completion)
        guard let code = transformation.configuration.get(key: "js_code", as: String.self),
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
                        console.info("Track " + event + " suppressed to avoid recursion")
                    }
                    let track = _track
                    """ : ""
        let dropFunction = "let drop = function() { payload = undefined }"
        let jsPayload = jsContext.evaluateScript("""
            ((payload, scope) => {
                \(eventualOverrideTrack)
                \(dropFunction)
                ;(() => {
                    \(code)
                })()
                return JSON.stringify(payload)
            })(\(serializedPayload), "\(scope.rawValue)")
            """
        )
        guard let jsPayload, let dictionary = DataItem(stringValue: jsPayload.toString()).getDataDictionary() else {
            completion.complete(result: nil)
            return
        }
        completion.complete(result: Dispatch(payload: DataObject(dictionary: dictionary),
                                             id: dispatch.id,
                                             timestamp: dispatch.timestamp))
    }

    func convert(_ dataObject: DataObject) -> JSValue? {
        guard let jsValue = JSValue(newObjectIn: jsContext) else {
            return nil
        }
        dataObject.asDictionary()
            .forEach { key, value in
                jsValue.setObject(value, forKeyedSubscript: NSString(string: key))
            }
        return jsValue
    }
}

#endif
