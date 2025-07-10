import SwiftUI

struct TripDetailView: View {
    let trip: TravelTrip
    @StateObject private var viewModel = TripDetailViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Trip Header
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
                } else if trip.status == .pending {
                    PendingReviewView()
                } else if trip.status == .inProgress {
                    InProgressView()
                } else if trip.status == .completed {
                    // Show message if completed but no recommendation
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
                } else if trip.status == .cancelled {
                    CancelledView()
                }
                
                // Additional trip details
                TripDetailsSection(trip: trip)
                
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
            HStack {
                Image(systemName: "map")
                    .foregroundColor(.blue)
                Text("Your Travel Itinerary")
                    .font(.title2)
                    .bold()
                Spacer()
            }
            
            // Overview - Handle both simple text and complex recommendations
            VStack(alignment: .leading, spacing: 12) {
                Text(recommendation.overview)
                    .font(.body)
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
            .cornerRadius(8)
            
            // Show detailed itinerary if available
            if let itinerary = recommendation.itinerary {
                DetailedItineraryView(itinerary: itinerary)
            } else {
                // Fallback to simple sections for backwards compatibility
                if !recommendation.activities.isEmpty {
                    ActivitiesView(activities: recommendation.activities)
                }
                
                if !recommendation.accommodations.isEmpty {
                    AccommodationsView(accommodations: recommendation.accommodations)
                }
                
                // Only show cost breakdown if it has actual data
                if recommendation.estimatedCost.totalEstimate > 0 {
                    CostBreakdownView(cost: recommendation.estimatedCost)
                }
                
                // Only show transportation if it has actual data
                if let transportation = recommendation.transportation,
                   (transportation.estimatedFlightCost > 0 || !transportation.localTransport.isEmpty) {
                    TransportationView(transportation: transportation)
                }
                
                if !recommendation.bestTimeToVisit.isEmpty && recommendation.bestTimeToVisit != "Not specified" {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Best Time to Visit")
                            .font(.headline)
                        Text(recommendation.bestTimeToVisit)
                            .font(.body)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                
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
                    Text("\(cost.currency) \(formatCostAmount(cost.totalEstimate))")
                        .font(.headline)
                        .bold()
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func formatCostAmount(_ amount: Double) -> String {
        if amount.isNaN || amount.isInfinite {
            return "0.00"
        }
        return String(format: "%.2f", max(0, amount))
    }
}

struct EnhancedCostBreakdownView: View {
    let itinerary: DetailedItinerary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "dollarsign.circle")
                    .foregroundColor(.green)
                Text("Major Travel Costs")
                    .font(.headline)
                Spacer()
            }
            
            VStack(spacing: 8) {
                // Flight Costs - show both cash and points
                if !itinerary.flights.allFlights.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Flights")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(Array(itinerary.flights.allFlights.enumerated()), id: \.offset) { index, flight in
                            HStack {
                                Text("Flight \(index + 1)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                FlexibleCostView(cost: flight.cost, style: .primary)
                                    .font(.subheadline)
                            }
                        }
                        
                        if itinerary.flights.allFlights.count > 1 {
                            Divider()
                                .padding(.horizontal)
                            HStack {
                                Text("Total Flights")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                FlexibleCostView(cost: itinerary.flights.totalFlightCost, style: .primary)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Divider()
                
                // Accommodation Costs - show both cash and points
                if !itinerary.accommodations.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Accommodations")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(itinerary.accommodations) { accommodation in
                            HStack {
                                Text(accommodation.name)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                Spacer()
                                FlexibleCostView(cost: accommodation.cost, style: .primary)
                                    .font(.subheadline)
                                Text("/night")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // Major Transportation (trains, buses between cities)
                if let majorTransportation = itinerary.majorTransportation, !majorTransportation.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Transportation")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(majorTransportation) { transport in
                            HStack {
                                Text("\(transport.method.displayName): \(transport.from) → \(transport.to)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                Spacer()
                                FlexibleCostView(cost: transport.cost, style: .primary)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // All Activities
                let allActivities = itinerary.dailyPlans.flatMap { $0.activities }.filter { $0.cost.totalCashValue > 0 }
                if !allActivities.isEmpty {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Activities")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ForEach(allActivities.prefix(10)) { activity in
                            HStack {
                                Text(activity.title)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                Spacer()
                                FlexibleCostView(cost: activity.cost, style: .primary)
                                    .font(.subheadline)
                            }
                        }
                        
                        if allActivities.count > 10 {
                            Text("+ \(allActivities.count - 10) more activities")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .italic()
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(12)
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
            Text("\(currency) \(formatAmount(amount))")
        }
        .font(.subheadline)
    }
    
    private func formatAmount(_ amount: Double) -> String {
        if amount.isNaN || amount.isInfinite {
            return "0.00"
        }
        return String(format: "%.2f", max(0, amount))
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
                        Text("$\(formatActivityCost(activity.estimatedCost))")
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
    
    private func formatActivityCost(_ cost: Double) -> String {
        if cost.isNaN || cost.isInfinite {
            return "0"
        }
        return String(format: "%.0f", max(0, cost))
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
                            Text(String(format: "%.1f", max(0, min(5, accommodation.rating))))
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
                    Text("Estimated Cost: $\(formatTransportCost(transportation.estimatedFlightCost))")
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
                    Text("Estimated Cost: $\(formatTransportCost(transportation.localTransportCost))")
                        .font(.caption)
                        .bold()
                }
            }
        }
        .padding()
        .background(Color.indigo.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func formatTransportCost(_ cost: Double) -> String {
        if cost.isNaN || cost.isInfinite {
            return "0"
        }
        return String(format: "%.0f", max(0, cost))
    }
}

struct PendingReviewView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            Text("Pending Review")
                .font(.headline)
            Text("Your trip request has been received and is being reviewed. I'll personally research and plan your perfect itinerary!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
}

struct InProgressView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Planning Your Trip")
                .font(.headline)
            Text("I'm currently researching and creating your personalized itinerary. This includes finding the best flights, accommodations, and activities based on your preferences.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

struct CancelledView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "xmark.circle")
                .font(.system(size: 40))
                .foregroundColor(.red)
            Text("Trip Cancelled")
                .font(.headline)
            Text("This trip request has been cancelled. If you have any questions, please contact support.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
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

struct TripDetailsSection: View {
    let trip: TravelTrip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                Text("Trip Details")
                    .font(.title2)
                    .bold()
                Spacer()
            }
            
            VStack(spacing: 12) {
                if let budget = trip.budget {
                    DetailRow(label: "Budget", value: budget, icon: "dollarsign.circle")
                }
                
                if let travelStyle = trip.travelStyle {
                    DetailRow(label: "Travel Style", value: travelStyle, icon: "person.circle")
                }
                
                if let groupSize = trip.groupSize {
                    DetailRow(label: "Group Size", value: "\(groupSize) people", icon: "person.2.circle")
                }
                
                if let flightClass = trip.flightClass {
                    DetailRow(label: "Flight Class", value: flightClass, icon: "airplane.circle")
                }
                
                if let interests = trip.interests, !interests.isEmpty {
                    DetailRow(label: "Interests", value: interests.joined(separator: ", "), icon: "heart.circle")
                }
                
                if let specialRequests = trip.specialRequests, !specialRequests.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "note.text")
                                .foregroundColor(.blue)
                            Text("Special Requests")
                                .font(.headline)
                        }
                        Text(specialRequests)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Detailed Itinerary Views
struct DetailedItineraryView: View {
    let itinerary: DetailedItinerary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Unified Transportation (flights and trains chronologically)
            UnifiedTransportationView(itinerary: itinerary)
            
            // Daily Plans
            if !itinerary.dailyPlans.isEmpty {
                DailyPlansView(dailyPlans: itinerary.dailyPlans)
            }
            
            // Accommodations
            if !itinerary.accommodations.isEmpty {
                AccommodationDetailsView(accommodations: itinerary.accommodations)
            }
            
            // Total Cost
            if itinerary.totalCost.totalEstimate > 0 {
                EnhancedCostBreakdownView(itinerary: itinerary)
            }
        }
    }
}

struct UnifiedTransportationView: View {
    let itinerary: DetailedItinerary
    
    private var allTransportation: [TransportationItem] {
        var items: [TransportationItem] = []
        
        // Add all flights
        for (index, flight) in itinerary.flights.allFlights.enumerated() {
            let title = getFlightTitle(for: index, total: itinerary.flights.allFlights.count)
            items.append(.flight(flight, title: title))
        }
        
        // Add major transportation (trains, buses)
        if let majorTransportation = itinerary.majorTransportation {
            for transport in majorTransportation {
                items.append(.localTransportation(transport))
            }
        }
        
        // Sort chronologically
        return items.sorted { item1, item2 in
            guard let date1 = item1.date, let date2 = item2.date else {
                // If dates are missing, sort flights first, then by time string
                switch (item1, item2) {
                case (.flight, .localTransportation):
                    return true
                case (.localTransportation, .flight):
                    return false
                default:
                    return item1.time < item2.time
                }
            }
            return date1 < date2
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "airplane")
                    .foregroundColor(.blue)
                Text("Transportation")
                    .font(.title2)
                    .bold()
                Spacer()
            }
            
            ForEach(Array(allTransportation.enumerated()), id: \.offset) { index, item in
                switch item {
                case .flight(let flight, let title):
                    FlightCardView(flight: flight, title: title)
                case .localTransportation(let transport):
                    UnifiedTransportationCardView(transport: transport)
                }
            }
            
            // Keep important booking information but remove total cost card
            if !itinerary.flights.bookingDeadline.isEmpty || !itinerary.flights.bookingInstructions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    if !itinerary.flights.bookingDeadline.isEmpty {
                        HStack {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .foregroundColor(.orange)
                            Text("Book by: \(itinerary.flights.bookingDeadline)")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    if !itinerary.flights.bookingInstructions.isEmpty {
                        Text(itinerary.flights.bookingInstructions)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private func getFlightTitle(for index: Int, total: Int) -> String {
        if total == 1 {
            return "Flight"
        } else if total == 2 {
            return index == 0 ? "Outbound Flight" : "Return Flight"
        } else {
            return "Flight \(index + 1)"
        }
    }
}

struct UnifiedTransportationCardView: View {
    let transport: LocalTransportation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: transport.method.icon)
                    .font(.title2)
                    .foregroundColor(.orange)
                Text(transport.method.displayName)
                    .font(.headline)
                    .bold()
                    .foregroundColor(.orange)
                Spacer()
                if transport.cost.totalCashValue > 0 {
                    FlexibleCostView(cost: transport.cost, style: .primary)
                        .font(.subheadline)
                        .bold()
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("From")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(transport.from)
                        .font(.title3)
                        .bold()
                    if !transport.time.isEmpty {
                        Text(transport.time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack {
                    Image(systemName: transport.method.icon)
                        .font(.title2)
                        .foregroundColor(.orange)
                    if !transport.duration.isEmpty {
                        Text(transport.duration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("To")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(transport.to)
                        .font(.title3)
                        .bold()
                }
            }
            
            if !transport.instructions.isEmpty {
                Text(transport.instructions)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            if let bookingUrl = transport.bookingUrl, !bookingUrl.isEmpty {
                Button(action: {
                    if let url = URL(string: bookingUrl) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "link")
                        Text("Book Transportation")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.orange.opacity(0.8), Color.red.opacity(0.6)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
}

struct FlightItineraryView: View {
    let flights: FlightItinerary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "airplane")
                    .foregroundColor(.blue)
                Text("Flight Information")
                    .font(.title2)
                    .bold()
                Spacer()
            }
            
            ForEach(Array(flights.allFlights.enumerated()), id: \.offset) { index, flight in
                let title = getFlightTitle(for: index, total: flights.allFlights.count)
                FlightCardView(flight: flight, title: title)
            }
            
            // Keep important booking information but remove total cost card
            if !flights.bookingDeadline.isEmpty || !flights.bookingInstructions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    if !flights.bookingDeadline.isEmpty {
                        HStack {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .foregroundColor(.orange)
                            Text("Book by: \(flights.bookingDeadline)")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    if !flights.bookingInstructions.isEmpty {
                        Text(flights.bookingInstructions)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private func getFlightTitle(for index: Int, total: Int) -> String {
        if total == 1 {
            return "Flight"
        } else if total == 2 {
            return index == 0 ? "Outbound Flight" : "Return Flight"
        } else {
            return "Flight \(index + 1)"
        }
    }
}

struct FlightCardView: View {
    let flight: FlightDetails
    let title: String
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                VStack(alignment: .leading) {
                    Text(flight.departure.airportCode.isEmpty ? "DEP" : flight.departure.airportCode)
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    if !flight.departure.city.isEmpty {
                        Text(flight.departure.city)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    if !flight.departure.date.isEmpty || !flight.departure.time.isEmpty {
                        Text("\(flight.departure.date) \(flight.departure.time)".trimmingCharacters(in: .whitespaces))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                Spacer()
                
                VStack {
                    Image(systemName: "airplane")
                        .font(.title2)
                        .foregroundColor(.white)
                    Text(flight.duration)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(flight.arrival.airportCode.isEmpty ? "ARR" : flight.arrival.airportCode)
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    if !flight.arrival.city.isEmpty {
                        Text(flight.arrival.city)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    if !flight.arrival.date.isEmpty || !flight.arrival.time.isEmpty {
                        Text("\(flight.arrival.date) \(flight.arrival.time)".trimmingCharacters(in: .whitespaces))
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            
            HStack {
                let flightInfo = [flight.airline, flight.flightNumber].filter { !$0.isEmpty }.joined(separator: " ")
                Text(flightInfo.isEmpty ? "Flight Details" : flightInfo)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Spacer()
                FlexibleCostView(cost: flight.cost, style: .white)
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue, Color.purple]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .onTapGesture {
            showDetails = true
        }
        .sheet(isPresented: $showDetails) {
            FlightDetailsSheet(flight: flight, title: title)
        }
    }
}

struct FlightDetailsSheet: View {
    let flight: FlightDetails
    let title: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Flight Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title)
                            .font(.largeTitle)
                            .bold()
                        
                        let flightInfo = [flight.airline, flight.flightNumber].filter { !$0.isEmpty }.joined(separator: " ")
                        if !flightInfo.isEmpty {
                            Text(flightInfo)
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    
                    // Flight Route
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Flight Route")
                            .font(.headline)
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Departure")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(flight.departure.airportCode.isEmpty ? "DEP" : flight.departure.airportCode)
                                    .font(.title2)
                                    .bold()
                                if !flight.departure.city.isEmpty {
                                    Text(flight.departure.city)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                if !flight.departure.date.isEmpty || !flight.departure.time.isEmpty {
                                    Text("\(flight.departure.date) \(flight.departure.time)".trimmingCharacters(in: .whitespaces))
                                        .font(.subheadline)
                                }
                            }
                            
                            Spacer()
                            
                            VStack {
                                Image(systemName: "airplane")
                                    .font(.title)
                                    .foregroundColor(.blue)
                                if !flight.duration.isEmpty {
                                    Text(flight.duration)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text("Arrival")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(flight.arrival.airportCode.isEmpty ? "ARR" : flight.arrival.airportCode)
                                    .font(.title2)
                                    .bold()
                                if !flight.arrival.city.isEmpty {
                                    Text(flight.arrival.city)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                if !flight.arrival.date.isEmpty || !flight.arrival.time.isEmpty {
                                    Text("\(flight.arrival.date) \(flight.arrival.time)".trimmingCharacters(in: .whitespaces))
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Flight Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Flight Details")
                            .font(.headline)
                        
                        if !flight.aircraft.isEmpty {
                            DetailRowView(label: "Aircraft", value: flight.aircraft)
                        }
                        
                        if !flight.bookingClass.isEmpty {
                            DetailRowView(label: "Class", value: flight.bookingClass)
                        }
                        
                        DetailRowView(label: "Cost", value: flight.cost.displayText)
                        
                        if let seatRec = flight.seatRecommendations, !seatRec.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Seat Recommendations")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(seatRec)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let notes = flight.notes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Notes")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(notes)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(12)
                    
                    // Booking Information
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "creditcard")
                                .foregroundColor(.green)
                            Text("How to Book")
                                .font(.headline)
                        }
                        
                        VStack(spacing: 12) {
                            // Show specific booking instructions for this flight
                            if let bookingInstructions = flight.bookingInstructions, !bookingInstructions.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Booking Instructions:")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(bookingInstructions)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            // Online booking button if URL is available
                            if let bookingUrl = flight.bookingUrl, !bookingUrl.isEmpty {
                                Button(action: {
                                    if let url = URL(string: bookingUrl) {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "safari")
                                        Text("Book Online")
                                        Spacer()
                                        Text(flight.cost.displayText)
                                            .fontWeight(.bold)
                                        Image(systemName: "arrow.up.right")
                                    }
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                            }
                            
                            // Alternative booking methods
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Alternative Booking Methods:")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                HStack {
                                    Image(systemName: "phone")
                                    Text("Call airline directly for potential phone-only deals")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Image(systemName: "building.2")
                                    Text("Visit travel agent for complex itineraries")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            if flight.bookingUrl?.isEmpty ?? true && flight.bookingInstructions?.isEmpty ?? true {
                                Text("💡 Contact your travel consultant for booking assistance")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Flight Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
}

struct DetailRowView: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

struct DailyPlansView: View {
    let dailyPlans: [DailyPlan]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
                Text("Daily Itinerary")
                    .font(.title2)
                    .bold()
                Spacer()
            }
            
            ForEach(dailyPlans) { day in
                DayPlanView(day: day)
            }
        }
    }
}

struct DayPlanView: View {
    let day: DailyPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Day \(day.dayNumber)")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(day.title)
                        .font(.headline)
                        .bold()
                    if !day.date.isEmpty {
                        Text(day.date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if day.estimatedCost.totalCashValue > 0 {
                    FlexibleCostView(cost: day.estimatedCost, style: .green)
                        .font(.subheadline)
                        .bold()
                }
            }
            
            if !day.activities.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(day.activities) { activity in
                        DailyActivityView(activity: activity)
                    }
                }
            }
            
            if !day.transportation.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(day.transportation) { transport in
                        LocalTransportationView(transport: transport)
                    }
                }
            }
            
            if let notes = day.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(8)
    }
}

struct DailyActivityView: View {
    let activity: DailyActivity
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .center, spacing: 4) {
                if !activity.time.isEmpty {
                    Text(activity.time)
                        .font(.caption2)
                        .bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Image(systemName: activity.category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
            }
            .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.title)
                    .font(.subheadline)
                    .bold()
                
                Text(activity.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                
                HStack {
                    if !activity.duration.isEmpty {
                        Label(activity.duration, systemImage: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if activity.cost.totalCashValue > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: activity.cost.paymentType.icon)
                            Text(activity.cost.shortDisplayText)
                        }
                        .font(.caption2)
                        .foregroundColor(.green)
                    }
                    
                    if activity.bookingRequired {
                        Label("Booking Required", systemImage: "calendar.badge.exclamationmark")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct MajorTransportationView: View {
    let transportation: [LocalTransportation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "tram")
                    .foregroundColor(.blue)
                Text("Transportation")
                    .font(.title2)
                    .bold()
                Spacer()
            }
            
            ForEach(transportation) { transport in
                LocalTransportationView(transport: transport)
            }
        }
    }
}

struct LocalTransportationView: View {
    let transport: LocalTransportation
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .center, spacing: 4) {
                if !transport.time.isEmpty {
                    Text(transport.time)
                        .font(.caption2)
                        .bold()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                }
                
                Image(systemName: transport.method.icon)
                    .font(.system(size: 16))
                    .foregroundColor(.orange)
            }
            .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(transport.method.displayName): \(transport.from) → \(transport.to)")
                    .font(.subheadline)
                    .bold()
                
                if !transport.instructions.isEmpty {
                    Text(transport.instructions)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                HStack {
                    if !transport.duration.isEmpty {
                        Label(transport.duration, systemImage: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    if transport.cost.totalCashValue > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: transport.cost.paymentType.icon)
                            Text(transport.cost.shortDisplayText)
                        }
                        .font(.caption2)
                        .foregroundColor(.green)
                    }
                    
                    if let bookingUrl = transport.bookingUrl, !bookingUrl.isEmpty {
                        Label("Booking Available", systemImage: "link")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct AccommodationDetailsView: View {
    let accommodations: [AccommodationDetails]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "building.2")
                    .foregroundColor(.blue)
                Text("Accommodations")
                    .font(.title2)
                    .bold()
                Spacer()
            }
            
            ForEach(accommodations) { accommodation in
                AccommodationCardView(accommodation: accommodation)
            }
        }
    }
}

struct AccommodationCardView: View {
    let accommodation: AccommodationDetails
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(accommodation.name)
                        .font(.headline)
                        .bold()
                    Text(accommodation.type.displayName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    FlexibleCostView(cost: accommodation.cost, style: .green)
                        .font(.subheadline)
                        .bold()
                    Text("/night")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text("Check-in: \(accommodation.checkIn)")
                    .font(.caption)
                Spacer()
                Text("Check-out: \(accommodation.checkOut)")
                    .font(.caption)
                Text("(\(calculateNights(checkIn: accommodation.checkIn, checkOut: accommodation.checkOut, fallback: accommodation.nights)) nights)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if !accommodation.amenities.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(accommodation.amenities.prefix(5), id: \.self) { amenity in
                            Text(amenity)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            
            if !accommodation.bookingInstructions.isEmpty {
                Text(accommodation.bookingInstructions)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(8)
    }
    
    private func calculateNights(checkIn: String, checkOut: String, fallback: Int) -> Int {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let checkInDate = dateFormatter.date(from: checkIn),
              let checkOutDate = dateFormatter.date(from: checkOut) else {
            // If we can't parse the dates, use the fallback
            return max(1, fallback)
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: checkInDate, to: checkOutDate)
        return max(1, components.day ?? fallback)
    }
}

// MARK: - Flexible Cost Display Component
struct FlexibleCostView: View {
    let cost: FlexibleCost
    let style: CostStyle
    
    enum CostStyle {
        case green
        case white
        case primary
        
        var color: Color {
            switch self {
            case .green: return .green
            case .white: return .white
            case .primary: return .primary
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: cost.paymentType.icon)
                .font(.caption)
                .foregroundColor(style.color)
            
            switch cost.paymentType {
            case .cash:
                Text("$\(Int(cost.cashAmount))")
                    .foregroundColor(style.color)
                    
            case .points:
                if let points = cost.pointsAmount, let program = cost.pointsProgram {
                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(points.formatted())")
                            .foregroundColor(style.color)
                        Text(program.uppercased())
                            .font(.caption2)
                            .foregroundColor(style.color.opacity(0.8))
                    }
                } else {
                    Text("$\(Int(cost.cashAmount))")
                        .foregroundColor(style.color)
                }
                
            case .hybrid:
                if let points = cost.pointsAmount, let program = cost.pointsProgram {
                    VStack(alignment: .trailing, spacing: 1) {
                        HStack(spacing: 2) {
                            Text("$\(Int(cost.cashAmount))")
                            Text("+")
                            Text("\(points.formatted())")
                        }
                        Text(program.uppercased())
                            .font(.caption2)
                            .foregroundColor(style.color.opacity(0.8))
                    }
                    .foregroundColor(style.color)
                } else {
                    Text("$\(Int(cost.cashAmount))")
                        .foregroundColor(style.color)
                }
            }
        }
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
        TripDetailView(trip: TravelTrip(
            id: "preview",
            userId: "user123",
            destination: "Tokyo, Japan",
            destinations: ["Tokyo, Japan"],
            startDate: .init(date: Date()),
            endDate: .init(date: Date().addingTimeInterval(7*24*60*60)),
            paymentMethod: "Credit Card",
            flexibleDates: false,
            status: .completed,
            createdAt: .init(date: Date()),
            updatedAt: nil,
            recommendation: nil,
            flightClass: "Economy",
            budget: "5000",
            travelStyle: "Comfortable",
            groupSize: 2,
            interests: ["Culture", "Food"],
            specialRequests: "Looking for authentic experiences"
        ))
    }
}
