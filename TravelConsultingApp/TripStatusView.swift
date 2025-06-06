import SwiftUI
import Firebase

struct TripStatusView: View {
    let tripId: String
    @StateObject private var viewModel = TripStatusViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if viewModel.isLoading {
                    loadingView
                } else if let trip = viewModel.trip {
                    tripDetailsView(trip: trip)
                } else {
                    errorView
                }
            }
            .padding()
        }
        .navigationTitle("Trip Status")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.fetchTrip(tripId: tripId)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("Retry") {
                viewModel.fetchTrip(tripId: tripId)
            }
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading trip details...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Unable to load trip")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Please check your connection and try again.")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                viewModel.fetchTrip(tripId: tripId)
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private func tripDetailsView(trip: Trip) -> some View {
        VStack(spacing: 24) {
            // Header with destination and status
            headerView(trip: trip)
            
            // Trip details
            tripInfoSection(trip: trip)
            
            // Recommendation section
            if let recommendation = trip.recommendation {
                recommendationSection(recommendation: recommendation)
            } else {
                statusMessageSection(status: trip.status)
            }
        }
    }
    
    private func headerView(trip: Trip) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "airplane.departure")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text(trip.destination)
                .font(.title)
                .fontWeight(.bold)
            
            StatusBadge(status: trip.status)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(16)
    }
    
    private func tripInfoSection(trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trip Information")
                .font(.headline)
            
            VStack(spacing: 12) {
                InfoRow(icon: "calendar", title: "Dates", value: formatDateRange(start: trip.startDate, end: trip.endDate))
                InfoRow(icon: "creditcard", title: "Payment", value: trip.paymentMethod)
                if trip.flexibleDates {
                    InfoRow(icon: "calendar.badge.clock", title: "Flexible Dates", value: "Yes")
                }
                if let createdAt = trip.createdAt {
                    InfoRow(icon: "clock", title: "Submitted", value: DateFormatter.relative.string(from: createdAt))
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func recommendationSection(recommendation: Recommendation) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Personalized Recommendation")
                .font(.headline)
            
            if let description = recommendation.description {
                Text(description)
                    .font(.body)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
            }
            
            VStack(spacing: 12) {
                RecommendationRow(icon: "bed.double", title: "Accommodation", value: recommendation.accommodation)
                RecommendationRow(icon: "car", title: "Transportation", value: recommendation.transportation)
                
                if !recommendation.activities.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "list.bullet")
                                .foregroundColor(.blue)
                                .frame(width: 20)
                            Text("Recommended Activities")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(recommendation.activities, id: \.self) { activity in
                                Text("• \(activity)")
                                    .font(.body)
                                    .padding(.leading, 20)
                            }
                        }
                    }
                }
                
                if let cost = recommendation.estimatedCost {
                    RecommendationRow(icon: "dollarsign.circle", title: "Estimated Cost", value: "$\(cost, specifier: "%.2f")")
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func statusMessageSection(status: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: statusIcon(for: status))
                .font(.system(size: 40))
                .foregroundColor(statusColor(for: status))
            
            Text(statusMessage(for: status))
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
            
            Text(statusDescription(for: status))
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(statusColor(for: status).opacity(0.1))
        .cornerRadius(12)
    }
    
    private func formatDateRange(start: Date?, end: Date?) -> String {
        guard let start = start, let end = end else {
            return "Not specified"
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    private func statusIcon(for status: String) -> String {
        switch status.lowercased() {
        case "submitted":
            return "paperplane"
        case "processing", "in_progress":
            return "gear"
        case "completed":
            return "checkmark.circle"
        case "cancelled":
            return "xmark.circle"
        default:
            return "questionmark.circle"
        }
    }
    
    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "submitted":
            return .blue
        case "processing", "in_progress":
            return .orange
        case "completed":
            return .green
        case "cancelled":
            return .red
        default:
            return .gray
        }
    }
    
    private func statusMessage(for status: String) -> String {
        switch status.lowercased() {
        case "submitted":
            return "Trip Submitted Successfully!"
        case "processing", "in_progress":
            return "Creating Your Itinerary"
        case "completed":
            return "Your Trip is Ready!"
        case "cancelled":
            return "Trip Cancelled"
        default:
            return "Unknown Status"
        }
    }
    
    private func statusDescription(for status: String) -> String {
        switch status.lowercased() {
        case "submitted":
            return "We've received your trip request and will start working on personalized recommendations shortly."
        case "processing", "in_progress":
            return "Our travel experts are crafting the perfect itinerary based on your preferences."
        case "completed":
            return "Your personalized travel recommendations are ready! Check the details below."
        case "cancelled":
            return "This trip request has been cancelled."
        default:
            return "We're processing your request."
        }
    }
}

struct StatusBadge: View {
    let status: String
    
    var body: some View {
        Text(status.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundColor(statusColor)
            .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch status.lowercased() {
        case "submitted":
            return .blue
        case "processing", "in_progress":
            return .orange
        case "completed":
            return .green
        case "cancelled":
            return .red
        default:
            return .gray
        }
    }
}

struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct RecommendationRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(value)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

extension DateFormatter {
    static let relative: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
}
