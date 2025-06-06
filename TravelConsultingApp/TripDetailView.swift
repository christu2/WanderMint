//
//  TripDetailView.swift
//  TravelConsultingApp
//
//  Created by Nick Christus on 6/6/25.
//

import SwiftUI

struct TripDetailView: View {
    let trip: Trip
    @StateObject private var viewModel = TripDetailViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Trip Header
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(trip.destination)
                            .font(.largeTitle)
                            .bold()
                        Spacer()
                        StatusBadge(status: trip.status)
                    }
                    
                    Text("\(trip.startDateFormatted, formatter: dateFormatter) - \(trip.endDateFormatted, formatter: dateFormatter)")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Payment: \(trip.paymentMethod)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if trip.flexibleDates {
                        Label("Flexible dates", systemImage: "calendar.badge.clock")
                            .font(.subheadline)
                            .foregroundColor(.green)
                    }
                }
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
                
                // Recommendation Section
                if let recommendation = trip.recommendation {
                    RecommendationView(recommendation: recommendation)
                } else if trip.status == .processing {
                    ProcessingView()
                } else if trip.status == .failed {
                    FailedView()
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Trip Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadTripDetails(tripId: trip.id)
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }
}

struct RecommendationView: View {
    let recommendation: Recommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Travel Recommendation")
                .font(.title2)
                .bold()
            
            // Overview
            VStack(alignment: .leading, spacing: 8) {
                Text("Overview")
                    .font(.headline)
                Text(recommendation.overview)
                    .font(.body)
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            // Cost Breakdown
            CostBreakdownView(cost: recommendation.estimatedCost)
            
            // Activities
            if !recommendation.activities.isEmpty {
                ActivitiesView(activities: recommendation.activities)
            }
            
            // Accommodations
            if !recommendation.accommodations.isEmpty {
                AccommodationsView(accommodations: recommendation.accommodations)
            }
            
            // Transportation
            TransportationView(transportation: recommendation.transportation)
            
            // Best Time to Visit
            VStack(alignment: .leading, spacing: 8) {
                Text("Best Time to Visit")
                    .font(.headline)
                Text(recommendation.bestTimeToVisit)
                    .font(.body)
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
            
            // Tips
            if !recommendation.tips.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Travel Tips")
                        .font(.headline)
                    ForEach(recommendation.tips, id: \.self) { tip in
                        HStack(alignment: .top) {
                            Text("•")
                            Text(tip)
                        }
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
}

struct CostBreakdownView: View {
    let cost: CostBreakdown
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Estimated Costs (\(cost.currency))")
                .font(.headline)
            
            VStack(spacing: 4) {
                CostRow(label: "Flights", amount: cost.flights, currency: cost.currency)
                CostRow(label: "Accommodation", amount: cost.accommodation, currency: cost.currency)
                CostRow(label: "Activities", amount: cost.activities, currency: cost.currency)
                CostRow(label: "Food", amount: cost.food, currency: cost.currency)
                CostRow(label: "Local Transport", amount: cost.localTransport, currency: cost.currency)
                CostRow(label: "Miscellaneous", amount: cost.miscellaneous, currency: cost.currency)
                
                Divider()
                
                HStack {
                    Text("Total Estimate")
                        .font(.headline)
                    Spacer()
                    Text("\(cost.currency) \(cost.totalEstimate, specifier: "%.2f")")
                        .font(.headline)
                        .bold()
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
}

struct CostRow: View {
    let label: String
    let amount: Double
    let currency: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text("\(currency) \(amount, specifier: "%.2f")")
        }
        .font(.subheadline)
    }
}

struct ActivitiesView: View {
    let activities: [Activity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recommended Activities")
                .font(.headline)
            
            ForEach(activities.sorted(by: { $0.priority < $1.priority })) { activity in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(activity.name)
                            .font(.subheadline)
                            .bold()
                        Spacer()
                        Text("$\(activity.estimatedCost, specifier: "%.0f")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(activity.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        Text(activity.category)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                        Text(activity.estimatedDuration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
                if activity.id != activities.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(8)
    }
}

struct AccommodationsView: View {
    let accommodations: [Accommodation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recommended Accommodations")
                .font(.headline)
            
            ForEach(accommodations) { accommodation in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(accommodation.name)
                            .font(.subheadline)
                            .bold()
                        Spacer()
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.caption)
                            Text("\(accommodation.rating, specifier: "%.1f")")
                                .font(.caption)
                        }
                    }
                    Text(accommodation.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack {
                        Text(accommodation.type.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .cornerRadius(4)
                        Text(accommodation.priceRange)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    if !accommodation.amenities.isEmpty {
                        Text("Amenities: \(accommodation.amenities.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
                if accommodation.id != accommodations.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(Color.teal.opacity(0.1))
        .cornerRadius(8)
    }
}

struct TransportationView: View {
    let transportation: TransportationInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Transportation")
                .font(.headline)
            
            if let flightInfo = transportation.flightInfo {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Flight Information")
                        .font(.subheadline)
                        .bold()
                    Text("Recommended Airlines: \(flightInfo.recommendedAirlines.joined(separator: ", "))")
                        .font(.caption)
                    Text("Estimated Flight Time: \(flightInfo.estimatedFlightTime)")
                        .font(.caption)
                    Text("Best Booking Time: \(flightInfo.bestBookingTime)")
                        .font(.caption)
                    Text("Estimated Cost: $\(transportation.estimatedFlightCost, specifier: "%.0f")")
                        .font(.caption)
                        .bold()
                }
                .padding(.bottom, 8)
            }
            
            if !transportation.localTransport.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Local Transportation")
                        .font(.subheadline)
                        .bold()
                    Text(transportation.localTransport.joined(separator: ", "))
                        .font(.caption)
                    Text("Estimated Cost: $\(transportation.localTransportCost, specifier: "%.0f")")
                        .font(.caption)
                        .bold()
                }
            }
        }
        .padding()
        .background(Color.indigo.opacity(0.1))
        .cornerRadius(8)
    }
}

struct ProcessingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Processing Your Request")
                .font(.headline)
            Text("We're creating your personalized travel recommendation. This usually takes a few minutes.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

struct FailedView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.red)
            Text("Request Failed")
                .font(.headline)
            Text("We encountered an issue processing your request. Please try submitting again or contact support.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - ViewModel
@MainActor
class TripDetailViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let tripService = TripService()
    
    func loadTripDetails(tripId: String) {
        // This could fetch additional details or real-time updates
        // For now, we rely on the trip data passed in
    }
}

#Preview {
    NavigationView {
        TripDetailView(trip: Trip(
            id: "preview",
            userId: "user123",
            destination: "Tokyo, Japan",
            startDate: .init(date: Date()),
            endDate: .init(date: Date().addingTimeInterval(7*24*60*60)),
            paymentMethod: "Credit Card",
            flexibleDates: false,
            status: .completed,
            createdAt: .init(date: Date()),
            updatedAt: nil,
            recommendation: nil
        ))
    }
}
