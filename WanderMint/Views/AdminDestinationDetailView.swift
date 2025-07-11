import SwiftUI

struct AdminDestinationDetailView: View {
    let destination: AdminDestination
    let tripId: String
    let onBookingUpdate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Destination Header
            VStack(alignment: .leading, spacing: 8) {
                Text(destination.cityName)
                    .font(.title2)
                    .bold()
                
                HStack {
                    Text("\(destination.arrivalDate) - \(destination.departureDate)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(destination.numberOfNights) nights")
                        .font(.subheadline)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
            
            // Accommodations
            if !destination.accommodationOptions.isEmpty {
                AdminAccommodationsSectionView(
                    destination: destination,
                    tripId: tripId,
                    onBookingUpdate: onBookingUpdate,
                    onAccommodationSelection: { accommodationId in
                        // Save selection locally for persistence across tab switches
                        UserDefaults.standard.set(accommodationId, forKey: "selected_accommodation_\(destination.id)")
                        onBookingUpdate()
                    }
                )
            }
            
            // Activities
            if !destination.recommendedActivities.isEmpty {
                AdminActivitiesSectionView(activities: destination.recommendedActivities)
            }
            
            // Restaurants
            if !destination.recommendedRestaurants.isEmpty {
                AdminRestaurantsSectionView(restaurants: destination.recommendedRestaurants)
            }
        }
    }
}

struct AdminAccommodationsSectionView: View {
    let destination: AdminDestination
    let tripId: String
    let onBookingUpdate: () -> Void
    let onAccommodationSelection: (String) -> Void
    
    @State private var showAllOptions: Bool = true
    
    private var accommodations: [AdminAccommodationOption] {
        destination.accommodationOptions
    }
    
    private var selectedAccommodationId: String? {
        // First check UserDefaults for local selection, then fall back to data model
        UserDefaults.standard.string(forKey: "selected_accommodation_\(destination.id)") ?? destination.selectedAccommodationId
    }
    
    private var sortedAccommodations: [AdminAccommodationOption] {
        accommodations.sorted { acc1, acc2 in
            acc1.priority < acc2.priority
        }
    }
    
