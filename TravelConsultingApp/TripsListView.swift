import SwiftUI

struct TripsListView: View {
    @StateObject private var viewModel = TripsListViewModel()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading trips...")
                } else if viewModel.trips.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "airplane.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No trips yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Submit your first trip request to get started!")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(trip.destination)
                    .font(.headline)
                Spacer()
                StatusBadge(status: trip.status)
            }
            
            Text("\(trip.startDateFormatted, formatter: dateFormatter) - \(trip.endDateFormatted, formatter: dateFormatter)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Submitted \(trip.createdAtFormatted, formatter: relativeDateFormatter)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    private var relativeDateFormatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }
}

struct StatusBadge: View {
    let status: TripStatusType
    
    var body: some View {
        Text(status.displayText)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColorForStatus(status))
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    
    private func backgroundColorForStatus(_ status: TripStatusType) -> Color {
        switch status {
        case .pending:
            return .orange
        case .inProgress:
            return .blue
        case .completed:
            return .green
        case .cancelled:
            return .red
        }
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
