import SwiftUI

struct AdminCostBreakdownView: View {
    let totalCost: AdminTotalCost
    let recommendation: AdminDestinationBasedRecommendation
    
    // Calculate costs dynamically like travelAdmin does
    private var calculatedCosts: (transportCash: Double, transportPoints: Int, accommodationCash: Double, accommodationPoints: Int, pointsByProgram: [String: Int]) {
        var transportCash: Double = 0
        var transportPoints: Int = 0
        var accommodationCash: Double = 0
        var accommodationPoints: Int = 0
        var pointsByProgram: [String: Int] = [:]
        
        // Calculate transportation costs (user selected option or highest priority option per segment)
        for segment in recommendation.logistics.transportSegments {
            if !segment.transportOptions.isEmpty {
                let selectedOption: AdminTransportOption?
                let localSelection = UserDefaults.standard.string(forKey: "selected_transport_option_\(segment.id)")
                let selectedId = localSelection ?? segment.selectedOptionId
                
                if let id = selectedId {
                    selectedOption = segment.transportOptions.first { $0.id == id }
                } else {
                    selectedOption = segment.transportOptions.min { $0.priority < $1.priority }
                }
                
                if let option = selectedOption {
                    transportCash += option.cost.cashAmount
                    let pts = option.cost.pointsAmount ?? 0
                    transportPoints += pts
                    if pts > 0 {
                        let program = (option.cost.pointsProgram?.isEmpty == false) ? option.cost.pointsProgram! : "Airline/Transfer"
                        pointsByProgram[program, default: 0] += pts
                    }
                }
            }
        }
        
        // Calculate accommodation costs (user selected option or highest priority option per destination)
        for destination in recommendation.destinations {
            if !destination.accommodationOptions.isEmpty {
                let selectedAccommodation: AdminAccommodationOption?
                let localSelection = UserDefaults.standard.string(forKey: "selected_accommodation_\(destination.id)")
                let selectedId = localSelection ?? destination.selectedAccommodationId
                
                if let id = selectedId {
                    selectedAccommodation = destination.accommodationOptions.first { $0.id == id }
                } else {
                    selectedAccommodation = destination.accommodationOptions.min { $0.priority < $1.priority }
                }
                
                if let accommodation = selectedAccommodation {
                    let nights = max(1, destination.numberOfNights)
                    accommodationCash += accommodation.hotel.pricePerNight * Double(nights)
                    let pts = (accommodation.hotel.pointsPerNight ?? 0) * nights
                    accommodationPoints += pts
                    if pts > 0 {
                        let program = (accommodation.hotel.loyaltyProgram?.isEmpty == false) ? accommodation.hotel.loyaltyProgram! : "Hotel Points"
                        pointsByProgram[program, default: 0] += pts
                    }
                }
            }
        }
        
        if pointsByProgram.isEmpty, let explicitPoints = totalCost.pointsUsed {
            pointsByProgram = explicitPoints
        }
        
        return (transportCash, transportPoints, accommodationCash, accommodationPoints, pointsByProgram)
    }
    
    private var totalCashEstimate: Double {
        let costs = calculatedCosts
        let computed = costs.transportCash + costs.accommodationCash
        return computed > 0 ? computed : totalCost.totalEstimate
    }
    
