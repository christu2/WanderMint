import Foundation
import FirebaseFirestore

// MARK: - Enhanced Trip Submission Model (Updated)
struct EnhancedTripSubmission: Codable {
    let destinations: [String] // Changed from single destination to array
    let departureLocation: String // New field for where user is departing from
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
        case destinations, departureLocation, startDate, endDate, flexibleDates, tripDuration
        case budget, travelStyle, groupSize, specialRequests, interests, flightClass
    }
}

// MARK: - User Profile
struct UserProfile: Codable {
    let userId: String
    var name: String
    var email: String
    var createdAt: Timestamp
    var lastLoginAt: Timestamp
    var profilePictureUrl: String?
    var onboardingCompleted: Bool
    var onboardingCompletedAt: Timestamp?
    
    enum CodingKeys: String, CodingKey {
        case userId, name, email, createdAt, lastLoginAt, profilePictureUrl, onboardingCompleted, onboardingCompletedAt
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
    let departureLocation: String? // New field for departure location
    let startDate: Timestamp
    let endDate: Timestamp
    let paymentMethod: String?   // Optional for backward compatibility
    let flexibleDates: Bool
    let status: TripStatusType
    let createdAt: Timestamp
    let updatedAt: Timestamp?
    let recommendation: Recommendation?              // Legacy format (deprecated)
    let destinationRecommendation: AdminDestinationBasedRecommendation?  // Admin-compatible format
    let flightClass: String?     // New field
    let budget: String?
    let travelStyle: String?
    let groupSize: Int?
    let interests: [String]?
    let specialRequests: String?
    
    enum CodingKeys: String, CodingKey {
        case id, userId, destination, destinations, departureLocation, startDate, endDate, paymentMethod, flexibleDates, status, createdAt, updatedAt, recommendation, destinationRecommendation, flightClass, budget, travelStyle, groupSize, interests, specialRequests
    }
    
    // Computed properties for easier date handling
    var startDateFormatted: Date {
        // Use timezone-safe date conversion to prevent day shifting
        let date = startDate.dateValue()
        return DateUtils.startOfDay(date)
    }
    
    var endDateFormatted: Date {
        // Use timezone-safe date conversion to prevent day shifting
        let date = endDate.dateValue()
        return DateUtils.startOfDay(date)
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
    
    // Helper properties for destination-centric UI
    var hasDestinationBasedRecommendation: Bool {
        return destinationRecommendation != nil
    }
    
    var hasLegacyRecommendation: Bool {
        return recommendation != nil
    }
    
    var cityCount: Int {
        if let destinations = destinations {
            return destinations.count
        } else if destination != nil {
            return 1
        }
        return 0
    }
    
    var isMultiCity: Bool {
        return cityCount > 1
    }
    
    // Get all destinations as array (handles both old and new formats)
    var allDestinations: [String] {
        if let destinations = destinations, !destinations.isEmpty {
            return destinations
        } else if let destination = destination {
            return [destination]
        }
        return []
    }
}

enum TripStatusType: String, Codable, CaseIterable {
    case pending = "pending"      // Waiting for your manual planning
    case inProgress = "in_progress"  // You're working on it
    case completed = "completed"   // You've finished the itinerary
    case cancelled = "cancelled"   // Trip was cancelled
    case failed = "failed"        // Trip processing failed
    
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
        case .failed:
            return "Failed"
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
        case .failed:
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

// MARK: - Enhanced Destination-Centric Models
struct DestinationBasedRecommendation: Identifiable, Codable {
    let id: String
    let tripOverview: String
    let destinations: [DestinationRecommendation]
    let logistics: LogisticsRecommendation
    let totalCost: CostBreakdown
    let createdAt: Timestamp?
    
    enum CodingKeys: String, CodingKey {
        case id, tripOverview, destinations, logistics, totalCost, createdAt
    }
}

struct DestinationRecommendation: Identifiable, Codable {
    let id: String
    let cityName: String
    let arrivalDate: String
    let departureDate: String
    let numberOfNights: Int
    let accommodationOptions: [AccommodationOption]
    let dailyItinerary: [DailyPlan]
    let localTransportation: [LocalTransportOption]
    let selectedAccommodationId: String?
    
