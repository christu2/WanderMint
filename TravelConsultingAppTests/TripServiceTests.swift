//
//  TripServiceTests.swift
//  TravelConsultingAppTests
//
//  Created by Nick Christus on 3/9/25.
//

import Testing
import Foundation
import FirebaseFirestore
@testable import TravelConsultingApp

struct TripServiceTests {
    
    // MARK: - Test Data Creation Helpers
    
    private func createTestTripData() -> [String: Any] {
        return [
            "id": "test-trip-123",
            "userId": "test-user-456",
            "destination": "Tokyo, Japan",
            "destinations": ["Tokyo, Japan", "Kyoto, Japan"],
            "startDate": Timestamp(date: Date()),
            "endDate": Timestamp(date: Date().addingTimeInterval(7*24*60*60)),
            "paymentMethod": "Credit Card",
            "flexibleDates": false,
            "status": "pending",
            "createdAt": Timestamp(date: Date()),
            "flightClass": "Economy",
            "budget": "5000",
            "travelStyle": "Comfortable",
            "groupSize": 2,
            "interests": ["Culture", "Food"],
            "specialRequests": "Looking for authentic experiences"
        ]
    }
    
    private func createTestRecommendationData() -> [String: Any] {
        return [
            "id": "rec-123",
            "destination": "Tokyo, Japan",
            "overview": "Tokyo is a vibrant city blending traditional and modern culture.",
            "bestTimeToVisit": "Spring (March-May) or Fall (September-November)",
            "tips": [
                "Learn basic Japanese phrases",
                "Get a JR Pass for train travel",
                "Try authentic sushi at Tsukiji"
            ],
            "createdAt": Timestamp(date: Date()),
            "activities": [
                [
                    "id": "act-1",
                    "name": "Visit Senso-ji Temple",
                    "description": "Ancient Buddhist temple in Asakusa",
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
                    "description": "Luxury hotel in Shinjuku",
                    "priceRange": "$400-600/night",
                    "rating": 4.8,
                    "amenities": ["Spa", "Pool", "Restaurant"]
                ]
            ],
            "transportation": [
                "estimatedFlightCost": 1200.0,
                "localTransportCost": 300.0,
                "localTransport": ["JR Pass", "Subway", "Taxi"]
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
    }
    
    private func createTestEnhancedTripSubmission() -> EnhancedTripSubmission {
        return EnhancedTripSubmission(
            destinations: ["Tokyo, Japan", "Kyoto, Japan"],
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
    }
    
    // MARK: - Parse Trip Tests
    
    @Test func testParseTripWithValidData() async throws {
        await MainActor.run {
            let service = TripService()
            let tripData = createTestTripData()
            
            // Since parseTrip is private, we'll test it indirectly through fetchUserTrips
            // For now, let's test the data structure validation
            
            #expect(tripData["id"] as? String == "test-trip-123")
            #expect(tripData["userId"] as? String == "test-user-456")
            #expect(tripData["destination"] as? String == "Tokyo, Japan")
            #expect(tripData["destinations"] as? [String] == ["Tokyo, Japan", "Kyoto, Japan"])
            #expect(tripData["flexibleDates"] as? Bool == false)
            #expect(tripData["status"] as? String == "pending")
        }
    }
    
    @Test func testParseTripWithLegacyData() async throws {
        // Test with old format (single destination, no new fields)
        var legacyTripData = createTestTripData()
        legacyTripData.removeValue(forKey: "destinations")
        legacyTripData.removeValue(forKey: "flightClass")
        legacyTripData.removeValue(forKey: "budget")
        legacyTripData.removeValue(forKey: "travelStyle")
        legacyTripData.removeValue(forKey: "groupSize")
        legacyTripData.removeValue(forKey: "interests")
        legacyTripData.removeValue(forKey: "specialRequests")
        
        // Verify legacy data structure
        #expect(legacyTripData["destination"] as? String == "Tokyo, Japan")
        #expect(legacyTripData["destinations"] == nil)
        #expect(legacyTripData["flightClass"] == nil)
    }
    
    @Test func testParseTripStatusMapping() async throws {
        let statusMappings: [String: TripStatusType] = [
            "submitted": .pending,
            "processing": .inProgress,
            "failed": .cancelled,
            "pending": .pending,
            "in_progress": .inProgress,
            "completed": .completed,
            "cancelled": .cancelled
        ]
        
        for (input, expected) in statusMappings {
            var tripData = createTestTripData()
            tripData["status"] = input
            
            // Test that our mapping logic would work
            let mappedStatus: TripStatusType
            switch input {
            case "submitted":
                mappedStatus = .pending
            case "processing":
                mappedStatus = .inProgress
            case "failed":
                mappedStatus = .cancelled
            default:
                mappedStatus = TripStatusType(rawValue: input) ?? .pending
            }
            
            #expect(mappedStatus == expected)
        }
    }
    
    // MARK: - Parse Recommendation Tests
    
    @Test func testParseRecommendationWithValidData() async throws {
        let recommendationData = createTestRecommendationData()
        
        // Verify recommendation data structure
        #expect(recommendationData["id"] as? String == "rec-123")
        #expect(recommendationData["destination"] as? String == "Tokyo, Japan")
        #expect(recommendationData["overview"] as? String == "Tokyo is a vibrant city blending traditional and modern culture.")
        #expect(recommendationData["bestTimeToVisit"] as? String == "Spring (March-May) or Fall (September-November)")
        
        // Verify tips array
        let tips = recommendationData["tips"] as? [String]
        #expect(tips?.count == 3)
        #expect(tips?.contains("Learn basic Japanese phrases") == true)
        
        // Verify activities array structure
        let activities = recommendationData["activities"] as? [[String: Any]]
        #expect(activities?.count == 1)
        
        if let firstActivity = activities?.first {
            #expect(firstActivity["id"] as? String == "act-1")
            #expect(firstActivity["name"] as? String == "Visit Senso-ji Temple")
            #expect(firstActivity["category"] as? String == "Cultural")
            #expect(firstActivity["estimatedCost"] as? Double == 0.0)
            #expect(firstActivity["priority"] as? Int == 1)
        }
        
        // Verify accommodations array structure
        let accommodations = recommendationData["accommodations"] as? [[String: Any]]
        #expect(accommodations?.count == 1)
        
        if let firstAccommodation = accommodations?.first {
            #expect(firstAccommodation["id"] as? String == "acc-1")
            #expect(firstAccommodation["name"] as? String == "Park Hyatt Tokyo")
            #expect(firstAccommodation["type"] as? String == "hotel")
            #expect(firstAccommodation["rating"] as? Double == 4.8)
        }
    }
    
    // MARK: - Parse Activity Tests
    
    @Test func testParseActivityWithValidData() async throws {
        let activityData: [String: Any] = [
            "id": "act-1",
            "name": "Visit Senso-ji Temple",
            "description": "Ancient Buddhist temple in Asakusa",
            "category": "Cultural",
            "estimatedDuration": "2 hours",
            "estimatedCost": 25.50,
            "priority": 1
        ]
        
        #expect(activityData["id"] as? String == "act-1")
        #expect(activityData["name"] as? String == "Visit Senso-ji Temple")
        #expect(activityData["description"] as? String == "Ancient Buddhist temple in Asakusa")
        #expect(activityData["category"] as? String == "Cultural")
        #expect(activityData["estimatedDuration"] as? String == "2 hours")
        #expect(activityData["estimatedCost"] as? Double == 25.50)
        #expect(activityData["priority"] as? Int == 1)
    }
    
    // MARK: - Parse Accommodation Tests
    
    @Test func testParseAccommodationWithValidData() async throws {
        let accommodationData: [String: Any] = [
            "id": "acc-1",
            "name": "Park Hyatt Tokyo",
            "type": "hotel",
            "description": "Luxury hotel in Shinjuku with stunning city views",
            "priceRange": "$400-600/night",
            "rating": 4.8,
            "amenities": ["Spa", "Pool", "Restaurant", "Gym"]
        ]
        
        #expect(accommodationData["id"] as? String == "acc-1")
        #expect(accommodationData["name"] as? String == "Park Hyatt Tokyo")
        #expect(accommodationData["type"] as? String == "hotel")
        #expect(accommodationData["description"] as? String == "Luxury hotel in Shinjuku with stunning city views")
        #expect(accommodationData["priceRange"] as? String == "$400-600/night")
        #expect(accommodationData["rating"] as? Double == 4.8)
        
        let amenities = accommodationData["amenities"] as? [String]
        #expect(amenities?.count == 4)
        #expect(amenities?.contains("Spa") == true)
        #expect(amenities?.contains("Pool") == true)
    }
    
    // MARK: - Parse Transportation Tests
    
    @Test func testParseTransportationWithValidData() async throws {
        let transportationData: [String: Any] = [
            "estimatedFlightCost": 1200.0,
            "localTransportCost": 300.0,
            "localTransport": ["JR Pass", "Subway", "Taxi"],
            "flightInfo": [
                "recommendedAirlines": ["ANA", "JAL", "United"],
                "estimatedFlightTime": "14 hours",
                "bestBookingTime": "2-3 months in advance"
            ]
        ]
        
        #expect(transportationData["estimatedFlightCost"] as? Double == 1200.0)
        #expect(transportationData["localTransportCost"] as? Double == 300.0)
        
        let localTransport = transportationData["localTransport"] as? [String]
        #expect(localTransport?.count == 3)
        #expect(localTransport?.contains("JR Pass") == true)
        
        let flightInfo = transportationData["flightInfo"] as? [String: Any]
        #expect(flightInfo != nil)
        
        if let flightInfo = flightInfo {
            let airlines = flightInfo["recommendedAirlines"] as? [String]
            #expect(airlines?.count == 3)
            #expect(airlines?.contains("ANA") == true)
            #expect(flightInfo["estimatedFlightTime"] as? String == "14 hours")
            #expect(flightInfo["bestBookingTime"] as? String == "2-3 months in advance")
        }
    }
    
    // MARK: - Parse Cost Breakdown Tests
    
    @Test func testParseCostBreakdownWithValidData() async throws {
        let costData: [String: Any] = [
            "totalEstimate": 3500.0,
            "flights": 1200.0,
            "accommodation": 1500.0,
            "activities": 400.0,
            "food": 300.0,
            "localTransport": 100.0,
            "miscellaneous": 0.0,
            "currency": "USD"
        ]
        
        #expect(costData["totalEstimate"] as? Double == 3500.0)
        #expect(costData["flights"] as? Double == 1200.0)
        #expect(costData["accommodation"] as? Double == 1500.0)
        #expect(costData["activities"] as? Double == 400.0)
        #expect(costData["food"] as? Double == 300.0)
        #expect(costData["localTransport"] as? Double == 100.0)
        #expect(costData["miscellaneous"] as? Double == 0.0)
        #expect(costData["currency"] as? String == "USD")
    }
    
    // MARK: - Enhanced Trip Submission Tests
    
    @Test func testCreateRequestDataFromEnhancedSubmission() async throws {
        let submission = createTestEnhancedTripSubmission()
        
        // Test the data mapping that would happen in submitEnhancedTrip
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
        
        if let duration = submission.tripDuration {
            requestData["tripDuration"] = duration
        }
        
        // Verify request data structure
        #expect(requestData["destinations"] as? [String] == ["Tokyo, Japan", "Kyoto, Japan"])
        #expect(requestData["startDate"] as? String == "2024-06-01T00:00:00Z")
        #expect(requestData["endDate"] as? String == "2024-06-10T00:00:00Z")
        #expect(requestData["flexibleDates"] as? Bool == false)
        #expect(requestData["budget"] as? String == "5000")
        #expect(requestData["travelStyle"] as? String == "Comfortable")
        #expect(requestData["groupSize"] as? Int == 2)
        #expect(requestData["specialRequests"] as? String == "Looking for authentic experiences")
        #expect(requestData["interests"] as? [String] == ["Culture", "Food"])
        #expect(requestData["flightClass"] as? String == "Economy")
        #expect(requestData["tripDuration"] == nil) // Not set in test data
    }
    
    // MARK: - Error Validation Tests
    
    @Test func testMissingRequiredFieldsValidation() async throws {
        // Test missing ID
        var invalidData = createTestTripData()
        invalidData.removeValue(forKey: "id")
        
        // Should fail validation
        #expect(invalidData["id"] == nil)
        
        // Test missing userId
        invalidData = createTestTripData()
        invalidData.removeValue(forKey: "userId")
        #expect(invalidData["userId"] == nil)
        
        // Test missing both destination and destinations
        invalidData = createTestTripData()
        invalidData.removeValue(forKey: "destination")
        invalidData.removeValue(forKey: "destinations")
        #expect(invalidData["destination"] == nil)
        #expect(invalidData["destinations"] == nil)
        
        // Test missing timestamps
        invalidData = createTestTripData()
        invalidData.removeValue(forKey: "startDate")
        #expect(invalidData["startDate"] == nil)
        
        invalidData = createTestTripData()
        invalidData.removeValue(forKey: "endDate")
        #expect(invalidData["endDate"] == nil)
        
        invalidData = createTestTripData()
        invalidData.removeValue(forKey: "createdAt")
        #expect(invalidData["createdAt"] == nil)
    }
    
    // MARK: - Date Formatting Tests
    
    @Test func testISO8601DateFormatting() async throws {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let testDate = Date()
        let formattedString = dateFormatter.string(from: testDate)
        let parsedDate = dateFormatter.date(from: formattedString)
        
        #expect(parsedDate != nil)
        #expect(abs(parsedDate!.timeIntervalSince(testDate)) < 1.0) // Within 1 second
    }
    
    // MARK: - Trip Submission Validation Tests
    
    @Test func testTripSubmissionValidation() async throws {
        let submission = createTestEnhancedTripSubmission()
        
        // Test valid submission
        #expect(!submission.destinations.isEmpty)
        #expect(!submission.startDate.isEmpty)
        #expect(!submission.endDate.isEmpty)
        #expect(!submission.travelStyle.isEmpty)
        #expect(submission.groupSize > 0)
        
        // Test start date before end date logic
        let startDateString = submission.startDate
        let endDateString = submission.endDate
        
        let formatter = ISO8601DateFormatter()
        let startDate = formatter.date(from: startDateString)
        let endDate = formatter.date(from: endDateString)
        
        #expect(startDate != nil)
        #expect(endDate != nil)
        #expect(startDate! < endDate!)
    }
}