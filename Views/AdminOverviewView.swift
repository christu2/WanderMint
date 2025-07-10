import SwiftUI

struct AdminCostBreakdownView: View {
    let totalCost: AdminTotalCost
    let recommendation: AdminDestinationBasedRecommendation
    
    // Calculate costs dynamically like travelAdmin does
    private var calculatedCosts: (transportCash: Double, transportPoints: Int, accommodationCash: Double, accommodationPoints: Int) {
        var transportCash: Double = 0
        var transportPoints: Int = 0
        var accommodationCash: Double = 0
        var accommodationPoints: Int = 0
        
        // Calculate transportation costs (user selected option or highest priority option per segment)
        for segment in recommendation.logistics.transportSegments {
            if !segment.transportOptions.isEmpty {
                // Use selected transport option if available, otherwise fall back to highest priority
                let selectedOption: AdminTransportOption?
                
                // Check UserDefaults first, then data model, then default to priority
                let localSelection = UserDefaults.standard.string(forKey: "selected_transport_option_\(segment.id)")
                let selectedId = localSelection ?? segment.selectedOptionId
                
                if let id = selectedId {
                    selectedOption = segment.transportOptions.first { $0.id == id }
                } else {
                    selectedOption = segment.transportOptions.min { $0.priority < $1.priority }
                }
                
                if let option = selectedOption {
                    transportCash += option.cost.cashAmount
                    transportPoints += option.cost.pointsAmount ?? 0
                }
            }
        }
        
        // Calculate accommodation costs (user selected option or highest priority option per destination)
        for destination in recommendation.destinations {
            if !destination.accommodationOptions.isEmpty {
                // Use selected accommodation if available, otherwise fall back to highest priority
                let selectedAccommodation: AdminAccommodationOption?
                
                // Check UserDefaults first, then data model, then default to priority
                let localSelection = UserDefaults.standard.string(forKey: "selected_accommodation_\(destination.id)")
                let selectedId = localSelection ?? destination.selectedAccommodationId
                
                if let id = selectedId {
                    selectedAccommodation = destination.accommodationOptions.first { $0.id == id }
                } else {
                    selectedAccommodation = destination.accommodationOptions.min { $0.priority < $1.priority }
                }
                
                if let accommodation = selectedAccommodation {
                    let nights = destination.numberOfNights
                    accommodationCash += accommodation.hotel.pricePerNight * Double(nights)
                    accommodationPoints += (accommodation.hotel.pointsPerNight ?? 0) * nights
                }
            }
        }
        
        return (transportCash, transportPoints, accommodationCash, accommodationPoints)
    }
    
    private var totalCashEstimate: Double {
        let costs = calculatedCosts
        return costs.transportCash + costs.accommodationCash
    }
    
    private var totalPoints: Int {
        let costs = calculatedCosts
        return costs.transportPoints + costs.accommodationPoints
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Cost Breakdown")
                .font(.headline)
            
            // Total estimate - focus on cash and points for logistics & accommodation
            VStack(spacing: 12) {
                if totalCashEstimate > 0 {
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
                        Text("\(totalPoints) pts")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
            
            // Cost breakdown - only logistics and accommodations
            VStack(spacing: 8) {
                let costs = calculatedCosts
                AdminCostRow(label: "Transportation", amount: costs.transportCash, currency: totalCost.currency, points: costs.transportPoints)
                AdminCostRow(label: "Accommodation", amount: costs.accommodationCash, currency: totalCost.currency, points: costs.accommodationPoints)
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
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
                    Text("\(points) pts")
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