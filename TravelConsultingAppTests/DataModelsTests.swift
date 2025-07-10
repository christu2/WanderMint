//
//  DataModelsTests.swift
//  TravelConsultingAppTests
//
//  Created by Nick Christus on 3/9/25.
//

import Testing
import Foundation
import FirebaseFirestore
@testable import TravelConsultingApp

struct DataModelsTests {
    
    // MARK: - FlexibleCost Tests
    
    @Test func testFlexibleCostCashOnlyInitializer() async throws {
        let cost = FlexibleCost(cashOnly: 500.0, notes: "Test note")
        
        #expect(cost.paymentType == .cash)
        #expect(cost.cashAmount == 500.0)
        #expect(cost.pointsAmount == nil)
        #expect(cost.pointsProgram == nil)
        #expect(cost.totalCashValue == 500.0)
        #expect(cost.notes == "Test note")
    }
    
    @Test func testFlexibleCostPointsOnlyInitializer() async throws {
        let cost = FlexibleCost(pointsOnly: 25000, program: "Chase", cashValue: 300.0)
        
        #expect(cost.paymentType == .points)
        #expect(cost.cashAmount == 0)
        #expect(cost.pointsAmount == 25000)
        #expect(cost.pointsProgram == "Chase")
        #expect(cost.totalCashValue == 300.0)
    }
    
    @Test func testFlexibleCostHybridInitializer() async throws {
        let cost = FlexibleCost(hybrid: 200.0, points: 15000, program: "Amex")
        
        #expect(cost.paymentType == .hybrid)
        #expect(cost.cashAmount == 200.0)
        #expect(cost.pointsAmount == 15000)
        #expect(cost.pointsProgram == "Amex")
        #expect(cost.totalCashValue == 200.0)
    }
    
    @Test func testFlexibleCostDisplayText() async throws {
        let cashCost = FlexibleCost(cashOnly: 500.0)
        #expect(cashCost.displayText == "$500")
        
        let pointsCost = FlexibleCost(pointsOnly: 25000, program: "Chase", cashValue: 300.0)
        #expect(pointsCost.displayText == "25,000 Chase points")
        
        let hybridCost = FlexibleCost(hybrid: 200.0, points: 15000, program: "Amex")
        #expect(hybridCost.displayText == "$200 + 15,000 Amex")
    }
    
    @Test func testFlexibleCostShortDisplayText() async throws {
        let cashCost = FlexibleCost(cashOnly: 500.0)
        #expect(cashCost.shortDisplayText == "$500")
        
        let pointsCost = FlexibleCost(pointsOnly: 25000, program: "Chase", cashValue: 300.0)
        #expect(pointsCost.shortDisplayText == "25,000pts")
        
        let hybridCost = FlexibleCost(hybrid: 200.0, points: 15000, program: "Amex")
        #expect(hybridCost.shortDisplayText == "$200+15,000pts")
    }
    
    // MARK: - PaymentType Tests
    
    @Test func testPaymentTypeDisplayNames() async throws {
        #expect(PaymentType.cash.displayName == "Cash")
        #expect(PaymentType.points.displayName == "Points")
        #expect(PaymentType.hybrid.displayName == "Cash + Points")
    }
    
    @Test func testPaymentTypeIcons() async throws {
        #expect(PaymentType.cash.icon == "dollarsign.circle")
        #expect(PaymentType.points.icon == "star.circle")
        #expect(PaymentType.hybrid.icon == "plus.circle")
    }
    
    // MARK: - TripStatusType Tests
    
    @Test func testTripStatusDisplayText() async throws {
        #expect(TripStatusType.pending.displayText == "Pending Review")
        #expect(TripStatusType.inProgress.displayText == "Planning in Progress")
        #expect(TripStatusType.completed.displayText == "Itinerary Ready")
        #expect(TripStatusType.cancelled.displayText == "Cancelled")
    }
    
    @Test func testTripStatusColors() async throws {
        #expect(TripStatusType.pending.color == "orange")
        #expect(TripStatusType.inProgress.color == "blue")
        #expect(TripStatusType.completed.color == "green")
        #expect(TripStatusType.cancelled.color == "red")
    }
    
    // MARK: - ActivityCategory Tests
    
