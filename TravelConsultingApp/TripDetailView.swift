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
            // Flight Information
            FlightItineraryView(flights: itinerary.flights)
            
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
                CostBreakdownView(cost: itinerary.totalCost)
            }
        }
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
            
            FlightCardView(flight: flights.outbound, title: "Outbound Flight")
            
            if let returnFlight = flights.returnFlight {
                FlightCardView(flight: returnFlight, title: "Return Flight")
            }
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Total Flight Cost:")
                        .font(.headline)
                    Spacer()
                    FlexibleCostView(cost: flights.totalFlightCost, style: .green)
                        .font(.headline)
                }
                
                if !flights.bookingDeadline.isEmpty {
                    Text("Book by: \(flights.bookingDeadline)")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
                
                if !flights.bookingInstructions.isEmpty {
                    Text(flights.bookingInstructions)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

struct FlightCardView: View {
    let flight: FlightDetails
    let title: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("\(flight.departure.airportCode)")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    Text(flight.departure.city)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Text("\(flight.departure.date) \(flight.departure.time)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
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
                    Text("\(flight.arrival.airportCode)")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)
                    Text(flight.arrival.city)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    Text("\(flight.arrival.date) \(flight.arrival.time)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            HStack {
                Text("\(flight.airline) \(flight.flightNumber)")
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
                Text("(\(accommodation.nights) nights)")
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
