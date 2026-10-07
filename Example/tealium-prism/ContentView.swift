//
//  ContentView.swift
//  Example_iOS
//
//  Created by Enrico Zannini on 15/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import SwiftUI
import TealiumPrism

class ContentViewModel: ObservableObject {
    @Published var email: String = ""
    init() {
        TealiumHelper.shared.teal?.dataLayer.get(key: "email", as: String.self).onSuccess { email in
            guard let email else { return }
            DispatchQueue.main.async {
                self.email = email
            }
        }
    }
}

class VisitorIdViewModel: ObservableObject {
    @Published var visitorId: String = ""
    private let disposables: CompositeDisposable = Disposables.automatic()

    init() {
        // Switch to the new instance's visitor ID on every Stop/Start, so the shut down instance isn't kept.
        TealiumHelper.shared.onTeal
            .flatMapLatest { teal -> Observable<String> in
                guard let teal else { return Observables.just("") }
                return Observables.create { observer in teal.visitorId.subscribe(observer) }
                    .compactMap { try? $0.get() }
            }
            .subscribe { [weak self] visitorId in
                DispatchQueue.main.async {
                    self?.visitorId = visitorId
                }
            }.addTo(disposables)
    }
}

struct ContentView: View {
    @State private var traceId: String = ""
    @State private var tealiumStarted: Bool = true
    @StateObject private var model = ContentViewModel()
    @StateObject private var visitorIdModel = VisitorIdViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    TealiumTextButton(title: tealiumStarted ? "Stop Tealium" : "Start Tealium") {
                        if tealiumStarted {
                            TealiumHelper.shared.stopTealium()
                        } else {
                            TealiumHelper.shared.startTealium()
                        }
                        self.tealiumStarted.toggle()
                    }
                    Group {
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
                                                                 data: ["event_category": "EXAMPLE",
                                                                        "event_action": "tap",
                                                                        "event_label": "Track Event"])
                            }
                            TealiumTextButton(title: "Flush Event Queue") {
                                TealiumHelper.shared.teal?.flushEventQueue()
                            }
                        }
                        Group {
                            NavigationLink("Consent") {
                                ConsentView()
                                    .navigationTitle("Consent")
                            }.tealiumButtonUI()
                            NavigationLink("Login (VisitorId)") {
                                ScrollView {
                                    VStack(spacing: 16) {
                                        Text("Visitor ID: \(visitorIdModel.visitorId)")
                                            .font(.footnote)
                                        TealiumTextField($model.email, placeholder: "Enter email") {
                                            applyEmail()
                                        }
                                        TealiumTextButton(title: "Erase Local History") {
                                            TealiumHelper.shared.teal?.visitorId.eraseLocalHistory()
                                        }
                                        TealiumTextButton(title: "Regenerate Visitor ID") {
                                            TealiumHelper.shared.teal?.visitorId.regenerate()
                                        }
                                    }
                                }.navigationTitle("Login")
                            }.tealiumButtonUI()
                            NavigationLink("DataLayer") {
                                if let teal = TealiumHelper.shared.teal {
                                    ScrollView {
                                        VStack(spacing: 16) {
                                            NavigationLink("Add to DataLayer") {
                                                AddToDataLayerView(dataLayer: teal.dataLayer)
                                                    .navigationTitle("Add to DataLayer")
                                            }.tealiumButtonUI()
                                            NavigationLink("Remove from DataLayer") {
                                                RemoveFromDataLayerView(dataLayer: teal.dataLayer)
                                                    .navigationTitle("Remove from DataLayer")
                                            }.tealiumButtonUI()

                                        }
                                    }.navigationTitle("DataLayer")
                                }
                            }.tealiumButtonUI()
                            NavigationLink("Context API") {
                                if let teal = TealiumHelper.shared.teal {
                                    ContextAPIView(viewModel: ContextAPIViewModel(contextAPI: teal.contextAPI()))
                                }
                            }.tealiumButtonUI()
                        }
                    }.disabled(!tealiumStarted)
                        .frame(maxWidth: .infinity)
                }
            }.navigationTitle("Tealium Sample")
        }
    }
    func applyEmail() {
        if model.email.isEmpty {
            TealiumHelper.shared.teal?.dataLayer.remove(key: "email")
        } else {
            TealiumHelper.shared.teal?.dataLayer.put(key: "email", value: model.email, expiry: .forever)
        }
    }
}

struct AddToDataLayerView: View {
    @State var key: String = ""
    @State var value: String = ""
    let dataLayer: DataLayer

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TealiumTextField($key, placeholder: "Enter key")
                TealiumTextField($value, placeholder: "Enter Value", applyButtonText: "Insert") {
                    dataLayer.put(key: key, value: value)
                }
            }
        }
    }
    
    
}

struct RemoveFromDataLayerView: View {
    @State var key: String = ""
    let dataLayer: DataLayer
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TealiumTextField($key, placeholder: "Enter key", applyButtonText: "Remove") {
                    dataLayer.remove(key: key)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