    @Test func testActivityCategoryDisplayNames() async throws {
        #expect(ActivityCategory.sightseeing.displayName == "Sightseeing")
        #expect(ActivityCategory.cultural.displayName == "Cultural")
        #expect(ActivityCategory.adventure.displayName == "Adventure")
        #expect(ActivityCategory.food.displayName == "Food & Dining")
        #expect(ActivityCategory.entertainment.displayName == "Entertainment")
    }
    
    @Test func testActivityCategoryIcons() async throws {
        #expect(ActivityCategory.sightseeing.icon == "camera")
        #expect(ActivityCategory.cultural.icon == "building.columns")
        #expect(ActivityCategory.adventure.icon == "mountain.2")
        #expect(ActivityCategory.food.icon == "fork.knife")
        #expect(ActivityCategory.transportation.icon == "car")
    }
    
    // MARK: - AccommodationType Tests
    
    @Test func testAccommodationTypeDisplayNames() async throws {
        #expect(AccommodationType.hotel.displayName == "Hotel")
        #expect(AccommodationType.resort.displayName == "Resort")
        #expect(AccommodationType.boutique.displayName == "Boutique Hotel")
        #expect(AccommodationType.airbnb.displayName == "Airbnb")
        #expect(AccommodationType.hostel.displayName == "Hostel")
        #expect(AccommodationType.guesthouse.displayName == "Guesthouse")
    }
    
    // MARK: - TransportMethod Tests
    
    @Test func testTransportMethodDisplayNames() async throws {
        #expect(TransportMethod.walking.displayName == "Walking")
        #expect(TransportMethod.taxi.displayName == "Taxi")
        #expect(TransportMethod.uber.displayName == "Uber/Lyft")
        #expect(TransportMethod.publicTransport.displayName == "Public Transport")
        #expect(TransportMethod.rental.displayName == "Rental Car")
    }
    
    // MARK: - TravelTrip Tests
    
    @Test func testTravelTripDisplayDestinations() async throws {
        // Test with new destinations array
        let tripWithMultipleDestinations = TravelTrip(
            id: "test1",
            userId: "user1",
            destination: nil,
            destinations: ["Tokyo, Japan", "Kyoto, Japan"],
            startDate: Timestamp(date: Date()),
            endDate: Timestamp(date: Date().addingTimeInterval(7*24*60*60)),
            paymentMethod: nil,
            flexibleDates: false,
            status: .pending,
            createdAt: Timestamp(date: Date()),
            updatedAt: nil,
            recommendation: nil,
            flightClass: nil,
            budget: nil,
            travelStyle: nil,
            groupSize: nil,
            interests: nil,
            specialRequests: nil
        )
        
        #expect(tripWithMultipleDestinations.displayDestinations == "Tokyo, Japan, Kyoto, Japan")
        
        // Test with legacy single destination
        let tripWithSingleDestination = TravelTrip(
            id: "test2",
            userId: "user1",
            destination: "Paris, France",
            destinations: nil,
            startDate: Timestamp(date: Date()),
            endDate: Timestamp(date: Date().addingTimeInterval(7*24*60*60)),
            paymentMethod: nil,
            flexibleDates: false,
            status: .pending,
            createdAt: Timestamp(date: Date()),
            updatedAt: nil,
            recommendation: nil,
            flightClass: nil,
            budget: nil,
            travelStyle: nil,
            groupSize: nil,
            interests: nil,
            specialRequests: nil
        )
        
        #expect(tripWithSingleDestination.displayDestinations == "Paris, France")
        
        // Test with empty destinations
        let tripWithEmptyDestinations = TravelTrip(
            id: "test3",
            userId: "user1",
            destination: nil,
            destinations: [],
            startDate: Timestamp(date: Date()),
            endDate: Timestamp(date: Date().addingTimeInterval(7*24*60*60)),
            paymentMethod: nil,
            flexibleDates: false,
            status: .pending,
            createdAt: Timestamp(date: Date()),
            updatedAt: nil,
            recommendation: nil,
            flightClass: nil,
            budget: nil,
            travelStyle: nil,
            groupSize: nil,
            interests: nil,
            specialRequests: nil
        )
        
        #expect(tripWithEmptyDestinations.displayDestinations == "Unknown")
    }
    
