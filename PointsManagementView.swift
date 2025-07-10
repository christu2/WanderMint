import SwiftUI

struct PointsManagementView: View {
    @StateObject private var viewModel = PointsManagementViewModel()
    @State private var selectedProvider = ""
    @State private var pointsAmount = ""
    @State private var selectedType: PointsType = .creditCard
    @State private var availableProviders: [String] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [AppTheme.Colors.backgroundPrimary, AppTheme.Colors.secondaryLight],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
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
                    } else {
                        ScrollView {
                            VStack(spacing: AppTheme.Spacing.lg) {
                                // Header Section
                                headerSection
                                
                                // Points Summary Cards
                                if !viewModel.hasNoPoints {
                                    pointsSummarySection
                                }
                                
                                // Add Points Section
                                addPointsSection
                                
                                // Points Details
                                if !viewModel.hasNoPoints {
                                    pointsDetailSection
                                }
                            }
                            .padding(AppTheme.Spacing.lg)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.loadPoints()
                // Initialize available providers for the default selected type
                availableProviders = providersForType(selectedType)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: "creditcard.and.123")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(AppTheme.Colors.primary)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Points & Miles")
                        .font(AppTheme.Typography.h1)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("Track your rewards to maximize your travel")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
            }
        }
    }
    
    private var pointsSummarySection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Your Points")
                    .font(AppTheme.Typography.h2)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.md) {
                PointsSummaryCard(
                    title: "Credit Cards",
                    points: totalPoints(for: viewModel.creditCardPoints),
                    icon: "creditcard.fill",
                    color: AppTheme.Colors.primary
                )
                
                PointsSummaryCard(
                    title: "Hotels",
                    points: totalPoints(for: viewModel.hotelPoints),
                    icon: "building.2.fill",
                    color: AppTheme.Colors.secondary
                )
                
                PointsSummaryCard(
                    title: "Airlines",
                    points: totalPoints(for: viewModel.airlinePoints),
                    icon: "airplane",
                    color: AppTheme.Colors.accent
                )
                
                PointsSummaryCard(
                    title: "Total Value",
                    points: totalPointsValue(),
                    icon: "dollarsign.circle.fill",
                    color: AppTheme.Colors.success,
                    isValue: true
                )
            }
        }
    }
    
    private var addPointsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.primary)
                
                Text("Add Points")
                    .font(AppTheme.Typography.h3)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
            }
            
            VStack(spacing: AppTheme.Spacing.md) {
                // Points type picker
                Picker("Points Type", selection: $selectedType) {
                    ForEach(PointsType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(AppTheme.Spacing.md)
                .background(Color.white)
                .cornerRadius(AppTheme.CornerRadius.md)
                .applyShadow(Shadow(color: AppTheme.Shadows.light, radius: 2, x: 0, y: 1))
                .onChange(of: selectedType) { _, newType in
                    // Update available providers and reset selection
                    availableProviders = providersForType(newType)
                    selectedProvider = ""
                }
                
                // Provider and amount inputs
                HStack(spacing: AppTheme.Spacing.md) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("Provider")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        Menu {
                            ForEach(availableProviders, id: \.self) { provider in
                                Button(provider) {
                                    selectedProvider = provider
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedProvider.isEmpty ? "Select Provider" : selectedProvider)
                                    .foregroundColor(selectedProvider.isEmpty ? AppTheme.Colors.textTertiary : AppTheme.Colors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                            }
                            .padding(AppTheme.Spacing.sm)
                            .background(Color.white)
                            .cornerRadius(AppTheme.CornerRadius.sm)
                            .applyShadow(Shadow(color: AppTheme.Shadows.light, radius: 1, x: 0, y: 1))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text("Amount")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        
                        TextField("Points", text: $pointsAmount)
                            .keyboardType(.numberPad)
                            .padding(AppTheme.Spacing.md)
                            .background(Color.white)
                            .cornerRadius(AppTheme.CornerRadius.sm)
                            .applyShadow(Shadow(color: AppTheme.Shadows.light, radius: 1, x: 0, y: 1))
                    }
                }
                
                // Add button
                Button(action: addPoints) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Points")
                    }
                    .font(AppTheme.Typography.button)
                    .foregroundColor(.white)
                    .frame(minHeight: 44)
                    .frame(maxWidth: .infinity)
                    .background(
                        (!selectedProvider.isEmpty && !pointsAmount.isEmpty) ?
                        AppTheme.Colors.gradientPrimary :
                        LinearGradient(colors: [Color.gray], startPoint: .top, endPoint: .bottom)
                    )
                    .cornerRadius(AppTheme.CornerRadius.md)
                    .applyShadow(AppTheme.Shadows.buttonShadow)
                }
                .disabled(selectedProvider.isEmpty || pointsAmount.isEmpty)
            }
            .padding(AppTheme.Spacing.lg)
            .background(Color.white)
            .cornerRadius(AppTheme.CornerRadius.lg)
            .applyShadow(AppTheme.Shadows.cardShadow)
        }
    }
    
    private var pointsDetailSection: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            if !viewModel.creditCardPoints.isEmpty {
                PointsCategoryCard(
                    title: "Credit Card Points",
                    icon: "creditcard.fill",
                    color: AppTheme.Colors.primary,
                    points: viewModel.creditCardPoints,
                    onDelete: { provider in
                        viewModel.removePoints(provider: provider, type: .creditCard)
                    },
                    onUpdate: { provider, newAmount in
                        viewModel.updatePoints(provider: provider, type: .creditCard, amount: newAmount)
                    }
                )
            }
            
            if !viewModel.hotelPoints.isEmpty {
                PointsCategoryCard(
                    title: "Hotel Points",
                    icon: "building.2.fill",
                    color: AppTheme.Colors.secondary,
                    points: viewModel.hotelPoints,
                    onDelete: { provider in
                        viewModel.removePoints(provider: provider, type: .hotel)
                    },
                    onUpdate: { provider, newAmount in
                        viewModel.updatePoints(provider: provider, type: .hotel, amount: newAmount)
                    }
                )
            }
            
            if !viewModel.airlinePoints.isEmpty {
                PointsCategoryCard(
                    title: "Airline Miles",
                    icon: "airplane",
                    color: AppTheme.Colors.accent,
                    points: viewModel.airlinePoints,
                    onDelete: { provider in
                        viewModel.removePoints(provider: provider, type: .airline)
                    },
                    onUpdate: { provider, newAmount in
                        viewModel.updatePoints(provider: provider, type: .airline, amount: newAmount)
                    }
                )
            }
        }
    }
    
    private func iconForType(_ type: PointsType) -> String {
        switch type {
        case .creditCard: return "creditcard.fill"
        case .hotel: return "building.2.fill"
        case .airline: return "airplane"
        }
    }
    
    private func totalPoints(for points: [String: Int]) -> Int {
        points.values.reduce(0, +)
    }
    
    private func totalPointsValue() -> Int {
        // Use configured point values
        let creditValue = Int(Double(totalPoints(for: viewModel.creditCardPoints)) * AppConfig.PointsValues.defaultCreditCardValue)
        let hotelValue = Int(Double(totalPoints(for: viewModel.hotelPoints)) * AppConfig.PointsValues.defaultHotelValue)
        let airlineValue = Int(Double(totalPoints(for: viewModel.airlinePoints)) * AppConfig.PointsValues.defaultAirlineValue)
        return (creditValue + hotelValue + airlineValue) / 100 // Convert to dollars
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
}

