import Foundation
import FirebaseFirestore

// MARK: - Trip Submission Model
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
    case submitted = "submitted"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    
    var displayText: String {
        switch self {
        case .submitted:
            return "Submitted"
        case .processing:
            return "Processing"
        case .completed:
            return "Completed"
        case .failed:
            return "Failed"
        }
    }
    
    var color: String {
        switch self {
        case .submitted:
            return "blue"
        case .processing:
            return "orange"
        case .completed:
            return "green"
        case .failed:
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
