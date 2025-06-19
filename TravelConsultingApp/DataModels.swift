import Foundation
import FirebaseFirestore

// MARK: - Enhanced Trip Submission Model (Updated)
struct EnhancedTripSubmission: Codable {
    let destinations: [String] // Changed from single destination to array
    let startDate: String      // Changed to String to avoid timezone issues
    let endDate: String        // Changed to String to avoid timezone issues
    let flexibleDates: Bool
    let tripDuration: Int?     // For flexible dates
    
    // Preference fields
    let budget: String?
    let travelStyle: String
    let groupSize: Int
    let specialRequests: String
    let interests: [String]
    let flightClass: String?   // New field for flight preference
    
    enum CodingKeys: String, CodingKey {
        case destinations, startDate, endDate, flexibleDates, tripDuration
        case budget, travelStyle, groupSize, specialRequests, interests, flightClass
    }
}

// MARK: - User Points Profile
struct UserPointsProfile: Codable {
    let userId: String
    var creditCardPoints: [String: Int] // "Amex": 50000, "Chase": 75000
    var hotelPoints: [String: Int] // "Hyatt": 25000, "Hilton": 40000
    var airlinePoints: [String: Int] // "United": 30000, "Delta": 15000
    var lastUpdated: Timestamp
    
    enum CodingKeys: String, CodingKey {
        case userId, creditCardPoints, hotelPoints, airlinePoints, lastUpdated
    }
}

enum PointsType: String, CaseIterable {
    case creditCard = "credit_card"
    case hotel = "hotel"
    case airline = "airline"
    
    var displayName: String {
        switch self {
        case .creditCard: return "Credit Card"
        case .hotel: return "Hotel"
        case .airline: return "Airline"
        }
    }
}

struct PointsProvider {
    static let creditCardProviders = ["American Express", "Chase", "Capital One", "Citi", "Bank of America", "Wells Fargo"]
    static let hotelProviders = ["Hyatt", "Marriott", "Hilton", "IHG", "Wyndham", "Choice Hotels"]
    static let airlineProviders = ["United", "Delta", "American", "Southwest", "JetBlue", "Alaska"]
}

// Keep the old one for backward compatibility
struct TripSubmission: Codable {
    let destination: String
    let startDate: Date
    let endDate: Date
    let paymentMethod: String? // Made optional since we now use flexible costs
    let flexibleDates: Bool
    
    enum CodingKeys: String, CodingKey {
        case destination, startDate, endDate, paymentMethod, flexibleDates
    }
}

// MARK: - Trip Status Model (Updated to handle multiple destinations)
struct TravelTrip: Identifiable, Codable {
    let id: String
    let userId: String
    let destination: String?     // Keep for backward compatibility
    let destinations: [String]?  // New field for multiple destinations
    let startDate: Timestamp
    let endDate: Timestamp
    let paymentMethod: String?   // Optional for backward compatibility
    let flexibleDates: Bool
    let status: TripStatusType
    let createdAt: Timestamp
    let updatedAt: Timestamp?
    let recommendation: Recommendation?
    let flightClass: String?     // New field
    let budget: String?
    let travelStyle: String?
    let groupSize: Int?
    let interests: [String]?
    let specialRequests: String?
    
    enum CodingKeys: String, CodingKey {
        case id, userId, destination, destinations, startDate, endDate, paymentMethod, flexibleDates, status, createdAt, updatedAt, recommendation, flightClass, budget, travelStyle, groupSize, interests, specialRequests
    }
    
    // Computed properties for easier date handling
    var startDateFormatted: Date {
        return startDate.dateValue()
    }
    
    var endDateFormatted: Date {
        return endDate.dateValue()
    }
    
    var createdAtFormatted: Date {
        return createdAt.dateValue()
    }
    
    // Helper to get destinations (handles both old and new format)
    var displayDestinations: String {
        if let destinations = destinations, !destinations.isEmpty {
            return destinations.joined(separator: ", ")
        }
        return destination ?? "Unknown"
    }
}

