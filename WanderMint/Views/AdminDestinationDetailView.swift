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
                
                if let altDates = destination.alternativeDates, !altDates.isEmpty {
                    Text("Alternative dates: \(altDates)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                if let overview = destination.overview, !overview.isEmpty {
                    Text(overview)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
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
            // Photo Header (if available)
            if let photoUrl = accommodation.hotel.photoUrl ?? accommodation.hotel.photos?.first, !photoUrl.isEmpty, let url = URL(string: photoUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 140)
                            .clipped()
                            .cornerRadius(8)
                    case .failure:
                        EmptyView()
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.15))
                            .frame(height: 140)
                            .cornerRadius(8)
                            .overlay(ProgressView())
                    @unknown default:
                        EmptyView()
                    }
                }
            }

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
                    
                    LocationMapButton(location: accommodation.hotel.location, name: accommodation.hotel.name)
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
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
            }
            
            // Booking / Points Instructions
            if let instructions = accommodation.effectiveBookingInstructions {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption)
                        .foregroundColor(.purple)
                        .padding(.top, 2)
                    Text(instructions)
                        .font(.caption)
                        .foregroundColor(.purple)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.purple.opacity(0.08))
                .cornerRadius(6)
            }
            
            // Action buttons
            HStack(spacing: 8) {
                // View details button
                ActionLinkButton(title: "Details", icon: "info.circle.fill", color: .blue) {
                    showingHotelDetails = true
                }
                
                // TripAdvisor button
                if let tripadvisorUrl = accommodation.hotel.tripadvisorUrl, !tripadvisorUrl.isEmpty {
                    ActionLinkButton(title: "TripAdvisor", icon: "star.bubble.fill", color: .teal) {
                        MapLauncher.openTripAdvisor(for: accommodation.hotel.name, location: accommodation.hotel.location, directUrl: tripadvisorUrl)
                    }
                }
                
                // Book hotel button
                if !accommodation.hotel.bookingUrl.isEmpty {
                    ActionLinkButton(title: "Book", icon: "globe", color: .indigo) {
                        let urlStr = accommodation.hotel.bookingUrl.hasPrefix("http") ? accommodation.hotel.bookingUrl : "https://\(accommodation.hotel.bookingUrl)"
                        if let url = URL(string: urlStr) {
                            UIApplication.shared.open(url)
                        }
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
                    
                    HStack(spacing: 6) {
                        if !activity.category.isEmpty {
                            Text(activity.category)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        if let priority = activity.priority, priority == 1 {
                            Text("Must-Do")
                                .font(.caption2)
                                .bold()
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.15))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        }
                        
                        if activity.bookingRequired == true {
                            Text("Booking Required")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.15))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    if activity.estimatedCost > 0 {
                        Text("$\(Int(activity.estimatedCost))")
                            .font(.subheadline)
                            .bold()
                    } else {
                        Text("Free / Included")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !activity.estimatedDuration.isEmpty {
                        Text(activity.estimatedDuration)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if !activity.description.isEmpty {
                Text(activity.description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            if let bestTime = activity.bestTimeToVisit, !bestTime.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text("Best time: \(bestTime)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let bookingInstructions = activity.bookingInstructions, !bookingInstructions.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "ticket.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text(bookingInstructions)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let tips = activity.tips, !tips.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("Tip: \(tips)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !activity.location.isEmpty {
                LocationMapButton(location: activity.location, name: activity.name)
            }
            
            // Action links row
            HStack(spacing: 8) {
                if let websiteUrl = activity.website ?? activity.bookingUrl, !websiteUrl.isEmpty {
                    ActionLinkButton(title: "Website", icon: "safari.fill", color: .blue) {
                        let urlStr = websiteUrl.hasPrefix("http") ? websiteUrl : "https://\(websiteUrl)"
                        if let url = URL(string: urlStr) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                
                ActionLinkButton(title: "TripAdvisor", icon: "star.bubble.fill", color: .teal) {
                    MapLauncher.openTripAdvisor(for: activity.name, location: activity.location, directUrl: activity.tripadvisorUrl)
                }
            }
            .padding(.top, 2)
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
                    
                    HStack(spacing: 6) {
                        if !restaurant.cuisine.isEmpty {
                            Text(restaurant.cuisine)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        if let mealType = restaurant.mealType, !mealType.isEmpty {
                            Text(mealType)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.purple.opacity(0.12))
                                .foregroundColor(.purple)
                                .cornerRadius(4)
                        }
                        
                        if restaurant.reservationRequired == true {
                            Text("Reserve Ahead")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red.opacity(0.12))
                                .foregroundColor(.red)
                                .cornerRadius(4)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    if !restaurant.priceRange.isEmpty {
                        Text(restaurant.priceRange)
                            .font(.subheadline)
                            .bold()
                            .foregroundColor(.green)
                    }
                    if let cost = restaurant.estimatedCost, cost > 0 {
                        Text("~$\(Int(cost))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if !restaurant.description.isEmpty {
                Text(restaurant.description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            if let specialties = restaurant.specialties, !specialties.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Text("Must try: \(specialties)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let resInst = restaurant.reservationInstructions, !resInst.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.caption)
                        .foregroundColor(.red)
                    Text(resInst)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let tips = restaurant.tips, !tips.isEmpty {
                HStack(alignment: .top, spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(.yellow)
                    Text("Tip: \(tips)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if !restaurant.location.isEmpty {
                LocationMapButton(location: restaurant.location, name: restaurant.name)
            }
            
            // Action links row
            HStack(spacing: 8) {
                ActionLinkButton(title: "Yelp", icon: "bubble.left.and.bubble.right.fill", color: .red) {
                    MapLauncher.openYelp(for: restaurant.name, location: restaurant.location, directUrl: restaurant.yelpUrl)
                }
                
                if let websiteUrl = restaurant.website, !websiteUrl.isEmpty {
                    ActionLinkButton(title: "Website", icon: "safari.fill", color: .blue) {
                        let urlStr = websiteUrl.hasPrefix("http") ? websiteUrl : "https://\(websiteUrl)"
                        if let url = URL(string: urlStr) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
                
                if let resUrl = restaurant.reservationUrl, !resUrl.isEmpty {
                    ActionLinkButton(title: "Reserve", icon: "calendar", color: .green) {
                        let urlStr = resUrl.hasPrefix("http") ? resUrl : "https://\(resUrl)"
                        if let url = URL(string: urlStr) {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }
            .padding(.top, 2)
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
                    // Hotel Photo Header (if available)
                    if let photoUrl = hotel.photoUrl ?? hotel.photos?.first, !photoUrl.isEmpty, let url = URL(string: photoUrl) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxHeight: 220)
                                    .clipped()
                                    .cornerRadius(12)
                            case .failure:
                                EmptyView()
                            case .empty:
                                Rectangle()
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(height: 180)
                                    .cornerRadius(12)
                                    .overlay(ProgressView())
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    
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
                                
                                LocationMapButton(location: hotel.location, name: hotel.name)
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
                    if let program = hotel.loyaltyProgram, !program.isEmpty {
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
                    
                    // Booking & Points Strategy Instructions
                    if let instructions = option.effectiveBookingInstructions {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .foregroundColor(.purple)
                                Text("Booking & Points Instructions")
                                    .font(.headline)
                            }
                            Text(instructions)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.purple.opacity(0.08))
                        .cornerRadius(12)
                    }
                    
                    // Amenities & Cancellation Policy
                    if let amenities = hotel.amenities, !amenities.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Amenities")
                                .font(.headline)
                            Text(amenities.joined(separator: " • "))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }
                    
                    if let policy = hotel.cancellationPolicy, !policy.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Cancellation Policy")
                                .font(.subheadline)
                                .bold()
                            Text(policy)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }
                    
                    // TripAdvisor Reviews
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reviews & Ratings")
                            .font(.headline)
                        
                        ActionLinkButton(title: "View on TripAdvisor", icon: "star.bubble.fill", color: .teal) {
                            MapLauncher.openTripAdvisor(for: hotel.name, location: hotel.location, directUrl: hotel.tripadvisorUrl)
                        }
                    }
                    .padding()
                    .background(Color.orange.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Booking Section
                    if !hotel.bookingUrl.isEmpty {
                        VStack(spacing: 12) {
                            Button(action: {
                                let urlStr = hotel.bookingUrl.hasPrefix("http") ? hotel.bookingUrl : "https://\(hotel.bookingUrl)"
                                if let url = URL(string: urlStr) {
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