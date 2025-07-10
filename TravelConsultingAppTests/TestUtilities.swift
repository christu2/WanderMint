//
//  TestUtilities.swift
//  TravelConsultingAppTests
//
//  Created by Nick Christus on 3/9/25.
//

import Foundation
import FirebaseFirestore
@testable import TravelConsultingApp

// MARK: - Test Data Factory

struct TestDataFactory {
    
    // MARK: - Trip Test Data
    
    static func createTestTravelTrip(
        id: String = "test-trip-\(UUID().uuidString)",
        userId: String = "test-user-\(UUID().uuidString)",
        destination: String = "Tokyo, Japan",
        status: TripStatusType = .pending,
        withRecommendation: Bool = false
    ) -> TravelTrip {
        let trip = TravelTrip(
            id: id,
            userId: userId,
            destination: destination,
            destinations: [destination],
            startDate: Timestamp(date: Date().addingTimeInterval(30*24*60*60)),
            endDate: Timestamp(date: Date().addingTimeInterval(37*24*60*60)),
            paymentMethod: nil,
            flexibleDates: false,
            status: status,
            createdAt: Timestamp(date: Date()),
            updatedAt: nil,
            recommendation: withRecommendation ? createTestRecommendation(destination: destination) : nil,
            flightClass: "Economy",
            budget: "5000",
            travelStyle: "Comfortable",
            groupSize: 2,
            interests: ["Culture", "Food"],
            specialRequests: "Looking for authentic experiences"
        )
        return trip
    }
    
    static func createTestRecommendation(
        id: String = "test-rec-\(UUID().uuidString)",
        destination: String = "Tokyo, Japan"
    ) -> Recommendation {
        return Recommendation(
            id: id,
            destination: destination,
            overview: "Tokyo is a vibrant city that perfectly blends traditional Japanese culture with cutting-edge modernity.",
            itinerary: nil,
            activities: [createTestActivity()],
            accommodations: [createTestAccommodation()],
            transportation: createTestTransportationInfo(),
            estimatedCost: createTestCostBreakdown(),
            bestTimeToVisit: "Spring (March-May) or Fall (September-November)",
            tips: [
                "Learn basic Japanese phrases",
                "Get a JR Pass for convenient train travel",
                "Try authentic sushi at Tsukiji Outer Market"
            ],
            createdAt: Timestamp(date: Date())
        )
    }
    
    static func createTestActivity(
        id: String = "test-activity-\(UUID().uuidString)",
        name: String = "Visit Senso-ji Temple",
        category: String = "Cultural"
    ) -> Activity {
        return Activity(
            id: id,
            name: name,
            description: "Ancient Buddhist temple in the historic Asakusa district",
            category: category,
            estimatedDuration: "2 hours",
            estimatedCost: 0.0,
            priority: 1
        )
    }
    
    static func createTestAccommodation(
        id: String = "test-accommodation-\(UUID().uuidString)",
        name: String = "Park Hyatt Tokyo"
    ) -> Accommodation {
        return Accommodation(
            id: id,
            name: name,
            type: "hotel",
            description: "Luxury hotel in Shinjuku with stunning city views",
            priceRange: "$400-600/night",
            rating: 4.8,
            amenities: ["Spa", "Pool", "Restaurant", "Gym", "Business Center"]
        )
    }
    
    static func createTestTransportationInfo() -> TransportationInfo {
        return TransportationInfo(
            flightInfo: FlightInfo(
                recommendedAirlines: ["ANA", "JAL", "United"],
                estimatedFlightTime: "14 hours",
                bestBookingTime: "2-3 months in advance"
            ),
            localTransport: ["JR Pass", "Subway", "Taxi", "Bus"],
            estimatedFlightCost: 1200.0,
            localTransportCost: 300.0
        )
    }
    
    static func createTestCostBreakdown() -> CostBreakdown {
        return CostBreakdown(
            totalEstimate: 3500.0,
            flights: 1200.0,
            accommodation: 1500.0,
            activities: 400.0,
            food: 300.0,
            localTransport: 100.0,
            miscellaneous: 0.0,
            currency: "USD"
        )
    }
    
    // MARK: - Points Test Data
    
    static func createTestUserPointsProfile(
        userId: String = "test-user-\(UUID().uuidString)"
    ) -> UserPointsProfile {
        return UserPointsProfile(
            userId: userId,
            creditCardPoints: [
                "Chase": 75000,
                "American Express": 50000,
                "Capital One": 25000
            ],
            hotelPoints: [
                "Hyatt": 30000,
                "Marriott": 45000,
                "Hilton": 20000
            ],
            airlinePoints: [
                "United": 60000,
                "Delta": 40000,
                "American": 35000
            ],
            lastUpdated: Timestamp(date: Date())
        )
    }
    
    // MARK: - Submission Test Data
    
    static func createTestEnhancedTripSubmission(
        destinations: [String] = ["Tokyo, Japan"],
        flexibleDates: Bool = false
    ) -> EnhancedTripSubmission {
        let startDate = Date().addingTimeInterval(30*24*60*60)
        let endDate = Date().addingTimeInterval(37*24*60*60)
        
        return EnhancedTripSubmission(
            destinations: destinations,
            startDate: ISO8601DateFormatter().string(from: startDate),
            endDate: ISO8601DateFormatter().string(from: endDate),
            flexibleDates: flexibleDates,
            tripDuration: flexibleDates ? 7 : nil,
            budget: "5000",
            travelStyle: "Comfortable",
            groupSize: 2,
            specialRequests: "Looking for authentic experiences",
            interests: ["Culture", "Food"],
            flightClass: "Economy"
        )
    }
    
    // MARK: - Flexible Cost Test Data
    
