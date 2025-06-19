//
//  TravelConsultingAppTests.swift
//  TravelConsultingAppTests
//
//  Created by Nick Christus on 3/9/25.
//

import Testing
import Foundation
@testable import TravelConsultingApp

struct TravelConsultingAppTests {

    @Test func testAppMainComponents() async throws {
        // Test that main app components can be instantiated
        await MainActor.run {
            let authViewModel = AuthenticationViewModel()
            let tripSubmissionViewModel = TripSubmissionViewModel()
            let tripService = TripService()
            let pointsService = PointsService()
            
            #expect(authViewModel.isAuthenticated == false)
            #expect(tripSubmissionViewModel.isLoading == false)
            
            // Test that services are properly initialized
            #expect(tripService != nil)
            #expect(pointsService != nil)
        }
    }
    
    @Test func testDataModelsInstantiation() async throws {
        // Test that all data models can be properly instantiated
        let trip = TestDataFactory.createTestTravelTrip()
        let recommendation = TestDataFactory.createTestRecommendation()
        let pointsProfile = TestDataFactory.createTestUserPointsProfile()
        let submission = TestDataFactory.createTestEnhancedTripSubmission()
        
        #expect(!trip.id.isEmpty)
        #expect(!recommendation.id.isEmpty)
        #expect(!pointsProfile.userId.isEmpty)
        #expect(!submission.destinations.isEmpty)
    }
    
    @Test func testValidationHelpers() async throws {
        // Test email validation
        #expect(TestValidationHelpers.validateEmail("test@example.com") == true)
        #expect(TestValidationHelpers.validateEmail("invalid-email") == false)
        
        // Test password validation
        #expect(TestValidationHelpers.validatePassword("password123") == true)
        #expect(TestValidationHelpers.validatePassword("12345") == false)
        
        // Test group size validation
        #expect(TestValidationHelpers.validateGroupSize(2) == true)
        #expect(TestValidationHelpers.validateGroupSize(0) == false)
        #expect(TestValidationHelpers.validateGroupSize(25) == false)
        
        // Test trip duration validation
        #expect(TestValidationHelpers.validateTripDuration(7) == true)
        #expect(TestValidationHelpers.validateTripDuration(0) == false)
        #expect(TestValidationHelpers.validateTripDuration(35) == false)
    }
    
    @Test func testDataGenerators() async throws {
        // Test random data generators
        let destinations = TestDataGenerators.generateRandomDestinations(count: 3)
        let interests = TestDataGenerators.generateRandomInterests(count: 2)
        let travelStyle = TestDataGenerators.generateRandomTravelStyle()
        let flightClass = TestDataGenerators.generateRandomFlightClass()
        
        #expect(destinations.count == 3)
        #expect(interests.count == 2)
        #expect(!travelStyle.isEmpty)
        #expect(!flightClass.isEmpty)
        
        // Test points generators
        let provider = TestDataGenerators.generateRandomPointsProvider(for: .creditCard)
        let amount = TestDataGenerators.generateRandomPointsAmount()
        let budget = TestDataGenerators.generateRandomBudget()
        
        #expect(PointsProvider.creditCardProviders.contains(provider))
        #expect(amount >= 1000 && amount <= 500000)
        #expect(Int(budget) != nil)
    }
    
    @Test func testFlexibleCostScenarios() async throws {
        // Test different flexible cost scenarios
        let costs = TestDataFactory.createTestFlexibleCosts()
        
        #expect(costs.count == 3)
        
        let cashCost = costs[0]
        let pointsCost = costs[1]
        let hybridCost = costs[2]
        
        #expect(cashCost.paymentType == .cash)
        #expect(pointsCost.paymentType == .points)
        #expect(hybridCost.paymentType == .hybrid)
        
        #expect(cashCost.displayText.contains("$"))
        #expect(pointsCost.displayText.contains("points"))
        #expect(hybridCost.displayText.contains("$") && hybridCost.displayText.contains("+"))
    }
    
    @Test func testErrorScenarios() async throws {
        // Test all error types
        let errors = TestDataFactory.createTestErrors()
        
        #expect(errors.count == 5)
        
        for error in errors {
            let description = error.localizedDescription
            #expect(!description.isEmpty)
            #expect(description.count > 10) // Reasonable error message length
        }
    }
    
    @Test func testComprehensiveWorkflow() async throws {
        // Test a complete workflow using test utilities
        
        // 1. Create user and points profile
        let userId = "workflow-test-user"
        let pointsProfile = TestDataFactory.createTestUserPointsProfile(userId: userId)
        
        // 2. Create trip submission
        let submission = TestDataFactory.createTestEnhancedTripSubmission(
            destinations: ["Tokyo, Japan", "Kyoto, Japan"],
            flexibleDates: false
        )
        
        // 3. Create completed trip
        let trip = TestDataFactory.createTestTravelTrip(
            userId: userId,
            destination: "Tokyo, Japan",
            status: .completed,
            withRecommendation: true
        )
        
        // 4. Validate workflow consistency
        #expect(trip.userId == pointsProfile.userId)
        #expect(trip.displayDestinations.contains("Tokyo, Japan"))
        #expect(trip.status == .completed)
        #expect(trip.recommendation != nil)
        
        // 5. Test recommendation details
        if let recommendation = trip.recommendation {
            #expect(recommendation.destination == "Tokyo, Japan")
            #expect(!recommendation.overview.isEmpty)
            #expect(!recommendation.tips.isEmpty)
            #expect(recommendation.estimatedCost.totalEstimate > 0)
        }
        
        // 6. Test points calculations
        let totalCreditCardPoints = pointsProfile.creditCardPoints.values.reduce(0, +)
        let totalHotelPoints = pointsProfile.hotelPoints.values.reduce(0, +)
        let totalAirlinePoints = pointsProfile.airlinePoints.values.reduce(0, +)
        
        #expect(totalCreditCardPoints > 0)
        #expect(totalHotelPoints > 0)
        #expect(totalAirlinePoints > 0)
    }
    
    @Test func testDataIntegrity() async throws {
        // Test data integrity across all models
        
        let trip = TestDataFactory.createTestTravelTrip(withRecommendation: true)
        let pointsProfile = TestDataFactory.createTestUserPointsProfile(userId: trip.userId)
        
        // Use assertion helpers to validate data integrity
        TestAssertionHelpers.assertValidTrip(trip)
        TestAssertionHelpers.assertValidPointsProfile(pointsProfile)
        
        if let recommendation = trip.recommendation {
            TestAssertionHelpers.assertValidRecommendation(recommendation)
        }
        
        // Test flexible costs if present
        if let recommendation = trip.recommendation {
            for activity in recommendation.activities {
                let flexibleCost = FlexibleCost(cashOnly: activity.estimatedCost)
                TestAssertionHelpers.assertValidFlexibleCost(flexibleCost)
            }
        }
    }

}
