//
//  ConsentView.swift
//  Example_iOS
//
//  Created by Enrico Zannini on 26/06/25.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import TealiumPrism
import SwiftUI

struct ConsentView: View {
    let purposes = CustomCMP.Purposes.allCases.map { $0.rawValue }
    @State var decision: ConsentDecision = TealiumHelper.shared.cmp.currentDecision
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @State private var showAlert: Bool = false

    var body: some View {
        ScrollView {
            content
                .onAppear {
                    decision = TealiumHelper.shared.cmp.currentDecision
                }
        }
        .navigationBarBackButtonHidden(true)
        #if os(tvOS)
        // The remote's Menu button pops the navigation even with the back button hidden
        .onExitCommand {
            dismissIfNoChanges()
        }
        #endif
        .toolbar {
            ToolbarItem(placement: cancellationPlacement) {
                Button(action: {
                    dismissIfNoChanges()
                }){
                    Label("Back", systemImage: "chevron.left")
                        .labelStyle(.iconOnly)
                }
            }
            ToolbarItem(placement: confirmationPlacement) {
                Button {
                    save()
                } label: {
                    Text("Save").bold()
                }
            }
        }.buttonStyle(.automatic)
    }

    var cancellationPlacement: ToolbarItemPlacement  {
        #if os(watchOS)
        .cancellationAction
        #else
        .navigation
        #endif
    }

    var confirmationPlacement: ToolbarItemPlacement  {
        .confirmationAction
    }

    var content: some View {
        VStack(spacing: 16) {
            Section {
                Group {
                    Toggle(ConsentDecision.DecisionType.explicit.rawValue.capitalized, isOn: bindingForDecisionType(.explicit))
                    Toggle(ConsentDecision.DecisionType.implicit.rawValue.capitalized, isOn: bindingForDecisionType(.implicit))
                }.tealiumButtonUI()
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
        }
        .frame(maxWidth: .infinity)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Unsaved consent changes"),
                message: Text("Do you want to discard them?"),
                primaryButton:  .default(Text("Continue Editing"), action: { }),
                secondaryButton: .destructive(Text("Discard"), action: {
                    self.presentationMode.wrappedValue.dismiss()
                    decision = TealiumHelper.shared.cmp.currentDecision
                })
            )
        }
    }

    func dismissIfNoChanges() {
        if decision != TealiumHelper.shared.cmp.currentDecision {
            showAlert = true
        } else {
            presentationMode.wrappedValue.dismiss()
        }
    }

    func save() {
        TealiumHelper.shared.cmp.applyConsent(decision)
        presentationMode.wrappedValue.dismiss()
    }

    func bindingForDecisionType(_ decisionType: ConsentDecision.DecisionType) -> Binding<Bool> {
        Binding<Bool> {
            decision.decisionType == decisionType
        } set: { value in
            guard !value else {
                decision = ConsentDecision(decisionType: decisionType,
                                           purposes: decision.purposes)
                return
            }
            let newType = switch decisionType {
            case .explicit:
                ConsentDecision.DecisionType.implicit
            case .implicit:
                ConsentDecision.DecisionType.explicit
            }
            decision = ConsentDecision(decisionType: newType,
                                       purposes: decision.purposes)
        }
    }

    func bindingForPurpose(_ purpose: String) -> Binding<Bool> {
        Binding<Bool> {
            decision.purposes.contains(purpose) == true
        } set: { value in
            var purposes = decision.purposes
            if purposes.contains(purpose) {
                if !value {
                    purposes.remove(purpose)
                }
            } else {
                if value {
                    purposes.insert(purpose)
                }
            }
            decision = ConsentDecision(decisionType: decision.decisionType,
                                       purposes: purposes)
        }
    }
}

#Preview {
    ConsentView()
}