enum TripStatusType: String, Codable, CaseIterable {
    case pending = "pending"      // Waiting for your manual planning
    case inProgress = "in_progress"  // You're working on it
    case completed = "completed"   // You've finished the itinerary
    case cancelled = "cancelled"   // Trip was cancelled
    
    var displayText: String {
        switch self {
        case .pending:
            return "Pending Review"
        case .inProgress:
            return "Planning in Progress"
        case .completed:
            return "Itinerary Ready"
        case .cancelled:
            return "Cancelled"
        }
    }
    
    var color: String {
        switch self {
        case .pending:
            return "orange"
        case .inProgress:
            return "blue"
        case .completed:
            return "green"
        case .cancelled:
            return "red"
        }
    }
}

// MARK: - Recommendation Model (Enhanced with Detailed Itinerary)
struct Recommendation: Identifiable, Codable {
    let id: String
    let destination: String
    let overview: String
    let itinerary: DetailedItinerary?
    let activities: [Activity]
    let accommodations: [Accommodation]
    let transportation: TransportationInfo?
    let estimatedCost: CostBreakdown
    let bestTimeToVisit: String
    let tips: [String]
    let createdAt: Timestamp?
    
    enum CodingKeys: String, CodingKey {
        case id, destination, overview, itinerary, activities, accommodations, transportation, estimatedCost, bestTimeToVisit, tips, createdAt
    }
    
    // Initialize with default values for simple text recommendations
    init(id: String, destination: String, overview: String, createdAt: Timestamp? = nil) {
        self.id = id
        self.destination = destination
        self.overview = overview
        self.itinerary = nil
        self.activities = []
        self.accommodations = []
        self.transportation = nil
        self.estimatedCost = CostBreakdown(totalEstimate: 0, flights: 0, accommodation: 0, activities: 0, food: 0, localTransport: 0, miscellaneous: 0, currency: "USD")
        self.bestTimeToVisit = ""
        self.tips = []
        self.createdAt = createdAt
    }
    
    // Full initializer for complex recommendations
    init(id: String, destination: String, overview: String, itinerary: DetailedItinerary?, activities: [Activity], accommodations: [Accommodation], transportation: TransportationInfo?, estimatedCost: CostBreakdown, bestTimeToVisit: String, tips: [String], createdAt: Timestamp?) {
        self.id = id
        self.destination = destination
        self.overview = overview
        self.itinerary = itinerary
        self.activities = activities
        self.accommodations = accommodations
        self.transportation = transportation
        self.estimatedCost = estimatedCost
        self.bestTimeToVisit = bestTimeToVisit
        self.tips = tips
        self.createdAt = createdAt
    }
}

// MARK: - Detailed Itinerary Models
struct DetailedItinerary: Identifiable, Codable {
    let id: String
    let flights: FlightItinerary
    let dailyPlans: [DailyPlan]
    let accommodations: [AccommodationDetails]
    let totalCost: CostBreakdown
    let bookingInstructions: BookingInstructions
    let emergencyInfo: EmergencyInfo
    
    enum CodingKeys: String, CodingKey {
        case id, flights, dailyPlans, accommodations, totalCost, bookingInstructions, emergencyInfo
    }
}

struct FlightItinerary: Codable {
    let outbound: FlightDetails
    let returnFlight: FlightDetails?
    let totalFlightCost: FlexibleCost
    let bookingDeadline: String
    let bookingInstructions: String
    
    enum CodingKeys: String, CodingKey {
        case outbound, returnFlight = "return", totalFlightCost, bookingDeadline, bookingInstructions
    }
}

struct FlightDetails: Codable {
    let flightNumber: String
    let airline: String
    let departure: FlightSegment
    let arrival: FlightSegment
    let duration: String
    let aircraft: String
    let cost: FlexibleCost
    let bookingClass: String
    let bookingUrl: String?
    let seatRecommendations: String?
    
    enum CodingKeys: String, CodingKey {
        case flightNumber, airline, departure, arrival, duration, aircraft, cost, bookingClass, bookingUrl, seatRecommendations
    }
}

struct FlightSegment: Codable {
    let airport: String
    let airportCode: String
    let city: String
    let date: String
    let time: String
    let terminal: String?
    let gate: String?
    
