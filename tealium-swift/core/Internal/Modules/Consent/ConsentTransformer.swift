//
//  ConsentTransformer.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 10/07/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Foundation

class ConsentTransformer: Transformer {
    let id: String = "ConsentTransformer"
    let settings: ObservableState<ConsentSettings>
    private let automaticDisposer = AutomaticDisposer()
    init(consentSettings: ObservableState<ConsentSettings>) {
        self.settings = consentSettings
    }

    func applyTransformation(_ id: String, to dispatch: TealiumDispatch, scope: DispatchScope, completion: @escaping (TealiumDispatch?) -> Void) {
        guard case let DispatchScope.dispatcher(dispatcherId) = scope,
              let requiredPurposes = settings.value.dispatcherToPurposes[dispatcherId],
              !requiredPurposes.isEmpty,
              self.dispatch(dispatch, matchesPurposes: requiredPurposes) else {
            completion(nil)
            return
        }
        completion(dispatch)
    }

    func dispatch(_ dispatch: TealiumDispatch, matchesPurposes requiredPurposes: [String]) -> Bool {
        guard let consentedPurposes = dispatch.eventData.getArray(key: "purposes_with_consent_all", of: String.self)?.compactMap({ $0 }) else {
            return false
        }
        return requiredPurposes.allSatisfy(consentedPurposes.contains)
    }
}
