//
//  ContentView.swift
//  Example_iOS
//
//  Created by Enrico Zannini on 15/10/24.
//  Copyright © 2024 Tealium, Inc. All rights reserved.
//

import Combine
import SwiftUI
import TealiumPrism

class ContentViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var tealium: Tealium? = TealiumHelper.shared.teal
    private let disposables: CompositeDisposable = Disposables.automatic()

    init() {
        // Follow the shared instance, so a Stop/Start from any window updates every window and the shut down instance isn't kept.
        TealiumHelper.shared.onTeal
            .subscribe { [weak self] teal in
                DispatchQueue.main.async {
                    self?.tealium = teal
                }
                self?.loadEmail(from: teal)
            }.addTo(disposables)
    }

    private func loadEmail(from teal: Tealium?) {
        teal?.dataLayer.get(key: "email", as: String.self).onSuccess { [weak self] email in
            guard let email else { return }
            DispatchQueue.main.async {
                self?.email = email
            }
        }
    }

    func toggleTealiumInstance() {
        if TealiumHelper.shared.teal != nil {
            TealiumHelper.shared.stopTealium()
        } else {
            TealiumHelper.shared.startTealium()
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
    @StateObject private var model = ContentViewModel()
    var teal: Tealium? {
        get {
            model.tealium
        }
        set {
            model.tealium = newValue
        }
    }
    @StateObject private var visitorIdModel = VisitorIdViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Button(teal != nil ? "Stop Tealium" : "Start Tealium") {
                        model.toggleTealiumInstance()
                    }
                    Group {
                        Group {
                            TealiumTextField($traceId,
                                             imageName: "person.fill",
                                             placeholder: "Enter Trace Id",
                                             applyButtonText: "Start Trace") {
                                TealiumHelper.shared.teal?.trace.join(id: self.traceId)
                            }
                            Button("Leave Trace") {
                                TealiumHelper.shared.teal?.trace.leave()
                            }
                            Button("Track View") {
                                TealiumHelper.shared.teal?.track("screen_view", data: nil)
                            }
                            Button("Track Event") {
                                TealiumHelper.shared.teal?.track("button_tapped",
                                                                 data: ["event_category": "EXAMPLE",
                                                                        "event_action": "tap",
                                                                        "event_label": "Track Event"])
                            }
                            Button("Flush Event Queue") {
                                TealiumHelper.shared.teal?.flushEventQueue()
                            }
                        }
                        Group {
                            ScrollableDetailView("Consent") {
                                ConsentView()
                            }
                            ScrollableDetailView("Login (VisitorId)") {
                                VStack {
                                    Text("Visitor ID: \(visitorIdModel.visitorId)")
                                        .font(.footnote)
                                    TealiumTextField($model.email,
                                                     placeholder: "Enter email",
                                                     applyButtonText: "Apply Email") {
                                        applyEmail()
                                    }
                                    Button("Erase Local History") {
                                        teal?.visitorId.eraseLocalHistory()
                                    }
                                    Button("Regenerate Visitor ID") {
                                        teal?.visitorId.regenerate()
                                    }
                                    Spacer()
                                }.padding()
                            }
                            ScrollableDetailView("DataLayer") {
                                if let teal {
                                    VStack(spacing: 16) {
                                        ScrollableDetailView("Add to DataLayer") {
                                            AddToDataLayerView(dataLayer: teal.dataLayer)
                                                .padding()
                                        }
                                        ScrollableDetailView("Remove from DataLayer") {
                                            RemoveFromDataLayerView(dataLayer: teal.dataLayer)
                                                .padding()
                                        }
                                    }.padding()
                                }
                            }
                            ScrollableDetailView("Context API") {
                                if let teal {
                                    ContextAPIView(viewModel: ContextAPIViewModel(contextAPI: teal.contextAPI()))
                                }
                            }
                        }
                    }.disabled(teal == nil)
                }
                .padding()
                .frame(maxWidth: .infinity) // Makes the scrollview expand to the full page, otherwise the title gets cut down during animation
            }.navigationTitle("Tealium Sample")
            .buttonStyle(TealiumButtonStyle())
        }
    }

    func applyEmail() {
        if model.email.isEmpty {
            teal?.dataLayer.remove(key: "email")
        } else {
            teal?.dataLayer.put(key: "email", value: model.email, expiry: .forever)
        }
    }
}

struct ScrollableDetailView<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content
    @Environment(\.isEnabled) var isEnabled

    init(_ title: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        NavigationLink(title) {
            ScrollView {
                Group {
                    if isEnabled {
                        content() // We create the content with potentially strong reference to dependencies (like Tealium)
                    } else {
                        // Replaces the content to avoid retaining the dependencies (Tealium) in the content.
                        Text("Tealium is stopped. Start it from the main screen to use this page.")
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                }
                .frame(maxWidth: .infinity) // Makes the scrollview expand to the full page, otherwise the title gets cut down during animation
                .navigationTitle(title)
            }
            .buttonStyle(TealiumButtonStyle())
            .disabled(!isEnabled) // Forward the link's state, since the destination doesn't inherit it, so nested pages are disabled too
        }
        .buttonStyle(TealiumButtonStyle())
    }
}

struct AddToDataLayerView: View {
    @State var key: String = ""
    @State var value: String = ""
    let dataLayer: DataLayer

    var body: some View {
        VStack(spacing: 16) {
            TealiumTextField($key, placeholder: "Enter key")
            TealiumTextField($value, placeholder: "Enter Value", applyButtonText: "Insert") {
                dataLayer.put(key: key, value: value)
            }
        }
    }
}

struct RemoveFromDataLayerView: View {
    @State var key: String = ""
    let dataLayer: DataLayer
    var body: some View {
        VStack(spacing: 16) {
            TealiumTextField($key, placeholder: "Enter key", applyButtonText: "Remove") {
                dataLayer.remove(key: key)
            }
        }
    }
}

#Preview {
    ContentView()
}
