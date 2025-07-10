//
//  PointsManagementView.swift
//  TravelConsultingApp
//
//  Created by Nick Christus on 6/6/25.
//


import SwiftUI

struct PointsManagementView: View {
    @StateObject private var viewModel = PointsManagementViewModel()
    @State private var selectedProvider = ""
    @State private var pointsAmount = ""
    @State private var selectedType: PointsType = .creditCard
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    LoadingView(message: "Loading your points...")
                } else if viewModel.errorMessage != nil {
                    ErrorView(
                        title: "Unable to Load Points",
                        message: viewModel.errorMessage ?? "Unknown error occurred",
                        retryAction: {
                            viewModel.clearError()
                            viewModel.loadPoints()
                        }
                    )
                } else if viewModel.hasNoPoints {
                    VStack {
                        EmptyStateView(
                            icon: "creditcard.and.123",
                            title: "Track Your Points",
                            subtitle: "Add your credit card, hotel, and airline points to help us find the best deals for your trips.",
                            actionTitle: nil,
                            action: nil
                        )
                        Spacer()
                        addPointsSection
                    }
                } else {
                    pointsForm
                }
            }
            .navigationTitle("My Points")
            .onAppear {
                viewModel.loadPoints()
            }
        }
    }
    
    private var addPointsSection: some View {
        VStack(spacing: 16) {
            Picker("Points Type", selection: $selectedType) {
                ForEach(PointsType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.segmented)
            
            Picker("Provider", selection: $selectedProvider) {
                Text("Select Provider").tag("")
                ForEach(providersForType(selectedType), id: \.self) { provider in
                    Text(provider).tag(provider)
                }
            }
            
            TextField("Points Amount", text: $pointsAmount)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            PrimaryButton(
                title: "Add Points",
                icon: "plus.circle.fill",
                isLoading: false,
                isEnabled: !selectedProvider.isEmpty && !pointsAmount.isEmpty
            ) {
                addPoints()
            }
        }
        .padding()
    }
    
    private var pointsForm: some View {
        Form {
            Section(header: Text("Add Points")) {
                Picker("Points Type", selection: $selectedType) {
                    ForEach(PointsType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                
                Picker("Provider", selection: $selectedProvider) {
                    Text("Select Provider").tag("")
                    ForEach(providersForType(selectedType), id: \.self) { provider in
                        Text(provider).tag(provider)
                    }
                }
                
                TextField("Points Amount", text: $pointsAmount)
                    .keyboardType(.numberPad)
                
                PrimaryButton(
                    title: "Add Points",
                    icon: "plus.circle.fill",
                    isLoading: false,
                    isEnabled: !selectedProvider.isEmpty && !pointsAmount.isEmpty
                ) {
                    addPoints()
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if !viewModel.creditCardPoints.isEmpty {
                Section(header: Text("Credit Card Points")) {
                    ForEach(Array(viewModel.creditCardPoints.keys.sorted()), id: \.self) { provider in
                        HStack {
                            Text(provider)
                            Spacer()
                            Text("\(viewModel.creditCardPoints[provider] ?? 0) pts")
                                .foregroundColor(.secondary)
                        }
                    }
                    .onDelete { indexSet in
                        deletePoints(from: .creditCard, at: indexSet)
                    }
                }
            }
            
            if !viewModel.hotelPoints.isEmpty {
                Section(header: Text("Hotel Points")) {
                    ForEach(Array(viewModel.hotelPoints.keys.sorted()), id: \.self) { provider in
                        HStack {
                            Text(provider)
                            Spacer()
                            Text("\(viewModel.hotelPoints[provider] ?? 0) pts")
                                .foregroundColor(.secondary)
                        }
                    }
                    .onDelete { indexSet in
                        deletePoints(from: .hotel, at: indexSet)
                    }
                }
            }
            
            if !viewModel.airlinePoints.isEmpty {
                Section(header: Text("Airline Points")) {
                    ForEach(Array(viewModel.airlinePoints.keys.sorted()), id: \.self) { provider in
                        HStack {
                            Text(provider)
                            Spacer()
                            Text("\(viewModel.airlinePoints[provider] ?? 0) pts")
                                .foregroundColor(.secondary)
                        }
                    }
                    .onDelete { indexSet in
                        deletePoints(from: .airline, at: indexSet)
                    }
                }
            }
        }
    }
    
    private func providersForType(_ type: PointsType) -> [String] {
        switch type {
        case .creditCard:
            return PointsProvider.creditCardProviders
        case .hotel:
            return PointsProvider.hotelProviders
        case .airline:
            return PointsProvider.airlineProviders
        }
    }
    
    private func addPoints() {
        guard let points = Int(pointsAmount) else { return }
        
        viewModel.addPoints(
            provider: selectedProvider,
            type: selectedType,
            amount: points
        )
        
        // Reset form
        selectedProvider = ""
        pointsAmount = ""
    }
    
    private func deletePoints(from type: PointsType, at indexSet: IndexSet) {
        let providers: [String]
        switch type {
        case .creditCard:
            providers = Array(viewModel.creditCardPoints.keys.sorted())
        case .hotel:
            providers = Array(viewModel.hotelPoints.keys.sorted())
        case .airline:
            providers = Array(viewModel.airlinePoints.keys.sorted())
        }
        
        for index in indexSet {
            let provider = providers[index]
            viewModel.removePoints(provider: provider, type: type)
        }
    }
}

// MARK: - ViewModel
@MainActor
class PointsManagementViewModel: ObservableObject {
    @Published var creditCardPoints: [String: Int] = [:]
    @Published var hotelPoints: [String: Int] = [:]
    @Published var airlinePoints: [String: Int] = [:]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let pointsService = PointsService()
    
    var hasNoPoints: Bool {
        return creditCardPoints.isEmpty && hotelPoints.isEmpty && airlinePoints.isEmpty && !isLoading && errorMessage == nil
    }
    
    func loadPoints() {
        isLoading = true
        
        Task {
            do {
                let profile = try await pointsService.getUserPointsProfile()
                creditCardPoints = profile?.creditCardPoints ?? [:]
                hotelPoints = profile?.hotelPoints ?? [:]
                airlinePoints = profile?.airlinePoints ?? [:]
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    func addPoints(provider: String, type: PointsType, amount: Int) {
        Task {
            do {
                try await pointsService.updatePoints(
                    provider: provider,
                    type: type,
                    amount: amount
                )
                
                // Update local state
                switch type {
                case .creditCard:
                    creditCardPoints[provider] = amount
                case .hotel:
                    hotelPoints[provider] = amount
                case .airline:
                    airlinePoints[provider] = amount
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func removePoints(provider: String, type: PointsType) {
        Task {
            do {
                try await pointsService.removePoints(provider: provider, type: type)
                
                // Update local state
                switch type {
                case .creditCard:
                    creditCardPoints.removeValue(forKey: provider)
                case .hotel:
                    hotelPoints.removeValue(forKey: provider)
                case .airline:
                    airlinePoints.removeValue(forKey: provider)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}

#Preview {
    PointsManagementView()
}