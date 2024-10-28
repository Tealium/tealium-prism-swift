//
//  ContentView.swift
//  Example_iOS
//
//  Created by Enrico Zannini on 15/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import SwiftUI

class ContentViewModel: ObservableObject {
    @Published var email: String = ""
    init() {
        TealiumHelper.shared.teal?.dataLayer.get(key: "email", completion: { item in
            guard let email = item?.get(as: String.self) else { return }
            DispatchQueue.main.async {
                self.email = email
            }
        })
    }
}

struct ContentView: View {
    @State private var traceId: String = ""
    @State private var tealiumStarted: Bool = true
    @StateObject private var model = ContentViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    Group {
                        TealiumTextField($traceId, imageName: "person.fill", placeholder: "Enter Trace Id")
                        TealiumTextButton(title: "Start Trace") {
                            TealiumHelper.shared.teal?.trace.join(id: self.traceId)
                        }
                        TealiumTextButton(title: "Leave Trace") {
                            TealiumHelper.shared.teal?.trace.leave()
                        }
                        TealiumTextButton(title: "Track View") {
                            TealiumHelper.shared.teal?.track("screen_view", data: nil)
                        }
                        TealiumTextButton(title: "Track Event") {
                            TealiumHelper.shared.teal?.track("button_tapped",
                                                             data: ["event_category": "example",
                                                                    "event_action": "tap",
                                                                    "event_label": "Track Event"])
                        }
                        TealiumTextButton(title: tealiumStarted ? "Stop Tealium" : "Start Tealium") {
                            if tealiumStarted {
                                TealiumHelper.shared.stopTealium()
                            } else {
                                TealiumHelper.shared.startTealium()
                            }
                            self.tealiumStarted.toggle()
                        }
                    }
                    Group {
                        TealiumTextField($model.email, placeholder: "Enter email") {
                            applyEmail()
                        }
                        TealiumTextButton(title: "Clear Stored Visitor IDs") {
                            TealiumHelper.shared.teal?.clearStoredVisitorIds()
                        }
                        TealiumTextButton(title: "Reset Visitor ID") {
                            TealiumHelper.shared.teal?.resetVisitorId()
                        }
                    }
                }
            }
        }
    }
    func applyEmail() {
        if model.email.isEmpty {
            TealiumHelper.shared.teal?.dataLayer.delete(key: "email")
        } else {
            TealiumHelper.shared.teal?.dataLayer.add(key: "email", value: model.email, expiry: .forever)
        }
    }
}

#Preview {
    ContentView()
}
