import SwiftUI

struct TripDetailView: View {
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
                
                // Recommendation Section - Use admin-compatible format
                if let destinationRecommendation = trip.destinationRecommendation {
                    AdminRecommendationView(
                        recommendation: destinationRecommendation, 
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
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: TripConversationView(trip: trip)) {
                    HStack(spacing: 4) {
                        Image(systemName: "message.circle.fill")
                        Text("Request Changes")
                            .font(.caption)
                    }
                    .foregroundColor(AppTheme.Colors.primary)
                }
            }
        }
        .onAppear {
            viewModel.loadTripDetails(tripId: initialTrip.id, initialTrip: initialTrip)
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
    let tripId: String
    let onBookingUpdate: () -> Void
    
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
                DetailedItineraryView(itinerary: itinerary, tripId: tripId, onBookingUpdate: onBookingUpdate)
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
    let tripId: String
    let onBookingUpdate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Unified Transportation (flights and trains chronologically)
            UnifiedTransportationView(itinerary: itinerary, tripId: tripId, onBookingUpdate: onBookingUpdate)
            
            // Daily Plans
            if !itinerary.dailyPlans.isEmpty {
                DailyPlansView(dailyPlans: itinerary.dailyPlans)
            }
            
            // Accommodations
            if !itinerary.accommodations.isEmpty {
                AccommodationDetailsView(accommodations: itinerary.accommodations, tripId: tripId, onBookingUpdate: onBookingUpdate)
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
    let tripId: String
    let onBookingUpdate: () -> Void
    
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
                    if let flightIndex = itinerary.flights.allFlights.firstIndex(where: { 
                        $0.flightNumber == flight.flightNumber && 
                        $0.airline == flight.airline && 
                        $0.departure.date == flight.departure.date 
                    }) {
                        FlightCardView(flight: flight, title: title, tripId: tripId, flightIndex: flightIndex, onBookingUpdate: onBookingUpdate)
                    } else {
                        FlightCardView(flight: flight, title: title, tripId: tripId, flightIndex: 0, onBookingUpdate: onBookingUpdate)
                    }
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
                        ClickableText(text: itinerary.flights.bookingInstructions, font: .caption, color: .secondary)
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
    let tripId: String
    let onBookingUpdate: () -> Void
    
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
                FlightCardView(flight: flight, title: title, tripId: tripId, flightIndex: index, onBookingUpdate: onBookingUpdate)
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
                        ClickableText(text: flights.bookingInstructions, font: .caption, color: .secondary)
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
    let tripId: String
    let flightIndex: Int
    let onBookingUpdate: () -> Void
    @State private var showDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                if let isBooked = flight.isBooked, isBooked {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        Text("BOOKED")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(8)
                }
            }
            
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
            FlightDetailsSheet(flight: flight, title: title, tripId: tripId, flightIndex: flightIndex, onBookingUpdate: onBookingUpdate)
        }
    }
}

