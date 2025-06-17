//
//  CMPConfigurationSelector.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 21/05/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A utility class that can select the right `ConsentConfiguration` based on the `ConsentSettings` and `CMPAdapter`.
 */
class CMPConfigurationSelector {
    let cmpAdapter: CMPAdapter
    let configuration: ObservableState<ConsentConfiguration?>
    let consentInspector: ObservableState<ConsentInspector?>
    let disposer = AutomaticDisposer()
    init(consentSettings: ObservableState<ConsentSettings?>, cmpAdapter: CMPAdapter) {
        self.cmpAdapter = cmpAdapter
        let configuration: ObservableState<ConsentConfiguration?> = consentSettings.mapState { settings in
            guard let configuration = settings?.configurations[cmpAdapter.id] else {
                return nil
            }
            return configuration
        }
        self.configuration = configuration
        let inspectorState = StateSubject<ConsentInspector?>(nil)
        configuration.combineLatest(cmpAdapter.consentDecision)
            .compactMap { configuration, decision in
                guard let configuration, let decision else { return nil }
                return ConsentInspector(configuration: configuration,
                                        decision: decision,
                                        allPurposes: cmpAdapter.allPurposes)
            }.subscribe(inspectorState)
            .addTo(disposer)
        self.consentInspector = inspectorState.toStatefulObservable()
    }
}
