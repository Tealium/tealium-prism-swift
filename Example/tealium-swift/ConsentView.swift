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
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    if decision != TealiumHelper.shared.cmp.currentDecision {
                        showAlert = true
                    } else {
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }){
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    save()
                } label: {
                    Text("Save").bold()
                }
            }
            
        }
    }

    var content: some View {
        VStack(spacing: 16) {
            Section {
                Toggle("\(decision.decisionType)".capitalized, isOn: bindingForDecisionType())
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

    func save() {
        TealiumHelper.shared.cmp.applyConsent(decision)
        presentationMode.wrappedValue.dismiss()
    }

    func bindingForDecisionType() -> Binding<Bool> {
        Binding<Bool> {
            decision.decisionType == .explicit
        } set: { value in
            decision = ConsentDecision(decisionType: value ? .explicit : .implicit,
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
