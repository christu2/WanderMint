import Foundation
import FirebaseFirestore

// MARK: - Enhanced Trip Submission Model
struct EnhancedTripSubmission: Codable {
    let destination: String
    let startDate: Date
    let endDate: Date
    let paymentMethod: String
    let flexibleDates: Bool
    let tripDuration: Int? // For flexible dates
    
    // Preference fields
    let budget: String?
    let travelStyle: String
    let groupSize: Int
    let specialRequests: String
    let interests: [String]
    
    enum CodingKeys: String, CodingKey {
        case destination, startDate, endDate, paymentMethod, flexibleDates, tripDuration
        case budget, travelStyle, groupSize, specialRequests, interests
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
    let paymentMethod: String
    let flexibleDates: Bool
    
    enum CodingKeys: String, CodingKey {
        case destination, startDate, endDate, paymentMethod, flexibleDates
    }
}

// MARK: - Trip Status Model
struct TravelTrip: Identifiable, Codable {
    let id: String
    let userId: String
    let destination: String
    let startDate: Timestamp
    let endDate: Timestamp
    let paymentMethod: String
    let flexibleDates: Bool
    let status: TripStatusType
    let createdAt: Timestamp
    let updatedAt: Timestamp?
    let recommendation: Recommendation?
    
    enum CodingKeys: String, CodingKey {
        case id, userId, destination, startDate, endDate, paymentMethod, flexibleDates, status, createdAt, updatedAt, recommendation
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

// MARK: - Recommendation Model
struct Recommendation: Identifiable, Codable {
    let id: String
    let destination: String
    let overview: String
    let activities: [Activity]
    let accommodations: [Accommodation]
    let transportation: TransportationInfo
    let estimatedCost: CostBreakdown
    let bestTimeToVisit: String
    let tips: [String]
    let createdAt: Timestamp
    
    enum CodingKeys: String, CodingKey {
        case id, destination, overview, activities, accommodations, transportation, estimatedCost, bestTimeToVisit, tips, createdAt
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
