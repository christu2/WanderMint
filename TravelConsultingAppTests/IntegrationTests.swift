//
//  IntegrationTests.swift
//  TravelConsultingAppTests
//
//  Created by Nick Christus on 3/9/25.
//

import Testing
import Foundation
import FirebaseFirestore
@testable import TravelConsultingApp

struct IntegrationTests {
    
    // MARK: - Trip Submission Integration Tests
    
    @Test func testTripSubmissionWorkflow() async throws {
        // Test the complete trip submission workflow
        let submission = EnhancedTripSubmission(
            destinations: ["Tokyo, Japan"],
            startDate: "2024-06-01T00:00:00Z",
            endDate: "2024-06-10T00:00:00Z",
            flexibleDates: false,
            tripDuration: nil,
            budget: "5000",
            travelStyle: "Comfortable",
            groupSize: 2,
            specialRequests: "Looking for authentic experiences",
            interests: ["Culture", "Food"],
            flightClass: "Economy"
        )
        
        // Validate submission data
        #expect(!submission.destinations.isEmpty)
        #expect(!submission.startDate.isEmpty)
        #expect(!submission.endDate.isEmpty)
        #expect(submission.groupSize > 0)
        
        // Test date parsing
        let formatter = ISO8601DateFormatter()
        let startDate = formatter.date(from: submission.startDate)
        let endDate = formatter.date(from: submission.endDate)
        
        #expect(startDate != nil)
        #expect(endDate != nil)
        #expect(startDate! < endDate!)
        
        // Test request data generation (as would happen in TripService)
        var requestData: [String: Any] = [
            "destinations": submission.destinations,
            "startDate": submission.startDate,
            "endDate": submission.endDate,
            "flexibleDates": submission.flexibleDates,
            "budget": submission.budget ?? "",
            "travelStyle": submission.travelStyle,
            "groupSize": submission.groupSize,
            "specialRequests": submission.specialRequests,
            "interests": submission.interests
        ]
        
        if let flightClass = submission.flightClass {
            requestData["flightClass"] = flightClass
        }
        
        // Validate request data structure
        #expect(requestData["destinations"] as? [String] == ["Tokyo, Japan"])
        #expect(requestData["budget"] as? String == "5000")
        #expect(requestData["flightClass"] as? String == "Economy")
    }
    
    @Test func testPointsManagementWorkflow() async throws {
        // Test the complete points management workflow
        let userId = "test-user-123"
        
        // Create initial points data
        let initialData: [String: Any] = [
            "userId": userId,
            "creditCardPoints": [:] as [String: Int],
            "hotelPoints": [:] as [String: Int],
            "airlinePoints": [:] as [String: Int],
            "lastUpdated": Timestamp(date: Date())
        ]
        
        // Test adding points
        var creditCardPoints = initialData["creditCardPoints"] as! [String: Int]
        creditCardPoints["Chase"] = 50000
        
        var updatedData = initialData
        updatedData["creditCardPoints"] = creditCardPoints
        updatedData["lastUpdated"] = Timestamp(date: Date())
        
        #expect((updatedData["creditCardPoints"] as! [String: Int])["Chase"] == 50000)
        
        // Test updating points
        creditCardPoints["Chase"] = 75000
        creditCardPoints["Amex"] = 60000
        updatedData["creditCardPoints"] = creditCardPoints
        
        #expect((updatedData["creditCardPoints"] as! [String: Int])["Chase"] == 75000)
        #expect((updatedData["creditCardPoints"] as! [String: Int])["Amex"] == 60000)
        
        // Test removing points
        creditCardPoints.removeValue(forKey: "Chase")
        updatedData["creditCardPoints"] = creditCardPoints
        
        #expect((updatedData["creditCardPoints"] as! [String: Int])["Chase"] == nil)
        #expect((updatedData["creditCardPoints"] as! [String: Int])["Amex"] == 60000)
    }
    