struct FlightDetailsSheet: View {
    let flight: FlightDetails
    let title: String
    let tripId: String
    let flightIndex: Int
    let onBookingUpdate: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showBookingConfirmation = false
    @StateObject private var tripService = TripService()
    
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
                            // Enhanced booking buttons
                            VStack(spacing: 8) {
                                // Primary booking button - uses Google Flights URL from booking instructions
                                if let bookingInstructions = flight.bookingInstructions,
                                   let googleFlightsUrl = extractGoogleFlightsUrl(from: bookingInstructions) {
                                    Link(destination: URL(string: googleFlightsUrl)!) {
                                        HStack {
                                            Image(systemName: "airplane.departure")
                                            Text("Book with \(flight.airline)")
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
                                // Fallback to direct URL if Google Flights URL not found
                                else if let directUrl = flight.directAirlineBookingUrl {
                                    Link(destination: URL(string: directUrl)!) {
                                        HStack {
                                            Image(systemName: "airplane.departure")
                                            Text("Book with \(flight.airline)")
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
                                
                                // Manual booking URL if provided
                                if let bookingUrl = flight.bookingUrl, !bookingUrl.isEmpty {
                                    Link(destination: URL(string: bookingUrl)!) {
                                        HStack {
                                            Image(systemName: "safari")
                                            Text("Book Online")
                                            Spacer()
                                            Text(flight.cost.displayText)
                                                .fontWeight(.bold)
                                            Image(systemName: "arrow.up.right")
                                        }
                                        .padding()
                                        .background(Color.green)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                    }
                                }
                                
                                // Booking status section
                                if let isBooked = flight.isBooked, isBooked {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("✅ This flight has been booked")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.green)
                                        if let reference = flight.bookingReference, !reference.isEmpty {
                                            Text("Confirmation: \(reference)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        if let bookedDate = flight.bookedDate, !bookedDate.isEmpty {
                                            Text("Booked on: \(bookedDate)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding()
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(8)
                                } else {
                                    Button(action: {
                                        showBookingConfirmation = true
                                    }) {
                                        HStack {
                                            Image(systemName: "checkmark.circle")
                                            Text("Mark as Booked")
                                            Spacer()
                                            Image(systemName: "arrow.right")
                                        }
                                        .padding()
                                        .background(Color.orange)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                    }
                                }
                            }
                            
                            // Booking tips (extracted from booking instructions)
                            if let bookingInstructions = flight.bookingInstructions,
                               let tips = extractBookingTips(from: bookingInstructions), !tips.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("💡 Booking Tips:")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    Text(tips)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.yellow.opacity(0.1))
                                .cornerRadius(6)
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
        .sheet(isPresented: $showBookingConfirmation) {
            BookingConfirmationSheet(
                itemType: "Flight",
                itemName: "\(title) - \(flight.airline) \(flight.flightNumber)",
                onConfirm: { reference, date in
                    Task {
                        do {
                            try await tripService.updateFlightBookingStatus(
                                tripId: tripId,
                                flightIndex: flightIndex,
                                isBooked: true,
                                bookingReference: reference,
                                bookedDate: date
                            )
                            // Refresh the trip data to show updated booking status
                            await MainActor.run {
                                onBookingUpdate()
                            }
                        } catch {
                        }
                    }
                }
            )
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
                        LocalTransportCardView(transport: transport)
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
                LocalTransportCardView(transport: transport)
            }
        }
    }
}

struct LocalTransportCardView: View {
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
    let tripId: String
    let onBookingUpdate: () -> Void
    
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
            
            ForEach(Array(accommodations.enumerated()), id: \.element.id) { index, accommodation in
                AccommodationCardView(accommodation: accommodation, tripId: tripId, accommodationIndex: index, onBookingUpdate: onBookingUpdate)
            }
        }
    }
}

struct AccommodationCardView: View {
    let accommodation: AccommodationDetails
    let tripId: String
    let accommodationIndex: Int
    let onBookingUpdate: () -> Void
    @State private var selectedPhotoIndex = 0
    @State private var showBookingConfirmation = false
    @StateObject private var tripService = TripService()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AccommodationPhotosView(photos: accommodation.photos, selectedPhotoIndex: $selectedPhotoIndex)
            
            HStack {
                AccommodationHeaderView(accommodation: accommodation)
                Spacer()
                AccommodationPriceView(cost: accommodation.cost)
            }
            
            AccommodationRatingView(accommodation: accommodation)
            AccommodationInfoView(accommodation: accommodation)
            AccommodationAmenitiesView(accommodation: accommodation)
            AccommodationActionButtonsView(accommodation: accommodation)
            AccommodationBookingStatusView(
                accommodation: accommodation,
                showBookingConfirmation: $showBookingConfirmation
            )
            AccommodationBookingInstructionsView(accommodation: accommodation)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .cornerRadius(8)
        .sheet(isPresented: $showBookingConfirmation) {
            BookingConfirmationSheet(
                itemType: "Accommodation",
                itemName: accommodation.name,
                onConfirm: { reference, date in
                    Task {
                        do {
                            try await tripService.updateAccommodationBookingStatus(
                                tripId: tripId,
                                accommodationIndex: accommodationIndex,
                                isBooked: true,
                                bookingReference: reference,
                                bookedDate: date
                            )
                            // Refresh the trip data to show updated booking status
                            await MainActor.run {
                                onBookingUpdate()
                            }
                        } catch {
                        }
                    }
                }
            )
        }
    }
    
}

// MARK: - Accommodation Utilities
struct AccommodationUtils {
    static func calculateNights(checkIn: String, checkOut: String, fallback: Int) -> Int {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let checkInDate = dateFormatter.date(from: checkIn),
              let checkOutDate = dateFormatter.date(from: checkOut) else {
            return max(1, fallback)
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: checkInDate, to: checkOutDate)
        return max(1, components.day ?? fallback)
    }
}

// MARK: - Accommodation Helper Views
struct AccommodationHeaderView: View {
    let accommodation: AccommodationDetails
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(accommodation.name)
                    .font(.headline)
                    .bold()
                if let source = accommodation.source, source == "tripadvisor" {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
                if let source = accommodation.source, source == "airbnb" {
                    Image(systemName: "house.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            HStack {
                Text(accommodation.type.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Hotel-specific info
                if let hotelChain = accommodation.hotelChain {
                    Text("• \(hotelChain)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Airbnb-specific info
                if let propertyType = accommodation.propertyType {
                    Text("• \(propertyType)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let priceLevel = accommodation.priceLevel {
                    Text("• \(priceLevel)")
                        .font(.subheadline)
                        .foregroundColor(.purple)
                        .bold()
                }
            }
            
            // Airbnb host info
            if let hostName = accommodation.hostName {
                HStack {
                    Text("Host: \(hostName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if let isSuperhost = accommodation.hostIsSuperhost, isSuperhost {
                        Text("• Superhost")
                            .font(.caption)
                            .foregroundColor(.red)
                            .bold()
                    }
                }
            }
        }
    }
}

struct AccommodationPriceView: View {
    let cost: FlexibleCost
    
    var body: some View {
        VStack(alignment: .trailing) {
            FlexibleCostView(cost: cost, style: .green)
                .font(.subheadline)
                .bold()
            Text("/night")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct AccommodationPhotosView: View {
    let photos: [AccommodationPhoto]?
    @Binding var selectedPhotoIndex: Int
    
    var body: some View {
        if let photos = photos, !photos.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Hotel Photos")
                        .font(.subheadline)
                        .bold()
                    Spacer()
                    Text("\(selectedPhotoIndex + 1) of \(photos.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                TabView(selection: $selectedPhotoIndex) {
                    ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                        AsyncImage(url: URL(string: photo.url)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 160)
                                .clipped()
                                .cornerRadius(8)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 160)
                                .overlay(
                                    Image(systemName: "photo")
                                        .foregroundColor(.gray)
                                )
                        }
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .frame(height: 160)
            }
        }
    }
}

struct AccommodationRatingView: View {
    let accommodation: AccommodationDetails
    
    var body: some View {
        if let rating = accommodation.reviewRating, rating > 0 {
            HStack {
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= Int(rating.rounded()) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
                Text(String(format: "%.1f", rating))
                    .font(.caption)
                    .bold()
                
                if let numReviews = accommodation.numReviews, numReviews > 0 {
                    Text("(\(numReviews.formatted()) reviews)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
}

struct AccommodationInfoView: View {
    let accommodation: AccommodationDetails
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Check-in/Check-out dates
            HStack {
                Text("Check-in: \(accommodation.checkIn)")
                    .font(.caption)
                Spacer()
                Text("Check-out: \(accommodation.checkOut)")
                    .font(.caption)
                Text("(\(AccommodationUtils.calculateNights(checkIn: accommodation.checkIn, checkOut: accommodation.checkOut, fallback: accommodation.nights)) nights)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Airbnb property details
            if accommodation.source == "airbnb" {
                HStack {
                    if let bedrooms = accommodation.bedrooms {
                        Text("\(bedrooms) bed\(bedrooms == 1 ? "" : "s")")
                            .font(.caption)
                    }
                    if let bathrooms = accommodation.bathrooms {
                        Text("• \(bathrooms == floor(bathrooms) ? String(format: "%.0f", bathrooms) : String(format: "%.1f", bathrooms)) bath\(bathrooms == 1 ? "" : "s")")
                            .font(.caption)
                    }
                    if let maxGuests = accommodation.maxGuests {
                        Text("• \(maxGuests) guest\(maxGuests == 1 ? "" : "s")")
                            .font(.caption)
                    }
                    Spacer()
                    if let instantBook = accommodation.instantBook, instantBook {
                        Text("⚡ Instant Book")
                            .font(.caption)
                            .foregroundColor(.green)
                            .bold()
                    }
                }
                .foregroundColor(.secondary)
            }
            
            // Enhanced Description
            if let description = accommodation.detailedDescription, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .padding(.top, 4)
            }
            
            // Consultant Notes
            if let consultantNotes = accommodation.consultantNotes, !consultantNotes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Travel Consultant Recommendation:")
                        .font(.caption2)
                        .bold()
                        .foregroundColor(.blue)
                    Text(consultantNotes)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .italic()
                        .lineLimit(3)
                }
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(6)
            }
        }
    }
    
}

struct AccommodationAmenitiesView: View {
    let accommodation: AccommodationDetails
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !accommodation.amenities.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(accommodation.amenities.prefix(8), id: \.self) { amenity in
                            Text(amenity)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(4)
                        }
                        if accommodation.amenities.count > 8 {
                            Text("+\(accommodation.amenities.count - 8) more")
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                    .padding(.horizontal, 1)
                }
            }
            
            // House Rules (Airbnb)
            if let houseRules = accommodation.houseRules, !houseRules.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("House Rules:")
                        .font(.caption2)
                        .bold()
                        .foregroundColor(.orange)
                    ForEach(houseRules.prefix(3), id: \.self) { rule in
                        Text("• \(rule)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    if houseRules.count > 3 {
                        Text("• +\(houseRules.count - 3) more rules")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
            }
        }
    }
}

struct AccommodationActionButtonsView: View {
    let accommodation: AccommodationDetails
    
    var body: some View {
        HStack(spacing: 12) {
            if let tripadvisorUrl = accommodation.tripadvisorUrl, !tripadvisorUrl.isEmpty,
               let url = URL(string: tripadvisorUrl) {
                Link("View on TripAdvisor", destination: url)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
            
            if let airbnbUrl = accommodation.airbnbUrl, !airbnbUrl.isEmpty,
               let url = URL(string: airbnbUrl) {
                Link("View on Airbnb", destination: url)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
            
            if let bookingUrl = accommodation.bookingUrl, !bookingUrl.isEmpty,
               let url = URL(string: bookingUrl) {
                Link("Book Direct", destination: url)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
        }
    }
}

struct AccommodationBookingStatusView: View {
    let accommodation: AccommodationDetails
    @Binding var showBookingConfirmation: Bool
    
    var body: some View {
        if let isBooked = accommodation.isBooked, isBooked {
            VStack(alignment: .leading, spacing: 4) {
                Text("✅ This accommodation has been booked")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
                if let reference = accommodation.bookingReference, !reference.isEmpty {
                    Text("Confirmation: \(reference)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(8)
            .background(Color.green.opacity(0.1))
            .cornerRadius(6)
        } else {
            Button(action: {
                showBookingConfirmation = true
            }) {
                HStack {
                    Image(systemName: "checkmark.circle")
                    Text("Mark as Booked")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
    }
}

struct AccommodationBookingInstructionsView: View {
    let accommodation: AccommodationDetails
    
    var body: some View {
        if !accommodation.bookingInstructions.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text("Booking Instructions:")
                    .font(.caption)
                    .fontWeight(.medium)
                ClickableText(text: accommodation.bookingInstructions, font: .caption, color: .secondary)
            }
        }
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
    @Published var trip: TravelTrip?
    
    private let tripService = TripService()
    
    func loadTripDetails(tripId: String, initialTrip: TravelTrip? = nil) {
        Task {
            do {
                isLoading = true
                errorMessage = nil
                
                // Set initial trip immediately if provided
                if let initialTrip = initialTrip, trip == nil {
                    trip = initialTrip
                }
                
                let fetchedTrip = try await tripService.fetchTrip(tripId: tripId)
                
                // Always update with fetched data - don't reject trips without recommendations
                if let fetchedTrip = fetchedTrip {
                    trip = fetchedTrip
                    
                    // Log if recommendation data is missing for debugging
                    if fetchedTrip.destinationRecommendation == nil && fetchedTrip.recommendation == nil {
                        Logger.info("Trip \(fetchedTrip.id) loaded without recommendation data", category: Logger.ui)
                    }
                } else if trip == nil && initialTrip != nil {
                    // If fetch returned nil but we have initial data, use it
                    trip = initialTrip
                }
                
            } catch {
                errorMessage = error.localizedDescription
                
                // On error, ensure we have some trip data if possible
                if trip == nil && initialTrip != nil {
                    trip = initialTrip
                }
            }
            isLoading = false
        }
    }
    
    func refreshTrip() {
        guard let currentTrip = trip else { return }
        // Pass the current trip as initial trip to preserve data if fetch fails
        loadTripDetails(tripId: currentTrip.id, initialTrip: currentTrip)
    }
}

// MARK: - URL Detection and Clickable Text
struct ClickableText: View {
    let text: String
    let font: Font
    let color: Color
    
    var body: some View {
        let urlPattern = #"(https?://[^\s]+)"#
        let _ = NSMutableAttributedString(string: text)
        
        if let regex = try? NSRegularExpression(pattern: urlPattern, options: .caseInsensitive) {
            let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
            
            if matches.isEmpty {
                // No URLs found, display as regular text
                Text(text)
                    .font(font)
                    .foregroundColor(color)
            } else {
                // URLs found, create clickable text
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(text.components(separatedBy: .whitespacesAndNewlines).enumerated()), id: \.offset) { index, word in
                        if word.contains("http") {
                            Link(word, destination: URL(string: word) ?? URL(string: "https://google.com")!)
                                .font(font)
                                .foregroundColor(.blue)
                        } else if !word.isEmpty {
                            Text(word)
                                .font(font)
                                .foregroundColor(color)
                        }
                    }
                }
            }
        } else {
            Text(text)
                .font(font)
                .foregroundColor(color)
        }
    }
}

// MARK: - Booking Status Tracking
struct BookingStatusBadge: View {
    let isBooked: Bool?
    let bookingReference: String?
    
    var body: some View {
        if let isBooked = isBooked, isBooked {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("BOOKED")
                    .font(.caption2)
                    .fontWeight(.bold)
                if let reference = bookingReference, !reference.isEmpty {
                    Text("(\(reference))")
                        .font(.caption2)
                }
            }
            .foregroundColor(.green)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

// MARK: - Booking Confirmation Sheet
struct BookingConfirmationSheet: View {
    let itemType: String?
    let itemName: String?
    let title: String?
    let onConfirm: (String, String) -> Void
    
    // Convenience initializers
    init(itemType: String, itemName: String, onConfirm: @escaping (String, String) -> Void) {
        self.itemType = itemType
        self.itemName = itemName
        self.title = nil
        self.onConfirm = onConfirm
    }
    
    init(title: String, onConfirm: @escaping (String, String) -> Void) {
        self.itemType = nil
        self.itemName = nil
        self.title = title
        self.onConfirm = onConfirm
    }
    
    @State private var bookingReference = ""
    @State private var bookingDate = Date()
    @Environment(\.dismiss) private var dismiss
    
    private var displayTitle: String {
        if let title = title {
            return title
        } else if let itemType = itemType {
            return "Mark \(itemType) as Booked"
        } else {
            return "Mark as Booked"
        }
    }
    
    private var displayItemName: String {
        return itemName ?? title ?? ""
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(displayTitle)
                    .font(.headline)
                
                Text(displayItemName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Booking Reference")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("Confirmation number", text: $bookingReference)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("Booking Date")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    DatePicker("", selection: $bookingDate, displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                }
                .padding()
                
                Spacer()
                
                Button("Confirm Booking") {
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd"
                    onConfirm(bookingReference, formatter.string(from: bookingDate))
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(bookingReference.isEmpty)
            }
            .padding()
            .navigationTitle("Booking Status")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
            )
        }
    }
}

#Preview {
    NavigationView {
        TripDetailView(initialTrip: TravelTrip(
            id: "preview",
            userId: "user123",
            destination: "Tokyo, Japan",
            destinations: ["Tokyo, Japan"],
            departureLocation: "New York, NY",
            startDate: .init(date: Date()),
            endDate: .init(date: Date().addingTimeInterval(7*24*60*60)),
            paymentMethod: "Credit Card",
            flexibleDates: false,
            status: .completed,
            createdAt: .init(date: Date()),
            updatedAt: nil,
            recommendation: nil,
            destinationRecommendation: nil,
            flightClass: "Economy",
            budget: "5000",
            travelStyle: "Comfortable",
            groupSize: 2,
            interests: ["Culture", "Food"],
            specialRequests: "Looking for authentic experiences"
        ))
    }
}

// MARK: - Helper Functions
func extractGoogleFlightsUrl(from text: String) -> String? {
    // Look for Google Flights URL in the booking instructions
    let pattern = "https://www\\.google\\.com/travel/flights[^\\s]*"
    let regex = try? NSRegularExpression(pattern: pattern, options: [])
    let range = NSRange(location: 0, length: text.utf16.count)
    
    if let match = regex?.firstMatch(in: text, options: [], range: range) {
        if let swiftRange = Range(match.range, in: text) {
            return String(text[swiftRange])
        }
    }
    return nil
}

func extractBookingTips(from text: String) -> String? {
    // Extract the "Tip:" section from booking instructions
    if let tipRange = text.range(of: "Tip:") {
        let tipsSection = String(text[tipRange.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
        return tipsSection.isEmpty ? nil : tipsSection
    }
    return nil
}

// MARK: - Destination-Based Recommendation View
struct DestinationBasedRecommendationView: View {
    let recommendation: DestinationBasedRecommendation
    let tripId: String
    let onBookingUpdate: () -> Void
    
    @State private var selectedTab: TabType = .destinations
    @State private var selectedDestination: String = ""
    
    enum TabType: CaseIterable {
        case destinations, logistics, overview
        
        var title: String {
            switch self {
            case .destinations: return "Destinations"
            case .logistics: return "Logistics"
            case .overview: return "Overview"
            }
        }
        
        var icon: String {
            switch self {
            case .destinations: return "map"
            case .logistics: return "airplane"
            case .overview: return "doc.text"
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Tab Selection
            HStack(spacing: 0) {
                ForEach(TabType.allCases, id: \.title) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 16))
                            Text(tab.title)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedTab == tab ? Color.blue.opacity(0.1) : Color.clear)
                        .foregroundColor(selectedTab == tab ? .blue : .secondary)
                    }
                }
            }
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
            
            // Tab Content
            TabView(selection: $selectedTab) {
                DestinationsTabView(
                    destinations: recommendation.destinations,
                    tripId: tripId,
                    onBookingUpdate: onBookingUpdate
                )
                .tag(TabType.destinations)
                
                LogisticsTabView(
                    logistics: recommendation.logistics,
                    tripId: tripId,
                    onBookingUpdate: onBookingUpdate
                )
                .tag(TabType.logistics)
                
                OverviewTabView(
                    recommendation: recommendation
                )
                .tag(TabType.overview)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
        .onAppear {
            if !recommendation.destinations.isEmpty {
                selectedDestination = recommendation.destinations[0].cityName
            }
        }
    }
}

// MARK: - Destinations Tab View
struct DestinationsTabView: View {
    let destinations: [DestinationRecommendation]
    let tripId: String
    let onBookingUpdate: () -> Void
    
    @State private var selectedDestination: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if destinations.isEmpty {
                // Empty state for when no destinations are available
                VStack(spacing: 12) {
                    Image(systemName: "map")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("Destinations Coming Soon")
                        .font(.headline)
                    Text("Your personalized destination recommendations will appear here once your trip planning is complete.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            } else {
                if destinations.count > 1 {
                    // City selector for multi-city trips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(destinations.enumerated()), id: \.element.id) { index, destination in
                                Button(action: {
                                    selectedDestination = index
                                }) {
                                    VStack(spacing: 4) {
                                        Text(destination.cityName)
                                            .font(.headline)
                                            .fontWeight(selectedDestination == index ? .bold : .medium)
                                        Text("\(destination.numberOfNights) nights")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedDestination == index ? Color.blue.opacity(0.1) : Color.clear)
                                    .foregroundColor(selectedDestination == index ? .blue : .primary)
                                    .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Selected destination content
                if selectedDestination < destinations.count {
                    let destination = destinations[selectedDestination]
                    
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Hotel Options Section
                            HotelOptionsView(
                                destination: destination,
                                tripId: tripId,
                                onBookingUpdate: onBookingUpdate
                            )
                            
                            // Daily Itinerary Section
                            DailyItineraryView(
                                dailyPlans: destination.dailyItinerary,
                                cityName: destination.cityName
                            )
                            
                            // Local Transportation Section
                            LocalTransportationView(
                                transportOptions: destination.localTransportation
                            )
                        }
                        .padding()
                    }
                }
            }
        }
    }
}

// MARK: - Logistics Tab View
struct LogisticsTabView: View {
    let logistics: LogisticsRecommendation
    let tripId: String
    let onBookingUpdate: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Your Transportation Timeline")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                if logistics.transportSegments.isEmpty && logistics.generalInstructions.isEmpty {
                    // Empty state for when no logistics are available
                    VStack(spacing: 12) {
                        Image(systemName: "airplane")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Transportation Plan Coming Soon")
                            .font(.headline)
                        Text("Your personalized transportation recommendations will appear here once your trip planning is complete.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                } else {
                    ForEach(logistics.transportSegments) { segment in
                        TransportSegmentView(
                            segment: segment,
                            tripId: tripId,
                            onBookingUpdate: onBookingUpdate
                        )
                    }
                    
                    if !logistics.generalInstructions.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("General Instructions")
                                .font(.headline)
                            Text(logistics.generalInstructions)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
            }
        }
    }
}

// MARK: - Overview Tab View
struct OverviewTabView: View {
    let recommendation: DestinationBasedRecommendation
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Trip Overview")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if recommendation.tripOverview.isEmpty {
                    // Empty state for when no overview is available
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("Overview Coming Soon")
                            .font(.headline)
                        Text("Your personalized trip overview will appear here once your trip planning is complete.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                } else {
                    Text(recommendation.tripOverview)
                        .font(.body)
                }
                
                // Cost Summary - only show if there are actual costs
                if recommendation.totalCost.totalEstimate > 0 {
                    CostBreakdownView(cost: recommendation.totalCost)
                }
            }
            .padding()
        }
    }
}

// MARK: - Hotel Options View
struct HotelOptionsView: View {
    let destination: DestinationRecommendation
    let tripId: String
    let onBookingUpdate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "building.2")
                    .foregroundColor(.blue)
                Text("Hotels in \(destination.cityName)")
                    .font(.headline)
            }
            
            if destination.accommodationOptions.isEmpty {
                Text("No hotel recommendations available")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(destination.accommodationOptions) { option in
                    AccommodationOptionCard(
                        option: option,
                        tripId: tripId,
                        onBookingUpdate: onBookingUpdate
                    )
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Accommodation Option Card
struct AccommodationOptionCard: View {
    let option: AccommodationOption
    let tripId: String
    let onBookingUpdate: () -> Void
    
    @State private var showBookingSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            hotelHeaderView
            hotelCostView
            hotelDescriptionView
            bookingStatusView
        }
        .padding()
        .background(cardBackgroundColor)
        .overlay(cardBorderOverlay)
        .cornerRadius(8)
        .sheet(isPresented: $showBookingSheet) {
            BookingConfirmationSheet(
                title: "Book \(option.hotel.name)",
                onConfirm: { reference, date in
                    // TODO: Implement accommodation booking
                    onBookingUpdate()
                }
            )
        }
    }
    
    private var hotelHeaderView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(option.hotel.name)
                    .font(.headline)
                Text(option.hotel.location.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if option.priority == 1 {
                Text("RECOMMENDED")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .cornerRadius(4)
            }
        }
    }
    
    private var hotelCostView: some View {
        Text(option.hotel.cost.displayText)
            .font(.subheadline)
            .fontWeight(.medium)
    }
    
    @ViewBuilder
    private var hotelDescriptionView: some View {
        if let description = option.hotel.detailedDescription, !description.isEmpty {
            Text(description)
                .font(.body)
                .lineLimit(3)
        }
    }
    
    @ViewBuilder
    private var bookingStatusView: some View {
        if option.isBooked {
            bookedStatusView
        } else if option.isSelected {
            selectedStatusView
        } else {
            unselectedStatusView
        }
    }
    
    private var bookedStatusView: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            VStack(alignment: .leading) {
                Text("✅ Booked")
                    .fontWeight(.medium)
                if let reference = option.bookingReference {
                    Text("Ref: \(reference)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var selectedStatusView: some View {
        Button("Mark as Booked") {
            showBookingSheet = true
        }
        .buttonStyle(.borderedProminent)
    }
    
    private var unselectedStatusView: some View {
        Button("Select This Hotel") {
            // TODO: Implement hotel selection
        }
        .buttonStyle(.bordered)
    }
    
    private var cardBackgroundColor: Color {
        option.isSelected ? Color.blue.opacity(0.1) : Color.white
    }
    
    private var cardBorderOverlay: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(option.isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: option.isSelected ? 2 : 1)
    }
}

// MARK: - Transport Segment View (Placeholder)
struct TransportSegmentView: View {
    let segment: TransportSegment
    let tripId: String
    let onBookingUpdate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(segment.date)
                    .font(.headline)
                    .foregroundColor(.blue)
                Spacer()
                Text(segment.route)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Text("Transport options coming soon...")
                .font(.body)
                .foregroundColor(.secondary)
                .italic()
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Daily Itinerary View
struct DailyItineraryView: View {
    let dailyPlans: [DailyPlan]
    let cityName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Itinerary")
                .font(.headline)
                .fontWeight(.bold)
            
            if dailyPlans.isEmpty {
                Text("Daily itinerary will be available once your trip planning is complete.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            } else {
                ForEach(dailyPlans) { plan in
                    DailyPlanCard(plan: plan)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Daily Plan Card
struct DailyPlanCard: View {
    let plan: DailyPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Day \(plan.dayNumber)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(plan.date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !plan.title.isEmpty {
                Text(plan.title)
                    .font(.title3)
                    .fontWeight(.medium)
            }
            
            // Activities
            if !plan.activities.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Activities")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    
                    ForEach(plan.activities) { activity in
                        HStack {
                            Text(activity.time)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 60, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(activity.title)
                                    .font(.body)
                                    .fontWeight(.medium)
                                
                                if !activity.description.isEmpty {
                                    Text(activity.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            
                            Spacer()
                            
                            Text(activity.cost.shortDisplayText)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Estimated Cost
            HStack {
                Text("Estimated Daily Cost:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(plan.estimatedCost.displayText)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            if let notes = plan.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Local Transportation Options View (Multiple Options)
struct LocalTransportationView: View {
    let transportOptions: [LocalTransportOption]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Local Transportation")
                .font(.headline)
                .fontWeight(.bold)
            
            if transportOptions.isEmpty {
                Text("Local transportation options will be available once your trip planning is complete.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
            } else {
                ForEach(transportOptions) { option in
                    LocalTransportOptionCard(option: option)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// MARK: - Local Transport Option Card
struct LocalTransportOptionCard: View {
    let option: LocalTransportOption
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: option.transportation.method.icon)
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(option.transportation.method.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("\(option.transportation.from) → \(option.transportation.to)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if option.isRecommended {
                    Text("RECOMMENDED")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green)
                        .cornerRadius(4)
                }
            }
            
            HStack {
                Text("Duration: \(option.transportation.duration)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(option.transportation.cost.shortDisplayText)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            if !option.transportation.instructions.isEmpty {
                Text(option.transportation.instructions)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            if let notes = option.notes, !notes.isEmpty {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(option.isRecommended ? Color.green : Color.clear, lineWidth: 2)
        )
    }
}

