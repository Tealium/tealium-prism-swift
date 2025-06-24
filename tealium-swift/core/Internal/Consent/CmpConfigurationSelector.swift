//
//  CmpConfigurationSelector.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 21/05/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import Foundation

/**
 * A utility class that can select the right `ConsentConfiguration` based on the `ConsentSettings` and `CmpAdapter`.
 */
class CmpConfigurationSelector {
    let cmpAdapter: CmpAdapter
    let configuration: ObservableState<ConsentConfiguration?>
    let consentInspector: ObservableState<ConsentInspector?>
    let disposer = AutomaticDisposer()
    init(consentSettings: ObservableState<ConsentSettings?>, cmpAdapter: CmpAdapter, queue: TealiumQueue = .worker) {
        self.cmpAdapter = cmpAdapter
        let configuration = consentSettings.mapState { $0?.configurations[cmpAdapter.id] }
        self.configuration = configuration
        let inspectorState = StateSubject<ConsentInspector?>(nil)
        configuration.combineLatest(cmpAdapter.consentDecision.observeOn(queue))
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