    @Test func testTripDataParsingWorkflow() async throws {
        // Test parsing a complete trip with recommendation
        let tripData: [String: Any] = [
            "id": "trip-123",
            "userId": "user-456",
            "destinations": ["Tokyo, Japan", "Kyoto, Japan"],
            "startDate": Timestamp(date: Date()),
            "endDate": Timestamp(date: Date().addingTimeInterval(7*24*60*60)),
            "flexibleDates": false,
            "status": "completed",
            "createdAt": Timestamp(date: Date()),
            "budget": "5000",
            "travelStyle": "Comfortable",
            "groupSize": 2,
            "interests": ["Culture", "Food"],
            "recommendation": [
                "id": "rec-789",
                "destination": "Tokyo, Japan",
                "overview": "Amazing cultural experience",
                "bestTimeToVisit": "Spring",
                "tips": ["Learn basic Japanese", "Get JR Pass"],
                "createdAt": Timestamp(date: Date()),
                "activities": [
                    [
                        "id": "act-1",
                        "name": "Visit Senso-ji Temple",
                        "description": "Historic temple",
                        "category": "Cultural",
                        "estimatedDuration": "2 hours",
                        "estimatedCost": 0.0,
                        "priority": 1
                    ]
                ],
                "accommodations": [
                    [
                        "id": "acc-1",
                        "name": "Park Hyatt Tokyo",
                        "type": "hotel",
                        "description": "Luxury hotel",
                        "priceRange": "$400-600/night",
                        "rating": 4.8,
                        "amenities": ["Spa", "Pool"]
                    ]
                ],
                "estimatedCost": [
                    "totalEstimate": 3500.0,
                    "flights": 1200.0,
                    "accommodation": 1500.0,
                    "activities": 400.0,
                    "food": 300.0,
                    "localTransport": 100.0,
                    "miscellaneous": 0.0,
                    "currency": "USD"
                ]
            ]
        ]
        
        // Validate trip structure
        #expect(tripData["id"] as? String == "trip-123")
        #expect(tripData["userId"] as? String == "user-456")
        #expect((tripData["destinations"] as? [String])?.count == 2)
        
        // Validate recommendation structure
        let recommendation = tripData["recommendation"] as? [String: Any]
        #expect(recommendation != nil)
        #expect(recommendation?["id"] as? String == "rec-789")
        #expect(recommendation?["destination"] as? String == "Tokyo, Japan")
        
        // Validate activities
        let activities = recommendation?["activities"] as? [[String: Any]]
        #expect(activities?.count == 1)
        #expect(activities?.first?["name"] as? String == "Visit Senso-ji Temple")
        
        // Validate accommodations
        let accommodations = recommendation?["accommodations"] as? [[String: Any]]
        #expect(accommodations?.count == 1)
        #expect(accommodations?.first?["name"] as? String == "Park Hyatt Tokyo")
        
        // Validate cost breakdown
        let estimatedCost = recommendation?["estimatedCost"] as? [String: Any]
        #expect(estimatedCost?["totalEstimate"] as? Double == 3500.0)
        #expect(estimatedCost?["currency"] as? String == "USD")
    }
    
    @Test func testErrorHandlingWorkflow() async throws {
        // Test error handling throughout the application
        
        // Test TravelAppError creation and descriptions
        let authError = TravelAppError.authenticationFailed
        let networkError = TravelAppError.networkError("Connection timeout")
        let dataError = TravelAppError.dataError("Invalid JSON format")
        let submissionError = TravelAppError.submissionFailed("Server returned 500")
        let unknownError = TravelAppError.unknown
        
        #expect(authError.localizedDescription == "Authentication failed. Please try logging in again.")
        #expect(networkError.localizedDescription == "Network error: Connection timeout")
        #expect(dataError.localizedDescription == "Data error: Invalid JSON format")
        #expect(submissionError.localizedDescription == "Trip submission failed: Server returned 500")
        #expect(unknownError.localizedDescription == "An unknown error occurred. Please try again.")
        
        // Test error propagation in ViewModels
        await MainActor.run {
            let viewModel = TripSubmissionViewModel()
            
            // Simulate different error scenarios
            viewModel.errorMessage = authError.localizedDescription
            #expect(viewModel.errorMessage?.contains("Authentication failed") == true)
            
            viewModel.errorMessage = networkError.localizedDescription
            #expect(viewModel.errorMessage?.contains("Connection timeout") == true)
            
            // Test error clearing
            viewModel.clearError()
            #expect(viewModel.errorMessage == nil)
        }
    }
    