    @Test func testTravelTripDateFormatters() async throws {
        let startDate = Date()
        let endDate = Date().addingTimeInterval(7*24*60*60)
        
        let trip = TravelTrip(
            id: "test",
            userId: "user1",
            destination: "Test Destination",
            destinations: nil,
            startDate: Timestamp(date: startDate),
            endDate: Timestamp(date: endDate),
            paymentMethod: nil,
            flexibleDates: false,
            status: .pending,
            createdAt: Timestamp(date: startDate),
            updatedAt: nil,
            recommendation: nil,
            flightClass: nil,
            budget: nil,
            travelStyle: nil,
            groupSize: nil,
            interests: nil,
            specialRequests: nil
        )
        
        // Test that formatted dates return Date objects
        #expect(abs(trip.startDateFormatted.timeIntervalSince1970 - startDate.timeIntervalSince1970) < 1.0)
        #expect(abs(trip.endDateFormatted.timeIntervalSince1970 - endDate.timeIntervalSince1970) < 1.0)
        #expect(abs(trip.createdAtFormatted.timeIntervalSince1970 - startDate.timeIntervalSince1970) < 1.0)
    }
    
    // MARK: - Recommendation Tests
    
    @Test func testRecommendationSimpleInitializer() async throws {
        let recommendation = Recommendation(
            id: "rec1",
            destination: "Tokyo",
            overview: "Great city for culture and food",
            createdAt: Timestamp(date: Date())
        )
        
        #expect(recommendation.id == "rec1")
        #expect(recommendation.destination == "Tokyo")
        #expect(recommendation.overview == "Great city for culture and food")
        #expect(recommendation.activities.isEmpty)
        #expect(recommendation.accommodations.isEmpty)
        #expect(recommendation.transportation == nil)
        #expect(recommendation.estimatedCost.totalEstimate == 0)
        #expect(recommendation.bestTimeToVisit == "")
        #expect(recommendation.tips.isEmpty)
    }
    
    // MARK: - EnhancedTripSubmission Tests
    
    @Test func testEnhancedTripSubmissionCodable() async throws {
        let submission = EnhancedTripSubmission(
            destinations: ["Tokyo", "Kyoto"],
            startDate: "2024-06-01",
            endDate: "2024-06-10",
            flexibleDates: false,
            tripDuration: 9,
            budget: "5000",
            travelStyle: "Comfortable",
            groupSize: 2,
            specialRequests: "Looking for authentic experiences",
            interests: ["Culture", "Food"],
            flightClass: "Economy"
        )
        
        // Test encoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(submission)
        #expect(data.count > 0)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedSubmission = try decoder.decode(EnhancedTripSubmission.self, from: data)
        
        #expect(decodedSubmission.destinations == submission.destinations)
        #expect(decodedSubmission.startDate == submission.startDate)
        #expect(decodedSubmission.endDate == submission.endDate)
        #expect(decodedSubmission.flexibleDates == submission.flexibleDates)
        #expect(decodedSubmission.tripDuration == submission.tripDuration)
        #expect(decodedSubmission.budget == submission.budget)
        #expect(decodedSubmission.travelStyle == submission.travelStyle)
        #expect(decodedSubmission.groupSize == submission.groupSize)
        #expect(decodedSubmission.specialRequests == submission.specialRequests)
        #expect(decodedSubmission.interests == submission.interests)
        #expect(decodedSubmission.flightClass == submission.flightClass)
    }
    
    // MARK: - Error Handling Tests
    
    @Test func testTravelAppErrorLocalizedDescriptions() async throws {
        #expect(TravelAppError.authenticationFailed.localizedDescription == "Authentication failed. Please try logging in again.")
        #expect(TravelAppError.networkError("Connection failed").localizedDescription == "Network error: Connection failed")
        #expect(TravelAppError.dataError("Invalid JSON").localizedDescription == "Data error: Invalid JSON")
        #expect(TravelAppError.submissionFailed("Server error").localizedDescription == "Trip submission failed: Server error")
        #expect(TravelAppError.unknown.localizedDescription == "An unknown error occurred. Please try again.")
    }
}