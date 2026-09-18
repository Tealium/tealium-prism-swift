//
//  ContextAPIView.swift
//  Example_iOS
//
//  Created by Sebastian Krajna on 6/11/2025.
//  Copyright © 2025 Tealium, Inc. All rights reserved.
//

import SwiftUI
import TealiumPrism

class ContextAPIViewModel: ObservableObject {
    @Published var engineId: String = ""
    @Published var engineResponse: EngineResponse?
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    private let contextAPI: ContextAPI
    private let userDefaults = UserDefaults.standard
    private let engineIdKey = "context_api_engine_id"
    
    init(contextAPI: ContextAPI) {
        self.contextAPI = contextAPI
        loadSavedEngineId()
    }
    
    func loadSavedEngineId() {
        engineId = userDefaults.string(forKey: engineIdKey) ?? ""
    }
    
    func saveEngineId() {
        userDefaults.set(engineId, forKey: engineIdKey)
    }
    
    func fetchEngineResponse() {
        isLoading = true
        errorMessage = nil
        engineResponse = nil
        
        saveEngineId()
        
        contextAPI.fetchEngineResponse(engineID: engineId).subscribe { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                switch result {
                case .success(let response):
                    self?.engineResponse = response
                case .failure(let error):
                    self?.errorMessage = "Error: \(error.localizedDescription)"
                }
            }
        }
    }
}

struct ContextAPIView: View {
    @StateObject private var viewModel: ContextAPIViewModel

    init(viewModel: ContextAPIViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TealiumTextField($viewModel.engineId, 
                                placeholder: "Enter Engine ID")
                TealiumTextButton(title: "Fetch Engine Response") {
                    viewModel.saveEngineId()
                    viewModel.fetchEngineResponse()
                }
                .disabled(viewModel.isLoading)
                
                if viewModel.isLoading {
                    ProgressView()
                        .padding()
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                if let response = viewModel.engineResponse {
                    ContextAPIResponseView(response: response)
                }
            }
            .padding()
        }
        .navigationTitle("Context API")
    }
}

struct ContextAPIResponseView: View {
    let response: EngineResponse
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let audiences = response.audiences, !audiences.isEmpty {
                ContextAPIDataRow(label: "Audiences", value: formatArray(audiences))
            }
            
            if let badges = response.badges, !badges.isEmpty {
                ContextAPIDataRow(label: "Badges", value: formatArray(badges))
            }
            
            if let properties = response.properties, !properties.isEmpty {
                ContextAPIDataRow(label: "Properties", value: formatDictionary(properties))
            }
            
            if let metrics = response.metrics, !metrics.isEmpty {
                ContextAPIDataRow(label: "Metrics", value: formatDictionary(metrics))
            }
            
            if let flags = response.flags, !flags.isEmpty {
                ContextAPIDataRow(label: "Flags", value: formatDictionary(flags))
            }
            
            if let dates = response.dates, !dates.isEmpty {
                ContextAPIDataRow(label: "Dates", value: formatDates(dates))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatArray(_ array: [String]) -> String {
        array.map { $0 }.joined(separator: "\n")
    }

    private func formatDictionary<T>(_ dict: [String: T]) -> String {
        formatArray(dict.map { "\($0.key): \($0.value)" })
    }
    
    private func formatDates(_ dates: [String: Int64]) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        return formatDictionary(dates.mapValues { timestamp in
            // Format Unix timestamp (milliseconds) as date
            let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0)
            return formatter.string(from: date)
        })
    }
}

struct ContextAPIDataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.headline)
                .foregroundColor(.tealBlue)
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
                .padding(.leading, 8)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    NavigationView {
        if let teal = TealiumHelper.shared.teal {
            ContextAPIView(viewModel: ContextAPIViewModel(contextAPI: teal.contextAPI()))
        }
    }
}