    enum CodingKeys: String, CodingKey {
        case airport, airportCode, city, date, time, terminal, gate
    }
}

struct DailyPlan: Identifiable, Codable {
    let id: String
    let dayNumber: Int
    let date: String
    let title: String
    let activities: [DailyActivity]
    let meals: [MealRecommendation]
    let transportation: [LocalTransportation]
    let estimatedCost: FlexibleCost
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id, dayNumber, date, title, activities, meals, transportation, estimatedCost, notes
    }
}

struct DailyActivity: Identifiable, Codable {
    let id: String
    let time: String
    let duration: String
    let title: String
    let description: String
    let location: ActivityLocation
    let cost: FlexibleCost
    let bookingRequired: Bool
    let bookingUrl: String?
    let bookingInstructions: String?
    let tips: [String]
    let category: ActivityCategory
    
    enum CodingKeys: String, CodingKey {
        case id, time, duration, title, description, location, cost, bookingRequired, bookingUrl, bookingInstructions, tips, category
    }
}

struct ActivityLocation: Codable {
    let name: String
    let address: String
    let coordinates: LocationCoordinates?
    let nearbyLandmarks: String?
    
    enum CodingKeys: String, CodingKey {
        case name, address, coordinates, nearbyLandmarks
    }
}

struct LocationCoordinates: Codable {
    let latitude: Double
    let longitude: Double
    
    enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
}

// MARK: - Flexible Cost System
struct FlexibleCost: Codable {
    let paymentType: PaymentType
    let cashAmount: Double
    let pointsAmount: Int?
    let pointsProgram: String?
    let totalCashValue: Double // Always present for comparisons
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case paymentType, cashAmount, pointsAmount, pointsProgram, totalCashValue, notes
    }
    
    // Convenience initializers
    init(cashOnly amount: Double, notes: String? = nil) {
        self.paymentType = .cash
        self.cashAmount = amount
        self.pointsAmount = nil
        self.pointsProgram = nil
        self.totalCashValue = amount
        self.notes = notes
    }
    
    init(pointsOnly points: Int, program: String, cashValue: Double, notes: String? = nil) {
        self.paymentType = .points
        self.cashAmount = 0
        self.pointsAmount = points
        self.pointsProgram = program
        self.totalCashValue = cashValue
        self.notes = notes
    }
    
    init(hybrid cash: Double, points: Int, program: String, notes: String? = nil) {
        self.paymentType = .hybrid
        self.cashAmount = cash
        self.pointsAmount = points
        self.pointsProgram = program
        self.totalCashValue = cash // Could add estimated points value if needed
        self.notes = notes
    }
    
    var displayText: String {
        switch paymentType {
        case .cash:
            return "$\(Int(cashAmount))"
        case .points:
            guard let points = pointsAmount, let program = pointsProgram else {
                return "$\(Int(cashAmount))"
            }
            return "\(points.formatted()) \(program) points"
        case .hybrid:
            guard let points = pointsAmount, let program = pointsProgram else {
                return "$\(Int(cashAmount))"
            }
            return "$\(Int(cashAmount)) + \(points.formatted()) \(program)"
        }
    }
    
    var shortDisplayText: String {
        switch paymentType {
        case .cash:
            return "$\(Int(cashAmount))"
        case .points:
            guard let points = pointsAmount else { return "$\(Int(cashAmount))" }
            return "\(points.formatted())pts"
        case .hybrid:
            guard let points = pointsAmount else { return "$\(Int(cashAmount))" }
            return "$\(Int(cashAmount))+\(points.formatted())pts"
        }
    }
}

enum PaymentType: String, Codable, CaseIterable {
    case cash = "cash"
    case points = "points"
    case hybrid = "hybrid"
    
    var displayName: String {
        switch self {
        case .cash: return "Cash"
        case .points: return "Points"
        case .hybrid: return "Cash + Points"
        }
    }
    
    var icon: String {
        switch self {
        case .cash: return "dollarsign.circle"
        case .points: return "star.circle"
        case .hybrid: return "plus.circle"
        }
    }
}