    enum CodingKeys: String, CodingKey {
        case id, cityName, arrivalDate, departureDate, numberOfNights, accommodationOptions, dailyItinerary, localTransportation, selectedAccommodationId
    }
}

struct AccommodationOption: Identifiable, Codable {
    let id: String
    let hotel: AccommodationDetails
    let isSelected: Bool
    let isBooked: Bool
    let bookingReference: String?
    let bookedDate: String?
    let priority: Int // 1 = primary recommendation, 2 = alternative, etc.
    
    enum CodingKeys: String, CodingKey {
        case id, hotel, isSelected, isBooked, bookingReference, bookedDate, priority
    }
}

struct LocalTransportOption: Identifiable, Codable {
    let id: String
    let transportation: LocalTransportation
    let isRecommended: Bool
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id, transportation, isRecommended, notes
    }
}

struct LogisticsRecommendation: Codable {
    let transportSegments: [TransportSegment]
    let bookingDeadlines: [String]
    let generalInstructions: String
    
    enum CodingKeys: String, CodingKey {
        case transportSegments, bookingDeadlines, generalInstructions
    }
}

struct TransportSegment: Identifiable, Codable {
    let id: String
    let date: String
    let route: String // "Madrid → Rome"
    let transportOptions: [TransportOption]
    let selectedOptionId: String?
    let bookingGroups: [BookingGroup]?
    
    enum CodingKeys: String, CodingKey {
        case id, date, route, transportOptions, selectedOptionId, bookingGroups
    }
}

struct BookingGroup: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let transportOptionIds: [String] // References to TransportOption IDs
    let bookingUrl: String?
    let totalCost: TransportCost?
    let notes: String?
    let isRoundTrip: Bool
    let bookingDeadline: String?
    let isSelected: Bool
    let isBooked: Bool
    let bookingReference: String?
    let bookedDate: String?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, transportOptionIds, bookingUrl, totalCost, notes, isRoundTrip, bookingDeadline, isSelected, isBooked, bookingReference, bookedDate
    }
}

struct TransportOption: Identifiable, Codable {
    let id: String
    let transportType: String
    let details: TransportDetails
    let cost: TransportCost
    let duration: String
    let bookingUrl: String?
    let notes: String?
    let isSelected: Bool
    let isBooked: Bool
    let bookingReference: String?
    let bookedDate: String?
    let priority: Int
    
    enum CodingKeys: String, CodingKey {
        case id, transportType, details, cost, duration, bookingUrl, notes, isSelected, isBooked, bookingReference, bookedDate, priority
    }
    
    // Computed property for backward compatibility
    var type: TransportType {
        return TransportType(rawValue: transportType) ?? .flight
    }
}

struct TransportCost: Codable {
    let cash: Double
    let points: Int
    let currency: String
    
    enum CodingKeys: String, CodingKey {
        case cash, points, currency
    }
    
    var displayString: String {
        var components: [String] = []
        
        if cash > 0 {
            components.append("\(currency) \(String(format: "%.0f", cash))")
        }
        
        if points > 0 {
            components.append("\(points) points")
        }
        
        if components.isEmpty {
            return "Free"
        }
        
        return components.joined(separator: " + ")
    }
}

enum TransportType: String, Codable, CaseIterable {
    case flight = "flight"
    case train = "train"
    case bus = "bus"
    case ferry = "ferry"
    case car = "car"
    
    var displayName: String {
        switch self {
        case .flight: return "Flight"
        case .train: return "Train"
        case .bus: return "Bus"
        case .ferry: return "Ferry"
        case .car: return "Car Rental"
        }
    }
    
    var icon: String {
        switch self {
        case .flight: return "airplane"
        case .train: return "train.side.front.car"
        case .bus: return "bus"
        case .ferry: return "ferry"
        case .car: return "car"
        }
    }
}

enum TransportDetails: Codable {
    case flight(FlightDetails)
    case train(TrainDetails)
    case bus(BusDetails)
    case ferry(FerryDetails)
    case car(CarRentalDetails)
    