    @Test func testDataConsistencyWorkflow() async throws {
        // Test data consistency across different models
        
        // Create a trip with all related data
        let tripId = "trip-consistency-test"
        let userId = "user-consistency-test"
        let destinationName = "Tokyo, Japan"
        
        // Trip data
        let trip = TravelTrip(
            id: tripId,
            userId: userId,
            destination: destinationName,
            destinations: [destinationName],
            startDate: Timestamp(date: Date()),
            endDate: Timestamp(date: Date().addingTimeInterval(7*24*60*60)),
            paymentMethod: nil,
            flexibleDates: false,
            status: .completed,
            createdAt: Timestamp(date: Date()),
            updatedAt: nil,
            recommendation: nil,
            flightClass: "Economy",
            budget: "5000",
            travelStyle: "Comfortable",
            groupSize: 2,
            interests: ["Culture", "Food"],
            specialRequests: "Authentic experiences"
        )
        
        // Recommendation data that should match the trip
        let recommendation = Recommendation(
            id: "rec-for-\(tripId)",
            destination: destinationName,
            overview: "Complete Tokyo experience",
            createdAt: Timestamp(date: Date())
        )
        
        // Points profile for the same user
        let pointsProfile = UserPointsProfile(
            userId: userId,
            creditCardPoints: ["Chase": 75000],
            hotelPoints: ["Hyatt": 30000],
            airlinePoints: ["United": 60000],
            lastUpdated: Timestamp(date: Date())
        )
        
        // Verify consistency
        #expect(trip.userId == pointsProfile.userId)
        #expect(trip.displayDestinations.contains(recommendation.destination))
        #expect(trip.id == tripId)
        #expect(recommendation.destination == destinationName)
        #expect(pointsProfile.userId == userId)
    }
    
    @Test func testFlexibleCostCalculationWorkflow() async throws {
        // Test flexible cost calculations across different scenarios
        
        // Scenario 1: Cash-only costs
        let flightCost = FlexibleCost(cashOnly: 1200.0)
        let hotelCost = FlexibleCost(cashOnly: 1500.0)
        let activityCost = FlexibleCost(cashOnly: 400.0)
        
        let totalCashCost = flightCost.totalCashValue + hotelCost.totalCashValue + activityCost.totalCashValue
        #expect(totalCashCost == 3100.0)
        
        // Scenario 2: Points-based costs
        let flightPointsCost = FlexibleCost(pointsOnly: 80000, program: "Chase", cashValue: 1000.0)
        let hotelPointsCost = FlexibleCost(pointsOnly: 60000, program: "Hyatt", cashValue: 1200.0)
        
        let totalPointsValue = flightPointsCost.totalCashValue + hotelPointsCost.totalCashValue
        #expect(totalPointsValue == 2200.0)
        
        // Scenario 3: Hybrid costs
        let hybridFlightCost = FlexibleCost(hybrid: 300.0, points: 40000, program: "Chase")
        let hybridHotelCost = FlexibleCost(hybrid: 500.0, points: 30000, program: "Hyatt")
        
        let totalHybridCash = hybridFlightCost.cashAmount + hybridHotelCost.cashAmount
        let totalHybridPoints = (hybridFlightCost.pointsAmount ?? 0) + (hybridHotelCost.pointsAmount ?? 0)
        
        #expect(totalHybridCash == 800.0)
        #expect(totalHybridPoints == 70000)
        
        // Test display text consistency
        #expect(flightCost.displayText == "$1200")
        #expect(flightPointsCost.displayText.contains("80,000"))
        #expect(flightPointsCost.displayText.contains("Chase"))
        #expect(hybridFlightCost.displayText.contains("$300"))
        #expect(hybridFlightCost.displayText.contains("40,000"))
    }
    