    private var displayedAccommodations: [AdminAccommodationOption] {
        if showAllOptions || selectedAccommodationId == nil {
            return sortedAccommodations
        } else {
            return sortedAccommodations.filter { $0.id == selectedAccommodationId }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Accommodations")
                    .font(.headline)
                
                Spacer()
                
                if accommodations.count > 1 {
                    Text("\(accommodations.count) options available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Selection status
            if selectedAccommodationId != nil && !showAllOptions {
                HStack {
                    Text("1 accommodation selected")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Button("Show All Options") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showAllOptions = true
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            ForEach(displayedAccommodations) { accommodation in
                AdminHotelCardView(
                    accommodation: accommodation,
                    isSelected: accommodation.id == selectedAccommodationId,
                    showSelection: accommodations.count > 1,
                    tripId: tripId,
                    onSelection: { accommodationId in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showAllOptions = false
                        }
                        onAccommodationSelection(accommodationId)
                        onBookingUpdate()
                    },
                    onBookingUpdate: onBookingUpdate
                )
            }
        }
        .onAppear {
            // Show all options initially if no selection has been made
            if selectedAccommodationId == nil {
                showAllOptions = true
            } else {
                // If we have a selection, hide other options
                showAllOptions = false
            }
        }
    }
}

struct AdminHotelCardView: View {
    let accommodation: AdminAccommodationOption
    let isSelected: Bool
    let showSelection: Bool
    let tripId: String
    let onSelection: (String) -> Void
    let onBookingUpdate: () -> Void
    
    @State private var showingHotelDetails = false
    
    private var borderColor: Color {
        if isSelected { return .green }
        if accommodation.priority == 1 { return .blue }
        return .gray.opacity(0.3)
    }
    
    private var backgroundColor: Color {
        if isSelected { return .green.opacity(0.1) }
        if accommodation.priority == 1 { return .blue.opacity(0.05) }
        return Color(UIColor.systemGray6)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Hotel header with selection
            HStack {
                if showSelection {
                    Button(action: {
                        onSelection(accommodation.id)
                    }) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? .green : .gray)
                            .font(.system(size: 20))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(accommodation.hotel.name)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if accommodation.priority == 1 && !isSelected {
                            Text("Recommended")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                        
                        if isSelected {
                            Text("Selected")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        }
                    }
                    
                    HStack {
                        // Star rating
                        HStack(spacing: 2) {
                            ForEach(0..<Int(accommodation.hotel.rating), id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                            if accommodation.hotel.rating.truncatingRemainder(dividingBy: 1) > 0 {
                                Image(systemName: "star.leadinghalf.filled")
                                    .foregroundColor(.yellow)
                                    .font(.caption)
                            }
                        }
                        
                        Text(String(format: "%.1f", accommodation.hotel.rating))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(accommodation.hotel.location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(Int(accommodation.hotel.pricePerNight))/night")
                        .font(.headline)
                        .bold()
                        .foregroundColor(isSelected ? .green : .primary)
                    
                    if let points = accommodation.hotel.pointsPerNight, points > 0,
                       let program = accommodation.hotel.loyaltyProgram {
                        Text("\(points) \(program) pts")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Text("Priority \(accommodation.priority)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Description
            if !accommodation.hotel.detailedDescription.isEmpty {
                Text(accommodation.hotel.detailedDescription)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            
            // Action buttons
            HStack {
                // View details button
                Button(action: {
                    showingHotelDetails = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle.fill")
                        Text("View Hotel Details")
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Book hotel button
                if !accommodation.hotel.bookingUrl.isEmpty {
                    Link(destination: URL(string: accommodation.hotel.bookingUrl)!) {
                        HStack(spacing: 4) {
                            Image(systemName: "globe")
                            Text("Book Hotel")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                }
                
                Spacer()
                
                if showSelection && !isSelected {
                    Button("Select This Hotel") {
                        onSelection(accommodation.id)
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
        )
        .sheet(isPresented: $showingHotelDetails) {
            HotelDetailModal(
                hotel: accommodation.hotel,
                option: accommodation
            )
        }
    }
}

struct AdminActivitiesSectionView: View {
    let activities: [AdminActivity]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended Activities")
                .font(.headline)
            
            ForEach(activities) { activity in
                AdminActivityCardView(activity: activity)
            }
        }
    }
}

struct AdminActivityCardView: View {
    let activity: AdminActivity
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(activity.name)
                        .font(.subheadline)
                        .bold()
                    
                    Text(activity.category)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("$\(Int(activity.estimatedCost))")
                        .font(.subheadline)
                        .bold()
                    
                    Text(activity.estimatedDuration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(activity.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            Text(activity.location)
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
}

struct AdminRestaurantsSectionView: View {
    let restaurants: [AdminRestaurant]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recommended Restaurants")
                .font(.headline)
            
            ForEach(restaurants) { restaurant in
                AdminRestaurantCardView(restaurant: restaurant)
            }
        }
    }
}

struct AdminRestaurantCardView: View {
    let restaurant: AdminRestaurant
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(restaurant.name)
                        .font(.subheadline)
                        .bold()
                    
                    Text(restaurant.cuisine)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                Text(restaurant.priceRange)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.green)
            }
            
            Text(restaurant.description)
                .font(.body)
                .foregroundColor(.secondary)
            
            Text(restaurant.location)
                .font(.caption)
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Hotel Detail Modal
struct HotelDetailModal: View {
    let hotel: AdminHotel
    let option: AdminAccommodationOption
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Hotel Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "building.2")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(hotel.name)
                                    .font(.title2)
                                    .bold()
                                
                                Text(hotel.location)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                // Star rating display
                                HStack(spacing: 2) {
                                    ForEach(0..<Int(hotel.rating), id: \.self) { _ in
                                        Image(systemName: "star.fill")
                                            .font(.headline)
                                            .foregroundColor(.yellow)
                                    }
                                    let remainder = hotel.rating - Double(Int(hotel.rating))
                                    if remainder >= 0.5 {
                                        Image(systemName: "star.leadinghalf.filled")
                                            .font(.headline)
                                            .foregroundColor(.yellow)
                                    }
                                }
                                
                                Text(String(format: "%.1f stars", hotel.rating))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Hotel Description
                    if !hotel.detailedDescription.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("About This Hotel")
                                .font(.headline)
                            
                            Text(hotel.detailedDescription)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }
                    
                    // Pricing Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pricing")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            HStack {
                                Text("Price per Night")
                                Spacer()
                                Text("$\(Int(hotel.pricePerNight))")
                                    .bold()
                            }
                            
                            if let points = hotel.pointsPerNight, points > 0,
                               let program = hotel.loyaltyProgram {
                                HStack {
                                    Text("\(program) Points per Night")
                                    Spacer()
                                    Text("\(points) pts")
                                        .bold()
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            HStack {
                                Text("Priority Level")
                                Spacer()
                                Text("Priority \(option.priority)")
                                    .font(.subheadline)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(6)
                            }
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Loyalty Program Info
                    if let program = hotel.loyaltyProgram {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Loyalty Program")
                                .font(.headline)
                            
                            HStack {
                                Image(systemName: "creditcard")
                                    .foregroundColor(.blue)
                                Text(program)
                                    .font(.subheadline)
                                Spacer()
                                if let points = hotel.pointsPerNight, points > 0 {
                                    Text("\(points) pts/night")
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding()
                        .background(Color.purple.opacity(0.05))
                        .cornerRadius(12)
                    }
                    
                    // TripAdvisor Integration
                    if let tripadvisorUrl = hotel.tripadvisorUrl, !tripadvisorUrl.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Reviews & Info")
                                .font(.headline)
                            
                            Button(action: {
                                if let url = URL(string: tripadvisorUrl) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "star.bubble")
                                    Text("View on TripAdvisor")
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(Color.orange.opacity(0.05))
                        .cornerRadius(12)
                    }
                    
                    // Booking Section
                    if !hotel.bookingUrl.isEmpty {
                        VStack(spacing: 12) {
                            Button(action: {
                                if let url = URL(string: hotel.bookingUrl.hasPrefix("http") ? hotel.bookingUrl : "https://\(hotel.bookingUrl)") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "globe")
                                    Text("Book This Hotel")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            
                            Text("Recommended booking priority: \(option.priority)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Hotel Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}