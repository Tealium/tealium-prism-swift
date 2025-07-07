//
//  ConsentView.swift
//  Example_iOS
//
//  Created by Enrico Zannini on 26/06/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import TealiumSwift
import SwiftUI

struct ConsentView: View {
    let purposes = TealiumHelper.shared.cmp.allPurposes ?? [String]()
    @ObservedObject var cmp = TealiumHelper.shared.cmp
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Section {
                    Toggle("\(cmp.currentDecision?.decisionType ?? .explicit)".capitalized, isOn: bindingForDecisionType())
                    .tealiumButtonUI()
                } header: {
                    Text("Decision Type").font(.title)
                }
                Section {
                    ForEach(purposes, id: \.self) { purpose in
                        Toggle(purpose, isOn: bindingForPurpose(purpose))
                                .tealiumButtonUI()
                    }
                } header: {
                    Text("Purposes").font(.title)
                }
            }.frame(maxWidth: .infinity)
        }
    }

    func bindingForDecisionType() -> Binding<Bool> {
        Binding<Bool> {
            cmp.currentDecision?.decisionType == .explicit
        } set: { value in
            let decision = ConsentDecision(decisionType: value ? .explicit : .implicit, purposes: cmp.currentDecision?.purposes ?? [])
            cmp.applyConsent(decision)
        }
    }

    func bindingForPurpose(_ purpose: String) -> Binding<Bool> {
        Binding<Bool> {
            cmp.currentDecision?.purposes.contains(purpose) ?? false
        } set: { value in
            var purposes = cmp.currentDecision?.purposes ?? []
            if purposes.contains(purpose) {
                if !value {
                    purposes.removeAll { $0 == purpose }
                }
            } else {
                if value {
                    purposes.append(purpose)
                }
            }
            let decision = ConsentDecision(decisionType: cmp.currentDecision?.decisionType ?? .explicit, purposes: purposes)
            cmp.applyConsent(decision)
        }
    }
}

#Preview {
    ConsentView()
}