    private var totalPoints: Int {
        let costs = calculatedCosts
        let computed = costs.transportPoints + costs.accommodationPoints
        if computed > 0 { return computed }
        return costs.pointsByProgram.values.reduce(0, +)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cost & Points Breakdown")
                .font(.headline)
            
            // Total estimate - focus on cash and points for logistics & accommodation
            VStack(spacing: 12) {
                if totalCashEstimate > 0 || totalPoints == 0 {
                    HStack {
                        Text("Total Cash Estimate")
                            .font(.title3)
                            .bold()
                        Spacer()
                        Text("$\(Int(totalCashEstimate)) \(totalCost.currency)")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.green)
                    }
                }
                
                if totalPoints > 0 {
                    HStack {
                        Text("Total Points Estimate")
                            .font(.title3)
                            .bold()
                        Spacer()
                        Text("\(totalPoints.formatted()) pts")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            
            // Category Breakdown
            VStack(spacing: 8) {
                let costs = calculatedCosts
                AdminCostRow(label: "Transportation", amount: costs.transportCash, currency: totalCost.currency, points: costs.transportPoints)
                AdminCostRow(label: "Accommodation", amount: costs.accommodationCash, currency: totalCost.currency, points: costs.accommodationPoints)
                if totalCost.activities > 0 {
                    AdminCostRow(label: "Activities", amount: totalCost.activities, currency: totalCost.currency)
                }
                if totalCost.food > 0 {
                    AdminCostRow(label: "Dining & Food", amount: totalCost.food, currency: totalCost.currency)
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
            
            // Per-Program Points Breakdown
            let programs = calculatedCosts.pointsByProgram.sorted { $0.key < $1.key }
            if !programs.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "creditcard.fill")
                            .foregroundColor(.blue)
                        Text("Points Required by Program")
                            .font(.subheadline)
                            .bold()
                    }
                    
                    ForEach(programs, id: \.key) { program, pts in
                        HStack {
                            Text(program)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(pts.formatted()) pts")
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.06))
                .cornerRadius(12)
            }
            
            // Points Strategy / Cost Notes
            if let costNotes = recommendation.costNotes, !costNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("Points & Booking Strategy")
                            .font(.subheadline)
                            .bold()
                    }
                    Text(costNotes)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.purple.opacity(0.08))
                .cornerRadius(12)
            }
            
            if let specialNotes = recommendation.specialNotes, !specialNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "note.text")
                            .foregroundColor(.orange)
                        Text("Additional Notes")
                            .font(.subheadline)
                            .bold()
                    }
                    Text(specialNotes)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.orange.opacity(0.08))
                .cornerRadius(12)
            }
        }
    }
}

struct AdminCostRow: View {
    let label: String
    let amount: Double
    let currency: String
    let points: Int
    
    init(label: String, amount: Double, currency: String, points: Int = 0) {
        self.label = label
        self.amount = amount
        self.currency = currency
        self.points = points
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.body)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if amount > 0 {
                    Text("$\(Int(amount)) \(currency)")
                        .font(.body)
                        .bold()
                }
                if points > 0 {
                    Text("\(points.formatted()) pts")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                if amount == 0 && points == 0 {
                    Text("--")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

struct AdminTripSummaryView: View {
    let destinations: [AdminDestination]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trip Summary")
                .font(.headline)
            
            ForEach(destinations) { destination in
                AdminDestinationSummaryView(destination: destination)
            }
        }
    }
}

struct AdminDestinationSummaryView: View {
    let destination: AdminDestination
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Destination header
            HStack {
                Text(destination.cityName)
                    .font(.subheadline)
                    .bold()
                Spacer()
                Text("\(destination.numberOfNights) nights")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Text("\(destination.arrivalDate) - \(destination.departureDate)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let overview = destination.overview, !overview.isEmpty {
                Text(overview)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Quick stats
            HStack(spacing: 16) {
                if !destination.accommodationOptions.isEmpty {
                    AdminSummaryStatView(
                        icon: "bed.double",
                        label: "Hotels",
                        value: "\(destination.accommodationOptions.count)"
                    )
                }
                
                if !destination.recommendedActivities.isEmpty {
                    AdminSummaryStatView(
                        icon: "map",
                        label: "Activities",
                        value: "\(destination.recommendedActivities.count)"
                    )
                }
                
                if !destination.recommendedRestaurants.isEmpty {
                    AdminSummaryStatView(
                        icon: "fork.knife",
                        label: "Restaurants",
                        value: "\(destination.recommendedRestaurants.count)"
                    )
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

struct AdminSummaryStatView: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.blue)
            
            Text(value)
                .font(.caption)
                .bold()
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