enum ActivityCategory: String, Codable, CaseIterable {
    case sightseeing = "sightseeing"
    case cultural = "cultural"
    case adventure = "adventure"
    case relaxation = "relaxation"
    case food = "food"
    case shopping = "shopping"
    case entertainment = "entertainment"
    case transportation = "transportation"
    
    var displayName: String {
        switch self {
        case .sightseeing: return "Sightseeing"
        case .cultural: return "Cultural"
        case .adventure: return "Adventure"
        case .relaxation: return "Relaxation"
        case .food: return "Food & Dining"
        case .shopping: return "Shopping"
        case .entertainment: return "Entertainment"
        case .transportation: return "Transportation"
        }
    }
    
    var icon: String {
        switch self {
        case .sightseeing: return "camera"
        case .cultural: return "building.columns"
        case .adventure: return "mountain.2"
        case .relaxation: return "leaf"
        case .food: return "fork.knife"
        case .shopping: return "bag"
        case .entertainment: return "theatermasks"
        case .transportation: return "car"
        }
    }
}

struct MealRecommendation: Identifiable, Codable {
    let id: String
    let type: MealType
    let time: String
    let restaurantName: String
    let cuisine: String
    let description: String
    let location: ActivityLocation
    let estimatedCost: FlexibleCost
    let reservationRequired: Bool
    let reservationUrl: String?
    let reservationInstructions: String?
    let dietaryAccommodations: [String]
    
    enum CodingKeys: String, CodingKey {
        case id, type, time, restaurantName, cuisine, description, location, estimatedCost, reservationRequired, reservationUrl, reservationInstructions, dietaryAccommodations
    }
}

enum MealType: String, Codable, CaseIterable {
    case breakfast = "breakfast"
    case lunch = "lunch"
    case dinner = "dinner"
    case snack = "snack"
    
    var displayName: String {
        return self.rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .breakfast: return "sunrise"
        case .lunch: return "sun.max"
        case .dinner: return "moon"
        case .snack: return "fork.knife.circle"
        }
    }
}

struct LocalTransportation: Identifiable, Codable {
    let id: String
    let time: String
    let method: TransportMethod
    let from: String
    let to: String
    let duration: String
    let cost: FlexibleCost
    let instructions: String
    let bookingUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, time, method, from, to, duration, cost, instructions, bookingUrl
    }
}

enum TransportMethod: String, Codable, CaseIterable {
    case walking = "walking"
    case taxi = "taxi"
    case uber = "uber"
    case publicTransport = "public_transport"
    case metro = "metro"
    case bus = "bus"
    case train = "train"
    case rental = "rental_car"
    
    var displayName: String {
        switch self {
        case .walking: return "Walking"
        case .taxi: return "Taxi"
        case .uber: return "Uber/Lyft"
        case .publicTransport: return "Public Transport"
        case .metro: return "Metro/Subway"
        case .bus: return "Bus"
        case .train: return "Train"
        case .rental: return "Rental Car"
        }
    }
    
    var icon: String {
        switch self {
        case .walking: return "figure.walk"
        case .taxi: return "car"
        case .uber: return "car.fill"
        case .publicTransport: return "bus"
        case .metro: return "tram"
        case .bus: return "bus"
        case .train: return "train.side.front.car"
        case .rental: return "car.2"
        }
    }
}

struct AccommodationDetails: Identifiable, Codable {
    let id: String
    let name: String
    let type: AccommodationType
    let checkIn: String
    let checkOut: String
    let nights: Int
    let location: ActivityLocation
    let roomType: String
    let amenities: [String]
    let cost: FlexibleCost
    let bookingUrl: String?
    let bookingInstructions: String
    let cancellationPolicy: String
    let contactInfo: ContactInfo
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, checkIn, checkOut, nights, location, roomType, amenities, cost, bookingUrl, bookingInstructions, cancellationPolicy, contactInfo
    }
}

enum AccommodationType: String, Codable, CaseIterable {
    case hotel = "hotel"
    case resort = "resort"
    case boutique = "boutique"
    case airbnb = "airbnb"
    case hostel = "hostel"
    case guesthouse = "guesthouse"
    