    enum CodingKeys: String, CodingKey {
        case type, details
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .flight(let details):
            try container.encode("flight", forKey: .type)
            try container.encode(details, forKey: .details)
        case .train(let details):
            try container.encode("train", forKey: .type)
            try container.encode(details, forKey: .details)
        case .bus(let details):
            try container.encode("bus", forKey: .type)
            try container.encode(details, forKey: .details)
        case .ferry(let details):
            try container.encode("ferry", forKey: .type)
            try container.encode(details, forKey: .details)
        case .car(let details):
            try container.encode("car", forKey: .type)
            try container.encode(details, forKey: .details)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        
        switch type {
        case "flight":
            let details = try container.decode(FlightDetails.self, forKey: .details)
            self = .flight(details)
        case "train":
            let details = try container.decode(TrainDetails.self, forKey: .details)
            self = .train(details)
        case "bus":
            let details = try container.decode(BusDetails.self, forKey: .details)
            self = .bus(details)
        case "ferry":
            let details = try container.decode(FerryDetails.self, forKey: .details)
            self = .ferry(details)
        case "car":
            let details = try container.decode(CarRentalDetails.self, forKey: .details)
            self = .car(details)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown transport type")
        }
    }
}

// New transport detail models
struct TrainDetails: Codable {
    let trainNumber: String
    let operatorName: String
    let departure: FlightSegment // Reuse FlightSegment for consistency
    let arrival: FlightSegment
    let duration: String
    let trainType: String // High-speed, Regional, etc.
    let cost: FlexibleCost
    let bookingClass: String
    let bookingUrl: String?
    let bookingInstructions: String?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case trainNumber, operatorName = "operator", departure, arrival, duration, trainType, cost, bookingClass, bookingUrl, bookingInstructions, notes
    }
}

struct BusDetails: Codable {
    let busNumber: String?
    let operatorName: String
    let departure: FlightSegment
    let arrival: FlightSegment
    let duration: String
    let busType: String // Coach, Express, etc.
    let cost: FlexibleCost
    let bookingUrl: String?
    let bookingInstructions: String?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case busNumber, operatorName = "operator", departure, arrival, duration, busType, cost, bookingUrl, bookingInstructions, notes
    }
}

struct FerryDetails: Codable {
    let ferryNumber: String?
    let operatorName: String
    let departure: FlightSegment
    let arrival: FlightSegment
    let duration: String
    let ferryType: String // Passenger, Car Ferry, etc.
    let cost: FlexibleCost
    let vehicleSpace: Bool? // If bringing a car
    let bookingUrl: String?
    let bookingInstructions: String?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case ferryNumber, operatorName = "operator", departure, arrival, duration, ferryType, cost, vehicleSpace, bookingUrl, bookingInstructions, notes
    }
}

struct CarRentalDetails: Codable {
    let company: String
    let pickupLocation: String
    let dropoffLocation: String
    let pickupDate: String
    let pickupTime: String
    let dropoffDate: String
    let dropoffTime: String
    let carType: String // Compact, SUV, etc.
    let cost: FlexibleCost
    let bookingUrl: String?
    let bookingInstructions: String?
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case company, pickupLocation, dropoffLocation, pickupDate, pickupTime, dropoffDate, dropoffTime, carType, cost, bookingUrl, bookingInstructions, notes
    }
}

// MARK: - Detailed Itinerary Models
struct DetailedItinerary: Identifiable, Codable {
    let id: String
    let flights: FlightItinerary
    let majorTransportation: [LocalTransportation]? // For trains, buses, etc. that span multiple days
    let dailyPlans: [DailyPlan]
    let accommodations: [AccommodationDetails]
    let totalCost: CostBreakdown
    let bookingInstructions: BookingInstructions
    let emergencyInfo: EmergencyInfo
    
    enum CodingKeys: String, CodingKey {
        case id, flights, majorTransportation, dailyPlans, accommodations, totalCost, bookingInstructions, emergencyInfo
    }
}

struct FlightItinerary: Codable {
    let outbound: FlightDetails
    let returnFlight: FlightDetails?
    let additionalFlights: [FlightDetails]? // Support for Flight 2, Flight 3, etc.
    let totalFlightCost: FlexibleCost
    let bookingDeadline: String
    let bookingInstructions: String
    
    enum CodingKeys: String, CodingKey {
        case outbound, returnFlight = "return", additionalFlights, totalFlightCost, bookingDeadline, bookingInstructions
    }
    
