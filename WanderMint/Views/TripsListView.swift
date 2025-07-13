import SwiftUI

struct TripsListView: View {
    @StateObject private var viewModel = TripsListViewModel()
    @EnvironmentObject var notificationService: NotificationService
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            ZStack {
                TripsListBackground()
                TripsListContent(
                    viewModel: viewModel, 
                    selectedTab: $selectedTab,
                    pendingTripId: notificationService.pendingTripId
                )
            }
            .navigationBarHidden(true)
            .onAppear {
                viewModel.loadTrips()
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
}

// MARK: - Helper Views
struct TripsListBackground: View {
    var body: some View {
        LinearGradient(
            colors: [AppTheme.Colors.backgroundPrimary, AppTheme.Colors.primaryLight],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

struct TripsListContent: View {
    @ObservedObject var viewModel: TripsListViewModel
    @Binding var selectedTab: Int
    let pendingTripId: String?
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading your trips...")
            } else if viewModel.errorMessage != nil {
                TripsListErrorView(viewModel: viewModel)
            } else if viewModel.trips.isEmpty {
                TripsListEmptyStateView(selectedTab: $selectedTab)
            } else {
                TripsListScrollView(
                    trips: viewModel.trips, 
                    pendingTripId: pendingTripId,
                    viewModel: viewModel,
                    refreshAction: {
                        await viewModel.refreshTrips()
                    }
                )
            }
        }
    }
}

struct TripsListErrorView: View {
    @ObservedObject var viewModel: TripsListViewModel
    
    var body: some View {
        ErrorView(
            title: "Unable to Load Trips",
            message: viewModel.errorMessage ?? "Unknown error occurred",
            retryAction: {
                viewModel.loadTrips()
            }
        )
    }
}

struct TripsListScrollView: View {
    let trips: [TravelTrip]
    let pendingTripId: String?
    let viewModel: TripsListViewModel
    let refreshAction: () async -> Void
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.md) {
                TripsListHeader(tripCount: trips.count)
                TripsListGrid(trips: trips, pendingTripId: pendingTripId, viewModel: viewModel)
            }
        }
        .refreshable {
            await refreshAction()
        }
        .navigationDestination(for: String.self) { tripId in
            if let trip = trips.first(where: { $0.id == tripId }) {
                TripDetailView(initialTrip: trip)
            }
        }
    }
}

struct TripsListHeader: View {
    let tripCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("My Adventures")
                .font(AppTheme.Typography.h1)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            Text("\(tripCount) trip\(tripCount == 1 ? "" : "s") planned")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppTheme.Spacing.lg)
        .padding(.top, AppTheme.Spacing.lg)
    }
}

struct TripsListGrid: View {
    let trips: [TravelTrip]
    let pendingTripId: String?
    let viewModel: TripsListViewModel
    @State private var showingDeleteAlert = false
    @State private var tripToDelete: TravelTrip?
    
    var body: some View {
        ForEach(trips) { trip in
            NavigationLink(value: trip.id) {
                EnhancedTripCard(trip: trip, canDelete: viewModel.canDeleteTrip(trip))
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, AppTheme.Spacing.lg)
            .accessibilityLabel("Trip to \(trip.displayDestinations)")
            .accessibilityHint("View trip details and itinerary")
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if viewModel.canDeleteTrip(trip) {
                    Button("Delete", role: .destructive) {
                        tripToDelete = trip
                        showingDeleteAlert = true
                    }
                    .tint(.red)
                }
            }
        }
        .alert("Delete Trip", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                tripToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let trip = tripToDelete {
                    viewModel.deleteTrip(trip)
                    tripToDelete = nil
                }
            }
        } message: {
            if let trip = tripToDelete {
                Text("Are you sure you want to delete your trip to \(trip.displayDestinations)? This action cannot be undone.")
            }
        }
    }
}

struct TripsListEmptyStateView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xl) {
            Spacer()
            
            TripsListEmptyStateIcon()
            TripsListEmptyStateText(selectedTab: $selectedTab)
            
            Spacer()
        }
        .padding(AppTheme.Spacing.lg)
    }
}

struct TripsListEmptyStateIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.Colors.gradientPrimary)
                .frame(width: 120, height: 120)
                .shadow(color: AppTheme.Colors.primary.opacity(0.3), radius: 20, x: 0, y: 10)
            
            Image(systemName: "airplane.departure")
                .font(.system(size: 50, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

struct TripsListEmptyStateText: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Text("Ready for Adventure?")
                .font(AppTheme.Typography.h1)
                .foregroundColor(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text("Start planning your next amazing trip! Tell us where you want to go and we'll create the perfect itinerary just for you.")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.lg)
            
            TripsListEmptyStateButton(selectedTab: $selectedTab)
        }
    }
}

struct TripsListEmptyStateButton: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        Button(action: {
            // Switch to trip submission tab (index 0)
            selectedTab = 0
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Plan My First Trip")
            }
            .font(AppTheme.Typography.button)
            .foregroundColor(.white)
            .frame(minHeight: 44)
            .padding(.horizontal, AppTheme.Spacing.xl)
            .background(AppTheme.Colors.gradientSecondary)
            .cornerRadius(AppTheme.CornerRadius.xl)
            .applyShadow(AppTheme.Shadows.buttonShadow)
        }
        .padding(.top, AppTheme.Spacing.lg)
        .accessibilityLabel("Plan my first trip")
        .accessibilityHint("Start planning your first trip")
    }
}