    var displayName: String {
        switch self {
        case .hotel: return "Hotel"
        case .resort: return "Resort"
        case .boutique: return "Boutique Hotel"
        case .airbnb: return "Airbnb"
        case .hostel: return "Hostel"
        case .guesthouse: return "Guesthouse"
        }
    }
    
    var icon: String {
        switch self {
        case .hotel: return "building"
        case .resort: return "building.2"
        case .boutique: return "house"
        case .airbnb: return "house.fill"
        case .hostel: return "bed.double"
        case .guesthouse: return "house.circle"
        }
    }
}

struct ContactInfo: Codable {
    let phone: String?
    let email: String?
    let website: String?
    
    enum CodingKeys: String, CodingKey {
        case phone, email, website
    }
}

struct BookingInstructions: Codable {
    let overallInstructions: String
    let flightBookingTips: [String]
    let accommodationBookingTips: [String]
    let activityBookingTips: [String]
    let paymentMethods: [String]
    let cancellationPolicies: String
    let travelInsuranceRecommendation: String?
    
    enum CodingKeys: String, CodingKey {
        case overallInstructions, flightBookingTips, accommodationBookingTips, activityBookingTips, paymentMethods, cancellationPolicies, travelInsuranceRecommendation
    }
}

struct EmergencyInfo: Codable {
    let emergencyContacts: [EmergencyContact]
    let localEmergencyNumbers: [String: String]
    let nearestEmbassy: EmbassyInfo?
    let medicalFacilities: [MedicalFacility]
    let importantPhrases: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case emergencyContacts, localEmergencyNumbers, nearestEmbassy, medicalFacilities, importantPhrases
    }
}

struct EmergencyContact: Identifiable, Codable {
    let id: String
    let name: String
    let relationship: String
    let phone: String
    let email: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, relationship, phone, email
    }
}

struct EmbassyInfo: Codable {
    let name: String
    let address: String
    let phone: String
    let email: String?
    let website: String?
    
    enum CodingKeys: String, CodingKey {
        case name, address, phone, email, website
    }
}

struct MedicalFacility: Identifiable, Codable {
    let id: String
    let name: String
    let type: String
    let address: String
    let phone: String
    let englishSpeaking: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, address, phone, englishSpeaking
    }
}

struct Activity: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let category: String
    let estimatedDuration: String
    let estimatedCost: Double
    let priority: Int // 1-5, with 1 being highest priority
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, category, estimatedDuration, estimatedCost, priority
    }
}

struct Accommodation: Identifiable, Codable {
    let id: String
    let name: String
    let type: String // hotel, airbnb, hostel, etc.
    let description: String
    let priceRange: String
    let rating: Double
    let amenities: [String]
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, description, priceRange, rating, amenities
    }
}

struct TransportationInfo: Codable {
    let flightInfo: FlightInfo?
    let localTransport: [String]
    let estimatedFlightCost: Double
    let localTransportCost: Double
    
    enum CodingKeys: String, CodingKey {
        case flightInfo, localTransport, estimatedFlightCost, localTransportCost
    }
}

struct FlightInfo: Codable {
    let recommendedAirlines: [String]
    let estimatedFlightTime: String
    let bestBookingTime: String
    
    enum CodingKeys: String, CodingKey {
        case recommendedAirlines, estimatedFlightTime, bestBookingTime
    }
}

struct CostBreakdown: Codable {
    let totalEstimate: Double
    let flights: Double
    let accommodation: Double
    let activities: Double
    let food: Double
    let localTransport: Double
    let miscellaneous: Double
    let currency: String
    
    enum CodingKeys: String, CodingKey {
        case totalEstimate, flights, accommodation, activities, food, localTransport, miscellaneous, currency
    }
}

// MARK: - Error Handling
enum TravelAppError: Error, LocalizedError {
    case authenticationFailed
    case networkError(String)
    case dataError(String)
    case submissionFailed(String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "Authentication failed. Please try logging in again."
        case .networkError(let message):
            return "Network error: \(message)"
        case .dataError(let message):
            return "Data error: \(message)"
        case .submissionFailed(let message):
            return "Trip submission failed: \(message)"
        case .unknown:
            return "An unknown error occurred. Please try again."
        }
    }
}