    // Computed property to get all flights in order
    var allFlights: [FlightDetails] {
        var flights = [outbound]
        if let returnFlight = returnFlight {
            flights.append(returnFlight)
        }
        if let additionalFlights = additionalFlights {
            flights.append(contentsOf: additionalFlights)
        }
        return flights
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
    let bookingInstructions: String?
    let notes: String?
    
    // Booking tracking
    let isBooked: Bool?
    let bookingReference: String?
    let bookedDate: String?
    let seatNumbers: String?
    
    enum CodingKeys: String, CodingKey {
        case flightNumber, airline, departure, arrival, duration, aircraft, cost, bookingClass, bookingUrl, seatRecommendations, bookingInstructions, notes
        case isBooked, bookingReference, bookedDate, seatNumbers
    }
    
    // Generate direct airline booking URL
    var directAirlineBookingUrl: String? {
        let airlineCode = airline.lowercased()
        let origin = departure.airportCode
        let destination = arrival.airportCode
        let departureDate = departure.date
        
        // Format date for URLs (YYYY-MM-DD to various airline formats)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        guard let date = dateFormatter.date(from: departureDate) else { return nil }
        
        switch airlineCode {
        case let airline where airline.contains("american"):
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yyyy"
            let formattedDate = formatter.string(from: date)
            return "https://www.aa.com/booking/choose-flights?from=\(origin)&to=\(destination)&departing=\(formattedDate)&passengers=1"
            
        case let airline where airline.contains("delta"):
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yyyy"
            let formattedDate = formatter.string(from: date)
            return "https://www.delta.com/flight-search/book-a-flight?from=\(origin)&to=\(destination)&departDate=\(formattedDate)&pax=1"
            
        case let airline where airline.contains("united"):
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let formattedDate = formatter.string(from: date)
            return "https://www.united.com/ual/en/us/flight-search/book-a-flight?f=\(origin)&t=\(destination)&d=\(formattedDate)&tt=1&at=1"
            
        case let airline where airline.contains("southwest"):
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yyyy"
            let formattedDate = formatter.string(from: date)
            return "https://www.southwest.com/flight/search-flight.html?originationAirportCode=\(origin)&destinationAirportCode=\(destination)&departureDate=\(formattedDate)&adultPassengersCount=1"
            
        case let airline where airline.contains("jetblue"):
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let formattedDate = formatter.string(from: date)
            return "https://www.jetblue.com/booking/flights?from=\(origin)&to=\(destination)&depart=\(formattedDate)&passenger=1"
            
        case let airline where airline.contains("alaska"):
            let formatter = DateFormatter()
            formatter.dateFormat = "MM/dd/yyyy"
            let formattedDate = formatter.string(from: date)
            return "https://www.alaskaair.com/booking/reservation/search?departureDate=\(formattedDate)&fromAirport=\(origin)&toAirport=\(destination)&numAdults=1"
            
        default:
            // Generic airline search fallback
            return "https://www.google.com/flights?f=\(origin)&t=\(destination)&d=\(departureDate)&c=economy&a=\(airline)"
        }
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

struct AccommodationPhoto: Identifiable, Codable {
    let id: String
    let url: String
    let caption: String?
    let width: Int?
    let height: Int?
    
    enum CodingKeys: String, CodingKey {
        case id, url, caption, width, height
    }
    
    // Convenience initializer for simple photos
    init(url: String, caption: String? = nil) {
        self.id = UUID().uuidString
        self.url = url
        self.caption = caption
        self.width = nil
        self.height = nil
    }
    
    // Full initializer
    init(id: String, url: String, caption: String?, width: Int?, height: Int?) {
        self.id = id
        self.url = url
        self.caption = caption
        self.width = width
        self.height = height
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
    
    // TripAdvisor Enhanced Fields
    let photos: [AccommodationPhoto]?
    let detailedDescription: String?
    let reviewRating: Double?
    let numReviews: Int?
    let priceLevel: String? // $, $$, $$$, $$$$
    let hotelChain: String?
    let tripadvisorUrl: String?
    let tripadvisorId: String?
    let consultantNotes: String?
    let source: String? // "tripadvisor", "airbnb", "manual", etc.
    
    // Airbnb Specific Fields
    let airbnbUrl: String?
    let airbnbListingId: String?
    let hostName: String?
    let hostIsSuperhost: Bool?
    let propertyType: String? // "Entire home", "Private room", "Shared room"
    let bedrooms: Int?
    let bathrooms: Double? // Can be 1.5, 2.5, etc.
    let maxGuests: Int?
    let instantBook: Bool?
    let neighborhood: String?
    let houseRules: [String]?
    let checkInInstructions: String?
    
    // Booking tracking
    let isBooked: Bool?
    let bookingReference: String?
    let bookedDate: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, type, checkIn, checkOut, nights, location, roomType, amenities, cost, bookingUrl, bookingInstructions, cancellationPolicy, contactInfo
        case photos, detailedDescription, reviewRating, numReviews, priceLevel, hotelChain, tripadvisorUrl, tripadvisorId, consultantNotes, source
        case airbnbUrl, airbnbListingId, hostName, hostIsSuperhost, propertyType, bedrooms, bathrooms, maxGuests, instantBook, neighborhood, houseRules, checkInInstructions
        case isBooked, bookingReference, bookedDate
    }
}

enum AccommodationType: String, Codable, CaseIterable {
    case hotel = "hotel"
    case resort = "resort"
    case boutique = "boutique"
    case airbnb = "airbnb"
    case hostel = "hostel"
    case guesthouse = "guesthouse"
    case apartment = "apartment"
    case villa = "villa"
    
    var displayName: String {
        switch self {
        case .hotel: return "Hotel"
        case .resort: return "Resort"
        case .boutique: return "Boutique Hotel"
        case .airbnb: return "Airbnb"
        case .hostel: return "Hostel"
        case .guesthouse: return "Guesthouse"
        case .apartment: return "Apartment"
        case .villa: return "Villa"
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
        case .apartment: return "building.fill"
        case .villa: return "house.lodge"
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

// MARK: - Hotel Search Models
struct HotelSearchResult: Identifiable, Codable {
    let id: String
    let name: String
    let address: String
    let rating: Double
    let numReviews: Int
    let priceLevel: String
    let hotelChain: String?
    let directBookingUrl: String?
    let bookingInstructions: String
    let phone: String?
    let website: String?
    let amenities: [String]
    let source: String // "tripadvisor", "foursquare", "mock"
    
    enum CodingKeys: String, CodingKey {
        case id, name, address, rating, numReviews, priceLevel, hotelChain, directBookingUrl, bookingInstructions, phone, website, amenities, source
    }
    
    // Convert to AccommodationDetails for trip integration
    func toAccommodationDetails(checkIn: String, checkOut: String, roomType: String = "Standard Room") -> AccommodationDetails {
        let nights = calculateNights(checkIn: checkIn, checkOut: checkOut)
        let estimatedCost = estimateCostFromPriceLevel(priceLevel: priceLevel, nights: nights)
        
        return AccommodationDetails(
            id: self.id,
            name: self.name,
            type: hotelChain != nil ? .hotel : .boutique,
            checkIn: checkIn,
            checkOut: checkOut,
            nights: nights,
            location: ActivityLocation(
                name: self.name,
                address: self.address,
                coordinates: nil,
                nearbyLandmarks: nil
            ),
            roomType: roomType,
            amenities: self.amenities,
            cost: FlexibleCost(cashOnly: estimatedCost),
            bookingUrl: self.directBookingUrl,
            bookingInstructions: self.bookingInstructions,
            cancellationPolicy: "Please check with hotel for cancellation policy",
            contactInfo: ContactInfo(
                phone: self.phone,
                email: nil,
                website: self.website
            ),
            photos: nil, // Will be populated by TripAdvisor details API
            detailedDescription: nil,
            reviewRating: rating > 0 ? rating : nil,
            numReviews: numReviews > 0 ? numReviews : nil,
            priceLevel: priceLevel.isEmpty ? nil : priceLevel,
            hotelChain: hotelChain,
            tripadvisorUrl: nil, // Will be populated by TripAdvisor details API
            tripadvisorId: source == "tripadvisor" ? id : nil,
            consultantNotes: nil,
            source: source,
            // Airbnb fields (set to nil for hotel search results)
            airbnbUrl: nil,
            airbnbListingId: nil,
            hostName: nil,
            hostIsSuperhost: nil,
            propertyType: nil,
            bedrooms: nil,
            bathrooms: nil,
            maxGuests: nil,
            instantBook: nil,
            neighborhood: nil,
            houseRules: nil,
            checkInInstructions: nil,
            // Booking tracking (set to nil for new records)
            isBooked: nil,
            bookingReference: nil,
            bookedDate: nil
        )
    }
    
    private func calculateNights(checkIn: String, checkOut: String) -> Int {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let checkInDate = formatter.date(from: checkIn),
              let checkOutDate = formatter.date(from: checkOut) else {
            return 1
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: checkInDate, to: checkOutDate)
        return max(components.day ?? 1, 1)
    }
    
    private func estimateCostFromPriceLevel(priceLevel: String, nights: Int) -> Double {
        let baseCost: Double
        
        switch priceLevel {
        case "$":
            baseCost = 80
        case "$$":
            baseCost = 150
        case "$$$":
            baseCost = 250
        case "$$$$":
            baseCost = 400
        default:
            baseCost = 180 // Default average
        }
        
        return baseCost * Double(nights)
    }
    
    var starRating: Int {
        return min(max(Int(round(rating)), 1), 5)
    }
    
    var displayRating: String {
        return String(format: "%.1f", rating)
    }
    
    var isChainHotel: Bool {
        return hotelChain != nil
    }
    
    var chainDisplayName: String {
        guard let chain = hotelChain else { return "Independent" }
        return chain.capitalized
    }
}

struct HotelSearchResponse: Codable {
    let success: Bool
    let hotels: [HotelSearchResult]
    let source: String
    let searchParams: HotelSearchParams
    
    enum CodingKeys: String, CodingKey {
        case success, hotels, source, searchParams
    }
}

struct HotelSearchParams: Codable {
    let location: String
    let checkIn: String?
    let checkOut: String?
    let guests: Int
    
    enum CodingKeys: String, CodingKey {
        case location, checkIn, checkOut, guests
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

// MARK: - Unified Transportation for Chronological Display
enum TransportationItem {
    case flight(FlightDetails, title: String)
    case localTransportation(LocalTransportation)
    
    var date: Date? {
        switch self {
        case .flight(let flight, _):
            // Try multiple date formats to handle different data sources
            let dateString = flight.departure.date
            
            // Format 1: yyyy-MM-dd
            let formatter1 = DateFormatter()
            formatter1.dateFormat = "yyyy-MM-dd"
            if let date = formatter1.date(from: dateString) {
                return date
            }
            
            // Format 2: MMM dd (e.g., "Nov 28")
            let formatter2 = DateFormatter()
            formatter2.dateFormat = "MMM dd"
            formatter2.locale = Locale(identifier: "en_US_POSIX")
            if let date = formatter2.date(from: dateString) {
                return date
            }
            
            // Format 3: MMM dd, yyyy (e.g., "Nov 28, 2023")
            let formatter3 = DateFormatter()
            formatter3.dateFormat = "MMM dd, yyyy"
            formatter3.locale = Locale(identifier: "en_US_POSIX")
            if let date = formatter3.date(from: dateString) {
                return date
            }
            
            // If all parsing fails, return nil
            return nil
        case .localTransportation(let transport):
            // Try to extract date from time string if it contains date info
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm"
            if let date = formatter.date(from: transport.time) {
                return date
            }
            // Fallback to just time parsing
            formatter.dateFormat = "HH:mm"
            if let timeOnly = formatter.date(from: transport.time) {
                // Use a reference date for time-only comparisons
                let calendar = Calendar.current
                let today = Date()
                let components = calendar.dateComponents([.year, .month, .day], from: today)
                let timeComponents = calendar.dateComponents([.hour, .minute], from: timeOnly)
                return calendar.date(from: DateComponents(
                    year: components.year,
                    month: components.month,
                    day: components.day,
                    hour: timeComponents.hour,
                    minute: timeComponents.minute
                ))
            }
            return nil
        }
    }
    
    var time: String {
        switch self {
        case .flight(let flight, _):
            return flight.departure.time
        case .localTransportation(let transport):
            return transport.time
        }
    }
}

// MARK: - Error Handling
enum TravelAppError: Error, LocalizedError {
    case authenticationFailed
    case networkError(String)
    case dataError(String)
    case submissionFailed(String)
    case networkUnavailable
    case requestTimeout
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
        case .networkUnavailable:
            return "Network connection unavailable. Please check your internet connection."
        case .requestTimeout:
            return "Request timed out. Please try again."
        case .unknown:
            return "An unknown error occurred. Please try again."
        }
    }
}