struct EnhancedTripCard: View {
    let trip: TravelTrip
    let canDelete: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with gradient background
            ZStack {
                AppTheme.Colors.gradientPrimary
                
                HStack {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                        Text(trip.displayDestinations)
                            .font(AppTheme.Typography.h3)
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Text(dateRangeText)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Spacer()
                    
                    VStack(spacing: AppTheme.Spacing.xs) {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            StatusBadge(status: trip.status)
                            
                            if canDelete {
                                Image(systemName: "trash")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.7))
                                    .help("Swipe left to delete")
                            }
                        }
                        
                        Image(systemName: destinationIcon)
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(AppTheme.Spacing.lg)
            }
            .frame(height: 100)
            
            // Content section
            VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                HStack {
                    Label(groupSizeText, systemImage: "person.2.fill")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Spacer()
                    
                    Label("Created \(trip.createdAtFormatted, formatter: relativeDateFormatter)", systemImage: "calendar")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textTertiary)
                        .lineLimit(1)
                }
                
                // Additional details if available
                if let budget = trip.budget, !budget.isEmpty {
                    HStack {
                        Image(systemName: "dollarsign.circle.fill")
                            .foregroundColor(AppTheme.Colors.secondary)
                        Text("Budget: $\(budget)")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                }
                
                // Progress indicator
                HStack {
                    Text(progressText)
                        .font(AppTheme.Typography.captionBold)
                        .foregroundColor(AppTheme.Colors.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textTertiary)
                }
            }
            .padding(AppTheme.Spacing.lg)
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg))
        .applyShadow(AppTheme.Shadows.cardShadow)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.lg)
                .stroke(AppTheme.Colors.surfaceBorder, lineWidth: 0.5)
        )
    }
    
    private var destinationIcon: String {
        let destination = trip.displayDestinations.lowercased()
        if destination.contains("beach") || destination.contains("island") {
            return "sun.max.fill"
        } else if destination.contains("mountain") || destination.contains("ski") {
            return "mountain.2.fill"
        } else if destination.contains("city") || destination.contains("urban") {
            return "building.2.fill"
        } else {
            return "location.fill"
        }
    }
    
    private var progressText: String {
        switch trip.status {
        case .pending:
            return "Planning in progress"
        case .inProgress:
            return "Itinerary being created"
        case .completed:
            return "Ready to travel!"
        case .cancelled:
            return "Trip cancelled"
        case .failed:
            return "Processing failed"
        }
    }
    
    private var dateRangeText: String {
        return DateUtils.displayString(from: trip.startDateFormatted, to: trip.endDateFormatted)
    }
    
    private var groupSizeText: String {
        let size = trip.groupSize ?? 1
        return "\(size) \(size == 1 ? "person" : "people")"
    }
    
    private var relativeDateFormatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }
}

// Keep original TripRowView for backwards compatibility if needed
struct TripRowView: View {
    let trip: TravelTrip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trip.displayDestinations)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(dateRangeText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusBadge(status: trip.status)
            }
            
            HStack {
                Label(groupSizeText, systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Created \(trip.createdAtFormatted, formatter: relativeDateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
    
    private var dateRangeText: String {
        return DateUtils.displayString(from: trip.startDateFormatted, to: trip.endDateFormatted)
    }
    
    private var groupSizeText: String {
        let size = trip.groupSize ?? 1
        return "\(size) \(size == 1 ? "person" : "people")"
    }
    
    private var relativeDateFormatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }
}

// MARK: - ViewModel
// Protocol to allow mocking
protocol TripServiceProtocol {
    func deleteTrip(tripId: String) async throws
    func fetchUserTrips() async throws -> [TravelTrip]
}

extension TripService: TripServiceProtocol {}

@MainActor
class TripsListViewModel: ObservableObject {
    @Published var trips: [TravelTrip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let tripService: TripServiceProtocol
    
    init(tripService: TripServiceProtocol? = nil) {
        self.tripService = tripService ?? TripService()
    }
    
    func loadTrips() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                trips = try await tripService.fetchUserTrips()
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    func refreshTrips() async {
        do {
            trips = try await tripService.fetchUserTrips()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
    
    func deleteTrip(_ trip: TravelTrip) {
        Task {
            await deleteTripAsync(trip)
        }
    }
    
    func deleteTripAsync(_ trip: TravelTrip) async {
        // Check if deletion is allowed first
        guard canDeleteTrip(trip) else {
            await MainActor.run {
                errorMessage = "Cannot delete this trip"
            }
            return
        }
        
        do {
            try await tripService.deleteTrip(tripId: trip.id)
            // Remove from local array on success
            await MainActor.run {
                trips.removeAll { $0.id == trip.id }
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to delete trip: \(error.localizedDescription)"
            }
        }
    }
    
    func canDeleteTrip(_ trip: TravelTrip) -> Bool {
        // Allow deletion if:
        // 1. Trip is completed or cancelled
        // 2. Trip end date has passed
        // 3. Trip is in failed state
        
        switch trip.status {
        case .completed, .cancelled, .failed:
            return true
        case .pending, .inProgress:
            // Check if trip end date has passed
            let now = Date()
            return trip.endDateFormatted < now
        }
    }
}

#Preview {
    TripsListView(selectedTab: .constant(1))
}