struct PointsSummaryCard: View {
    let title: String
    let points: Int
    let icon: String
    let color: Color
    let isValue: Bool
    
    init(title: String, points: Int, icon: String, color: Color, isValue: Bool = false) {
        self.title = title
        self.points = points
        self.icon = icon
        self.color = color
        self.isValue = isValue
    }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(formattedPoints)
                    .font(AppTheme.Typography.h2)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(title)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppTheme.Spacing.lg)
        .background(Color.white)
        .cornerRadius(AppTheme.CornerRadius.lg)
        .applyShadow(AppTheme.Shadows.cardShadow)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var formattedPoints: String {
        if isValue {
            return "$\(points)"
        } else if points >= 1000000 {
            return String(format: "%.1fM", Double(points) / 1000000)
        } else if points >= 1000 {
            return String(format: "%.1fK", Double(points) / 1000)
        } else {
            return "\(points)"
        }
    }
}

struct PointsCategoryCard: View {
    let title: String
    let icon: String
    let color: Color
    let points: [String: Int]
    let onDelete: (String) -> Void
    let onUpdate: (String, Int) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
                
                Text(title)
                    .font(AppTheme.Typography.h3)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Text("\(points.values.reduce(0, +)) pts")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
            }
            
            VStack(spacing: AppTheme.Spacing.sm) {
                ForEach(Array(points.keys.sorted()), id: \.self) { provider in
                    EditablePointsRow(
                        provider: provider,
                        currentPoints: points[provider] ?? 0,
                        onUpdate: { newPoints in
                            onUpdate(provider, newPoints)
                        },
                        onDelete: {
                            onDelete(provider)
                        }
                    )
                }
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(Color.white)
        .cornerRadius(AppTheme.CornerRadius.lg)
        .applyShadow(AppTheme.Shadows.cardShadow)
    }
}

struct EditablePointsRow: View {
    let provider: String
    let currentPoints: Int
    let onUpdate: (Int) -> Void
    let onDelete: () -> Void
    
    @State private var isEditing = false
    @State private var editedPoints = ""
    @State private var showingUpdateConfirmation = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(provider)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if isEditing {
                    HStack(spacing: AppTheme.Spacing.sm) {
                        TextField("Points", text: $editedPoints)
                            .keyboardType(.numberPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(width: 120)
                        
                        Button("Save") {
                            savePoints()
                        }
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(.white)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(AppTheme.Colors.success)
                        .cornerRadius(AppTheme.CornerRadius.xs)
                        .disabled(editedPoints.isEmpty)
                        
                        Button("Cancel") {
                            cancelEdit()
                        }
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.xs)
                        .background(AppTheme.Colors.backgroundSecondary)
                        .cornerRadius(AppTheme.CornerRadius.xs)
                    }
                } else {
                    Text("\(currentPoints) points")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
            
            Spacer()
            
            if !isEditing {
                HStack(spacing: AppTheme.Spacing.sm) {
                    Button(action: startEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.Colors.error)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(isEditing ? AppTheme.Colors.primaryLight.opacity(0.3) : AppTheme.Colors.backgroundSecondary)
        .cornerRadius(AppTheme.CornerRadius.sm)
        .animation(AppTheme.Animation.quick, value: isEditing)
        .alert("Update Successful", isPresented: $showingUpdateConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\(provider) points updated successfully!")
        }
    }
    
    private func startEdit() {
        editedPoints = String(currentPoints)
        isEditing = true
    }
    
    private func cancelEdit() {
        editedPoints = ""
        isEditing = false
    }
    
    private func savePoints() {
        guard let newPoints = Int(editedPoints), newPoints >= 0 else {
            return
        }
        
        onUpdate(newPoints)
        isEditing = false
        editedPoints = ""
        showingUpdateConfirmation = true
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
    
    func updatePoints(provider: String, type: PointsType, amount: Int) {
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