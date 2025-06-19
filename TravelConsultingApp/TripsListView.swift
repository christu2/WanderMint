import SwiftUI

struct TripsListView: View {
    @StateObject private var viewModel = TripsListViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    LoadingView(message: "Loading your trips...")
                } else if viewModel.errorMessage != nil {
                    ErrorView(
                        title: "Unable to Load Trips",
                        message: viewModel.errorMessage ?? "Unknown error occurred",
                        retryAction: {
                            viewModel.loadTrips()
                        }
                    )
                } else if viewModel.trips.isEmpty {
                    EmptyStateView(
                        icon: "airplane.departure",
                        title: "Ready for Adventure?",
                        subtitle: "Start planning your next amazing trip! Tell us where you want to go and we'll create the perfect itinerary just for you.",
                        actionTitle: "Plan My First Trip",
                        action: {
                            // This would switch to the submission tab
                            // You can implement tab switching here
                        }
                    )
                } else {
                    List(viewModel.trips) { trip in
                        NavigationLink(destination: TripDetailView(trip: trip)) {
                            TripRowView(trip: trip)
                        }
                    }
                    .refreshable {
                        await viewModel.refreshTrips()
                    }
                }
            }
            .navigationTitle("My Trips")
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
        .padding(.vertical, 12) // Increased from 4 to 12 for better touch target
        .contentShape(Rectangle()) // Better tap target
    }
    
    private var dateRangeText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "\(formatter.string(from: trip.startDateFormatted)) - \(formatter.string(from: trip.endDateFormatted))"
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
@MainActor
class TripsListViewModel: ObservableObject {
    @Published var trips: [TravelTrip] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let tripService = TripService()
    
    func loadTrips() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                print("Loading trips...")
                trips = try await tripService.fetchUserTrips()
                print("Loaded \(trips.count) trips successfully")
            } catch {
                print("Error loading trips: \(error)")
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
}

#Preview {
    TripsListView()
}
