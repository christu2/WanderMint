import SwiftUI

struct AdminTripDetailView: View {
    let initialTrip: TravelTrip
    @StateObject private var viewModel = TripDetailViewModel()
    
    private var trip: TravelTrip {
        return viewModel.trip ?? initialTrip
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Loading indicator
                if viewModel.isLoading {
                    ProgressView("Loading trip details...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                }
                
                // Trip Header
                AdminTripHeaderView(trip: trip)
                
                // Admin Recommendation Section
                if let adminRecommendation = trip.destinationRecommendation {
                    AdminRecommendationView(
                        recommendation: adminRecommendation,
                        tripId: trip.id,
                        onBookingUpdate: {
                            viewModel.refreshTrip()
                        }
                    )
                } else if trip.status == .pending {
                    PendingReviewView()
                } else if trip.status == .inProgress {
                    InProgressView()
                } else if trip.status == .completed {
                    NoRecommendationView()
                } else if trip.status == .cancelled {
                    CancelledView()
                }
                
                // Additional trip details
                AdminTripDetailsSection(trip: trip)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadTripDetails(tripId: initialTrip.id, initialTrip: initialTrip)
        }
    }
}

struct AdminTripHeaderView: View {
    let trip: TravelTrip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(trip.displayDestinations)
                    .font(.largeTitle)
                    .bold()
                Spacer()
                StatusBadge(status: trip.status)
            }
            
            Text("\(trip.startDateFormatted, formatter: dateFormatter) - \(trip.endDateFormatted, formatter: dateFormatter)")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if let departureLocation = trip.departureLocation, !departureLocation.isEmpty {
                HStack {
                    Image(systemName: "airplane.departure")
                        .foregroundColor(.blue)
                    Text("Departing from \(departureLocation)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if trip.flexibleDates {
                Label("Flexible dates", systemImage: "calendar.badge.clock")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

struct NoRecommendationView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            Text("Itinerary Processing")
                .font(.headline)
            Text("Your travel consultant is still preparing your personalized itinerary. Check back soon!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

struct AdminTripDetailsSection: View {
    let trip: TravelTrip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trip Details")
                .font(.headline)
                .padding(.bottom, 5)
            
            if let budget = trip.budget {
                DetailRowView(label: "Budget", value: budget)
            }
            
            if let travelStyle = trip.travelStyle {
                DetailRowView(label: "Travel Style", value: travelStyle)
            }
            
            if let groupSize = trip.groupSize {
                DetailRowView(label: "Group Size", value: "\(groupSize) people")
            }
            
            if let flightClass = trip.flightClass {
                DetailRowView(label: "Flight Class", value: flightClass)
            }
            
            if let interests = trip.interests, !interests.isEmpty {
                DetailRowView(label: "Interests", value: interests.joined(separator: ", "))
            }
            
            if let specialRequests = trip.specialRequests, !specialRequests.isEmpty {
                DetailRowView(label: "Special Requests", value: specialRequests)
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

// Note: Status views (PendingReviewView, InProgressView, CancelledView) are defined in TripDetailView.swift

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter
}()