    static func createTestFlexibleCosts() -> [FlexibleCost] {
        return [
            FlexibleCost(cashOnly: 1200.0, notes: "Flight cost"),
            FlexibleCost(pointsOnly: 80000, program: "Chase", cashValue: 1000.0, notes: "Using credit card points"),
            FlexibleCost(hybrid: 300.0, points: 40000, program: "Hyatt", notes: "Hotel stay with points + cash")
        ]
    }
    
    // MARK: - Error Test Data
    
    static func createTestErrors() -> [TravelAppError] {
        return [
            .authenticationFailed,
            .networkError("Connection timeout"),
            .dataError("Invalid JSON format"),
            .submissionFailed("Server error 500"),
            .unknown
        ]
    }
}

// MARK: - Test Validation Helpers

struct TestValidationHelpers {
    
    static func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    static func validatePassword(_ password: String) -> Bool {
        return password.count >= 6
    }
    
    static func validateGroupSize(_ size: Int) -> Bool {
        return size >= 1 && size <= 20
    }
    
    static func validateTripDuration(_ duration: Int) -> Bool {
        return duration >= 1 && duration <= 30
    }
    
    static func validateDateRange(start: Date, end: Date) -> Bool {
        return end > start
    }
    
    static func validateFlexibleDates(earliest: Date, latest: Date) -> Bool {
        return latest >= earliest
    }
    
    static func validateDestination(_ destination: String) -> Bool {
        return !destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    static func validatePointsAmount(_ amount: Int) -> Bool {
        return amount >= 0 && amount <= 10000000
    }
    
    static func validateCurrency(_ currency: String) -> Bool {
        let validCurrencies = ["USD", "EUR", "GBP", "JPY", "CAD", "AUD"]
        return validCurrencies.contains(currency)
    }
}

// MARK: - Test Data Generators

struct TestDataGenerators {
    
    static func generateRandomDestinations(count: Int = 3) -> [String] {
        let destinations = [
            "Tokyo, Japan",
            "Paris, France",
            "London, England",
            "New York, USA",
            "Sydney, Australia",
            "Rome, Italy",
            "Barcelona, Spain",
            "Bangkok, Thailand",
            "Dubai, UAE",
            "Singapore"
        ]
        return Array(destinations.shuffled().prefix(count))
    }
    
    static func generateRandomInterests(count: Int = 3) -> [String] {
        let interests = [
            "Culture",
            "Food",
            "Nature",
            "History",
            "Nightlife",
            "Shopping",
            "Adventure Sports",
            "Art",
            "Music",
            "Architecture"
        ]
        return Array(interests.shuffled().prefix(count))
    }
    
    static func generateRandomTravelStyle() -> String {
        let styles = ["Budget", "Comfortable", "Luxury", "Adventure", "Relaxation"]
        return styles.randomElement()!
    }
    
    static func generateRandomFlightClass() -> String {
        let classes = ["Economy", "Premium Economy", "Business", "First"]
        return classes.randomElement()!
    }
    
    static func generateRandomPointsProvider(for type: PointsType) -> String {
        switch type {
        case .creditCard:
            return PointsProvider.creditCardProviders.randomElement()!
        case .hotel:
            return PointsProvider.hotelProviders.randomElement()!
        case .airline:
            return PointsProvider.airlineProviders.randomElement()!
        }
    }
    
    static func generateRandomPointsAmount() -> Int {
        return Int.random(in: 1000...500000)
    }
    
    static func generateRandomBudget() -> String {
        let budgets = ["1000", "2500", "5000", "10000", "15000", "25000"]
        return budgets.randomElement()!
    }
}

// MARK: - Test Assertion Helpers

struct TestAssertionHelpers {
    
    static func assertValidTrip(_ trip: TravelTrip) {
        assert(!trip.id.isEmpty, "Trip ID should not be empty")
        assert(!trip.userId.isEmpty, "User ID should not be empty")
        assert(!trip.displayDestinations.isEmpty, "Destinations should not be empty")
        assert(trip.endDateFormatted > trip.startDateFormatted, "End date should be after start date")
        assert(trip.createdAtFormatted <= Date(), "Created date should not be in the future")
    }
    
    static func assertValidRecommendation(_ recommendation: Recommendation) {
        assert(!recommendation.id.isEmpty, "Recommendation ID should not be empty")
        assert(!recommendation.destination.isEmpty, "Destination should not be empty")
        assert(!recommendation.overview.isEmpty, "Overview should not be empty")
        assert(recommendation.estimatedCost.totalEstimate >= 0, "Total estimate should not be negative")
    }
    
    static func assertValidPointsProfile(_ profile: UserPointsProfile) {
        assert(!profile.userId.isEmpty, "User ID should not be empty")
        assert(profile.lastUpdated.dateValue() <= Date(), "Last updated should not be in the future")
        
        // Validate all points are non-negative
        for (_, points) in profile.creditCardPoints {
            assert(points >= 0, "Credit card points should not be negative")
        }
        for (_, points) in profile.hotelPoints {
            assert(points >= 0, "Hotel points should not be negative")
        }
        for (_, points) in profile.airlinePoints {
            assert(points >= 0, "Airline points should not be negative")
        }
    }
    
    static func assertValidFlexibleCost(_ cost: FlexibleCost) {
        assert(cost.cashAmount >= 0, "Cash amount should not be negative")
        assert(cost.totalCashValue >= 0, "Total cash value should not be negative")
        
        if let points = cost.pointsAmount {
            assert(points >= 0, "Points amount should not be negative")
        }
        
        if cost.paymentType == .points || cost.paymentType == .hybrid {
            assert(cost.pointsAmount != nil, "Points amount should be set for points/hybrid payment")
            assert(cost.pointsProgram != nil, "Points program should be set for points/hybrid payment")
        }
    }
}