    @Test func testDateValidationWorkflow() async throws {
        // Test date validation across the application
        
        let today = Date()
        let tomorrow = Date().addingTimeInterval(24 * 60 * 60)
        let nextWeek = Date().addingTimeInterval(7 * 24 * 60 * 60)
        let nextMonth = Date().addingTimeInterval(30 * 24 * 60 * 60)
        
        // Test valid date ranges
        #expect(tomorrow > today)
        #expect(nextWeek > tomorrow)
        #expect(nextMonth > nextWeek)
        
        // Test trip date validation
        let validTripDates = nextWeek > tomorrow
        #expect(validTripDates == true)
        
        // Test flexible date validation
        let earliestStart = tomorrow
        let latestStart = nextWeek
        let flexibleDatesValid = latestStart >= earliestStart
        #expect(flexibleDatesValid == true)
        
        // Test invalid scenarios
        let invalidEndDate = Date().addingTimeInterval(-24 * 60 * 60) // Yesterday
        let invalidTripDates = invalidEndDate > today
        #expect(invalidTripDates == false)
        
        // Test ISO8601 formatting consistency
        let formatter = ISO8601DateFormatter()
        let formattedToday = formatter.string(from: today)
        let parsedToday = formatter.date(from: formattedToday)
        
        #expect(parsedToday != nil)
        #expect(abs(parsedToday!.timeIntervalSince(today)) < 1.0)
    }
    
    @Test func testUserWorkflowIntegration() async throws {
        // Test complete user workflow from registration to trip completion
        
        // Step 1: User registration data
        let userEmail = "test@example.com"
        let userId = "user-workflow-test"
        
        // Validate email
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        let emailValid = emailPredicate.evaluate(with: userEmail)
        #expect(emailValid == true)
        
        // Step 2: User creates points profile
        let pointsProfile = UserPointsProfile(
            userId: userId,
            creditCardPoints: ["Chase": 50000],
            hotelPoints: [:],
            airlinePoints: [:],
            lastUpdated: Timestamp(date: Date())
        )
        
        #expect(pointsProfile.userId == userId)
        #expect(pointsProfile.creditCardPoints["Chase"] == 50000)
        
        // Step 3: User submits trip
        let tripSubmission = EnhancedTripSubmission(
            destinations: ["Tokyo, Japan"],
            startDate: ISO8601DateFormatter().string(from: Date().addingTimeInterval(30*24*60*60)),
            endDate: ISO8601DateFormatter().string(from: Date().addingTimeInterval(37*24*60*60)),
            flexibleDates: false,
            tripDuration: nil,
            budget: "5000",
            travelStyle: "Comfortable",
            groupSize: 2,
            specialRequests: "First time in Japan",
            interests: ["Culture", "Food"],
            flightClass: "Economy"
        )
        
        #expect(tripSubmission.destinations.count == 1)
        #expect(tripSubmission.groupSize == 2)
        #expect(tripSubmission.interests.contains("Culture"))
        
        // Step 4: Trip gets processed and completed
        let completedTrip = TravelTrip(
            id: "trip-\(userId)",
            userId: userId,
            destination: nil,
            destinations: tripSubmission.destinations,
            startDate: Timestamp(date: ISO8601DateFormatter().date(from: tripSubmission.startDate)!),
            endDate: Timestamp(date: ISO8601DateFormatter().date(from: tripSubmission.endDate)!),
            paymentMethod: nil,
            flexibleDates: tripSubmission.flexibleDates,
            status: .completed,
            createdAt: Timestamp(date: Date()),
            updatedAt: Timestamp(date: Date()),
            recommendation: nil,
            flightClass: tripSubmission.flightClass,
            budget: tripSubmission.budget,
            travelStyle: tripSubmission.travelStyle,
            groupSize: tripSubmission.groupSize,
            interests: tripSubmission.interests,
            specialRequests: tripSubmission.specialRequests
        )
        
        // Verify workflow consistency
        #expect(completedTrip.userId == pointsProfile.userId)
        #expect(completedTrip.destinations == tripSubmission.destinations)
        #expect(completedTrip.budget == tripSubmission.budget)
        #expect(completedTrip.travelStyle == tripSubmission.travelStyle)
        #expect(completedTrip.groupSize == tripSubmission.groupSize)
        #expect(completedTrip.status == .completed)
    }
}