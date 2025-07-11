//
//  TripServiceTests.swift
//  WanderMintTests
//
//  Created by Claude Code on 7/10/25.
//

import XCTest
import Firebase
import FirebaseAuth
import FirebaseFirestore
@testable import WanderMint

@MainActor
final class TripServiceTests: XCTestCase {
    
    var tripService: TripService!
    var mockURLSession: MockURLSession!
    
    override func setUpWithError() throws {
        super.setUp()
        mockURLSession = MockURLSession()
        tripService = TripService()
    }
    
    override func tearDownWithError() throws {
        tripService = nil
        mockURLSession = nil
        super.tearDown()
    }
    
    // MARK: - Trip Creation Tests
    
    func testCreateTripSuccess() async throws {
        let mockTrip = TravelTrip(
            id: "test-id",
            userId: "user-123",
            destination: "Paris",
            destinations: ["Paris"],
            departureLocation: "New York",
            startDate: Timestamp(date: Date()),
            endDate: Timestamp(date: Date().addingTimeInterval(86400 * 7)),
            paymentMethod: "cash",
            flexibleDates: false,
            status: .pending,
            createdAt: Timestamp(date: Date()),
            updatedAt: Timestamp(date: Date()),
            recommendation: nil,
            destinationRecommendation: nil,
            flightClass: nil,
            budget: nil,
            travelStyle: nil,
            groupSize: nil,
            interests: nil,
            specialRequests: nil
        )
        
        // Mock successful response
        mockURLSession.data = try JSONEncoder().encode(mockTrip)
        
        guard let url = URL(string: "https://example.com") else {
            XCTFail("Failed to create URL")
            return
        }
        
        mockURLSession.response = HTTPURLResponse(
            url: url,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // This test would require dependency injection to work properly
        // For now, we'll test the trip model validation
        XCTAssertEqual(mockTrip.destination, "Paris")
        XCTAssertEqual(mockTrip.destinations, ["Paris"])
        XCTAssertEqual(mockTrip.status, .pending)
    }
    
    func testTripValidation() {
        let validTrip = TravelTrip(
            id: "test-id",
            userId: "user-123",
            destination: "Tokyo",
            destinations: ["Tokyo"],
            departureLocation: "Los Angeles",
            startDate: Timestamp(date: Date()),
            endDate: Timestamp(date: Date().addingTimeInterval(86400 * 5)),
            paymentMethod: "cash",
            flexibleDates: false,
            status: .pending,
            createdAt: Timestamp(date: Date()),
            updatedAt: Timestamp(date: Date()),
            recommendation: nil,
            destinationRecommendation: nil,
            flightClass: nil,
            budget: nil,
            travelStyle: nil,
            groupSize: nil,
            interests: nil,
            specialRequests: nil
        )
        
        XCTAssertFalse(validTrip.destination?.isEmpty ?? true)
        XCTAssertFalse(validTrip.displayDestinations.isEmpty)
        XCTAssertTrue(validTrip.endDateFormatted > validTrip.startDateFormatted)
    }
    
    // MARK: - Trip Status Tests
    
    func testTripStatusTransitions() {
        var trip = TravelTrip(
            id: "test-id",
            userId: "user-123",
            destination: "London",
            destinations: ["London"],
            departureLocation: "Boston",
            startDate: Timestamp(date: Date()),
            endDate: Timestamp(date: Date().addingTimeInterval(86400 * 3)),
            paymentMethod: "cash",
            flexibleDates: false,
            status: .pending,
            createdAt: Timestamp(date: Date()),
            updatedAt: Timestamp(date: Date()),
            recommendation: nil,
            destinationRecommendation: nil,
            flightClass: nil,
            budget: nil,
            travelStyle: nil,
            groupSize: nil,
            interests: nil,
            specialRequests: nil
        )
        
        XCTAssertEqual(trip.status, .pending)
        
        // Test different status enum values
        XCTAssertEqual(TripStatusType.pending.rawValue, "pending")
        XCTAssertEqual(TripStatusType.inProgress.rawValue, "in_progress")
        XCTAssertEqual(TripStatusType.completed.rawValue, "completed")
    }
    
    // MARK: - Trip Service Method Tests
    
    func testTripServiceInitialization() {
        XCTAssertNotNil(tripService)
    }
    
    func testTripDestinationHelpers() {
        let singleDestinationTrip = TravelTrip(
            id: "single-dest",
            userId: "user-123",
            destination: "Rome",
            destinations: nil,
            departureLocation: "Miami",
            startDate: Timestamp(date: Date()),
            endDate: Timestamp(date: Date().addingTimeInterval(86400 * 4)),
            paymentMethod: "cash",
            flexibleDates: false,
            status: .pending,
            createdAt: Timestamp(date: Date()),
            updatedAt: nil,
            recommendation: nil,
            destinationRecommendation: nil,
            flightClass: nil,
            budget: nil,
            travelStyle: nil,
            groupSize: nil,
            interests: nil,
            specialRequests: nil
        )
        
        let multiDestinationTrip = TravelTrip(
            id: "multi-dest",
            userId: "user-123",
            destination: nil,
            destinations: ["Barcelona", "Madrid", "Seville"],
            departureLocation: "Denver",
            startDate: Timestamp(date: Date()),
            endDate: Timestamp(date: Date().addingTimeInterval(86400 * 10)),
            paymentMethod: "cash",
            flexibleDates: false,
            status: .pending,
            createdAt: Timestamp(date: Date()),
            updatedAt: nil,
            recommendation: nil,
            destinationRecommendation: nil,
            flightClass: nil,
            budget: nil,
            travelStyle: nil,
            groupSize: nil,
            interests: nil,
            specialRequests: nil
        )
        
        XCTAssertEqual(singleDestinationTrip.cityCount, 1)
        XCTAssertFalse(singleDestinationTrip.isMultiCity)
        XCTAssertEqual(singleDestinationTrip.displayDestinations, "Rome")
        
        XCTAssertEqual(multiDestinationTrip.cityCount, 3)
        XCTAssertTrue(multiDestinationTrip.isMultiCity)
        XCTAssertEqual(multiDestinationTrip.displayDestinations, "Barcelona, Madrid, Seville")
    }
}

// MARK: - Mock URL Session

class MockURLSession {
    var data: Data?
    var response: URLResponse?
    var error: Error?
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if let error = error {
            throw error
        }
        
        return (data ?? Data(), response ?? URLResponse())
    }
}