//
//  DataModelsTests.swift
//  WanderMintTests
//
//  Created by Claude Code on 7/10/25.
//

import XCTest
import Firebase
import FirebaseFirestore
@testable import WanderMint

final class DataModelsTests: XCTestCase {
    
    // MARK: - Trip Model Tests
    
    func testTripModelCreation() {
        let trip = TravelTrip(
            id: "trip-123",
            userId: "user-123",
            destination: "Paris, France",
            destinations: ["Paris, France"],
            departureLocation: "New York, NY",
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
        
        XCTAssertEqual(trip.id, "trip-123")
        XCTAssertEqual(trip.destination, "Paris, France")
        XCTAssertEqual(trip.status, .pending)
        XCTAssertTrue(trip.endDateFormatted > trip.startDateFormatted)
    }
    
    func testTripStatusEnum() {
        let statuses: [TripStatusType] = [.pending, .inProgress, .completed, .cancelled, .failed]
        
        XCTAssertEqual(statuses.count, 5)
        XCTAssertEqual(TripStatusType.pending.rawValue, "pending")
        XCTAssertEqual(TripStatusType.inProgress.rawValue, "in_progress")
        XCTAssertEqual(TripStatusType.completed.rawValue, "completed")
        XCTAssertEqual(TripStatusType.cancelled.rawValue, "cancelled")
        XCTAssertEqual(TripStatusType.failed.rawValue, "failed")
    }
    
    func testTripDuration() {
        let startDate = Date()
        let endDate = Date().addingTimeInterval(86400 * 5) // 5 days
        
        let trip = TravelTrip(
            id: "trip-123",
            userId: "user-123",
            destination: "Test Destination",
            destinations: ["Test Destination"],
            departureLocation: "Test Departure",
            startDate: Timestamp(date: startDate),
            endDate: Timestamp(date: endDate),
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
        
        let duration = trip.endDateFormatted.timeIntervalSince(trip.startDateFormatted)
        let expectedDays = duration / 86400
        
        XCTAssertEqual(expectedDays, 5.0, accuracy: 0.1)
    }
    
    // MARK: - User Profile Model Tests
    
    func testUserProfileCreation() {
        let userProfile = UserProfile(
            userId: "user-123",
            name: "John Doe",
            email: "john.doe@example.com",
            createdAt: Timestamp(),
            lastLoginAt: Timestamp(),
            profilePictureUrl: "https://example.com/photo.jpg",
            onboardingCompleted: true,
            onboardingCompletedAt: Timestamp()
        )
        
        XCTAssertEqual(userProfile.userId, "user-123")
        XCTAssertEqual(userProfile.name, "John Doe")
        XCTAssertEqual(userProfile.email, "john.doe@example.com")
        XCTAssertTrue(userProfile.onboardingCompleted)
        XCTAssertNotNil(userProfile.onboardingCompletedAt)
    }
    
    func testUserProfileDefaults() {
        let userProfile = UserProfile(
            userId: "user-123",
            name: "Jane Doe",
            email: "jane.doe@example.com",
            createdAt: Timestamp(),
            lastLoginAt: Timestamp(),
            profilePictureUrl: nil,
            onboardingCompleted: false,
            onboardingCompletedAt: nil
        )
        
        XCTAssertFalse(userProfile.onboardingCompleted)
        XCTAssertNil(userProfile.onboardingCompletedAt)
        XCTAssertNil(userProfile.profilePictureUrl)
    }
    
    // MARK: - Points Model Tests
    
    func testUserPointsProfileCreation() {
        let pointsProfile = UserPointsProfile(
            userId: "user-123",
            creditCardPoints: [
                "Chase Sapphire": 50000,
                "Amex Platinum": 75000
            ],
            hotelPoints: [
                "Marriott": 100000,
                "Hilton": 50000
            ],
            airlinePoints: [
                "United": 60000,
                "Delta": 40000
            ],
            lastUpdated: Timestamp()
        )
        
        XCTAssertEqual(pointsProfile.userId, "user-123")
        XCTAssertEqual(pointsProfile.creditCardPoints.count, 2)
        XCTAssertEqual(pointsProfile.hotelPoints.count, 2)
        XCTAssertEqual(pointsProfile.airlinePoints.count, 2)
        XCTAssertEqual(pointsProfile.creditCardPoints["Chase Sapphire"], 50000)
    }
    
    func testFlexibleCostModel() {
        let cashCost = FlexibleCost(cashOnly: 500.0)
        let pointsCost = FlexibleCost(pointsOnly: 25000, program: "Chase", cashValue: 500.0)
        let hybridCost = FlexibleCost(hybrid: 200.0, points: 15000, program: "Amex")
        
        XCTAssertEqual(cashCost.paymentType, .cash)
        XCTAssertEqual(cashCost.cashAmount, 500.0)
        
        XCTAssertEqual(pointsCost.paymentType, .points)
        XCTAssertEqual(pointsCost.pointsAmount, 25000)
        XCTAssertEqual(pointsCost.pointsProgram, "Chase")
        
        XCTAssertEqual(hybridCost.paymentType, .hybrid)
        XCTAssertEqual(hybridCost.cashAmount, 200.0)
        XCTAssertEqual(hybridCost.pointsAmount, 15000)
    }
    
    func testPaymentTypeEnum() {
        let types: [PaymentType] = [.cash, .points, .hybrid]
        
        XCTAssertEqual(types.count, 3)
        XCTAssertEqual(PaymentType.cash.rawValue, "cash")
        XCTAssertEqual(PaymentType.points.rawValue, "points")
        XCTAssertEqual(PaymentType.hybrid.rawValue, "hybrid")
    }
    
    // MARK: - Accommodation Model Tests
    
    func testAccommodationDetailsCreation() {
        let accommodation = AccommodationDetails(
            id: "acc-123",
            name: "Test Hotel",
            type: .hotel,
            checkIn: "2024-01-01",
            checkOut: "2024-01-07",
            nights: 6,
            location: ActivityLocation(
                name: "Test Hotel",
                address: "123 Test Street",
                coordinates: nil,
                nearbyLandmarks: nil
            ),
            roomType: "Standard Room",
            amenities: ["WiFi", "Pool"],
            cost: FlexibleCost(cashOnly: 600.0),
            bookingUrl: "https://example.com",
            bookingInstructions: "Book directly",
            cancellationPolicy: "Free cancellation",
            contactInfo: ContactInfo(phone: "123-456-7890", email: "test@hotel.com", website: "https://hotel.com"),
            photos: nil,
            detailedDescription: nil,
            reviewRating: 4.5,
            numReviews: 100,
            priceLevel: "$$",
            hotelChain: "Test Chain",
            tripadvisorUrl: nil,
            tripadvisorId: nil,
            consultantNotes: nil,
            source: "test",
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
            isBooked: nil,
            bookingReference: nil,
            bookedDate: nil
        )
        
        XCTAssertEqual(accommodation.id, "acc-123")
        XCTAssertEqual(accommodation.name, "Test Hotel")
        XCTAssertEqual(accommodation.type, .hotel)
        XCTAssertEqual(accommodation.nights, 6)
        XCTAssertEqual(accommodation.reviewRating, 4.5)
        XCTAssertEqual(accommodation.numReviews, 100)
    }
    
    // MARK: - Points Type Tests
    
    func testPointsTypeEnum() {
        let types: [PointsType] = [.creditCard, .airline, .hotel]
        
        XCTAssertEqual(types.count, 3)
        XCTAssertEqual(PointsType.creditCard.rawValue, "credit_card")
        XCTAssertEqual(PointsType.airline.rawValue, "airline")
        XCTAssertEqual(PointsType.hotel.rawValue, "hotel")
    }
    
    // MARK: - Error Handling Tests
    
    func testTravelAppErrorTypes() {
        let networkError = TravelAppError.networkError("Network failed")
        let authError = TravelAppError.authenticationFailed
        let dataError = TravelAppError.dataError("Test error")
        let submissionError = TravelAppError.submissionFailed("Submission failed")
        let unknownError = TravelAppError.unknown
        
        XCTAssertNotNil(networkError)
        XCTAssertNotNil(authError)
        XCTAssertNotNil(dataError)
        XCTAssertNotNil(submissionError)
        XCTAssertNotNil(unknownError)
        
        if case .dataError(let message) = dataError {
            XCTAssertEqual(message, "Test error")
        } else {
            XCTFail("Expected dataError with message")
        }
        
        if case .networkError(let message) = networkError {
            XCTAssertEqual(message, "Network failed")
        } else {
            XCTFail("Expected networkError with message")
        }
    }
}