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
    
    func testAdminDestinationBasedRecommendationRichDecoding() throws {
        let json = """
        {
          "id": "rec-1",
          "tripOverview": "Paris & London Points Itinerary",
          "costNotes": "Transfer 50k Chase UR to Air France Flying Blue and 90k Chase UR to Hyatt.",
          "destinations": [
            {
              "id": "dest-1",
              "cityName": "Paris",
              "arrivalDate": "2026-05-12",
              "departureDate": "2026-05-14",
              "numberOfNights": 2,
              "overview": "Romantic stay near Place Vendôme.",
              "accommodationOptions": [
                {
                  "id": "acc-1",
                  "priority": 1,
                  "bookingInstructions": "Transfer 90k Chase UR to World of Hyatt.",
                  "hotel": {
                    "name": "Park Hyatt Paris-Vendôme",
                    "rating": 5.0,
                    "pricePerNight": 0,
                    "pointsPerNight": 45000,
                    "loyaltyProgram": "World of Hyatt",
                    "location": "5 Rue de la Paix, Paris",
                    "bookingUrl": "https://www.hyatt.com",
                    "detailedDescription": "Palace hotel in central Paris.",
                    "amenities": ["Spa", "Breakfast"]
                  }
                }
              ],
              "recommendedActivities": [
                {
                  "id": "act-1",
                  "name": "Louvre Evening Tour",
                  "description": "Guided tour",
                  "location": { "name": "Louvre", "address": "Rue de Rivoli" },
                  "estimatedCost": { "cashAmount": 65 },
                  "estimatedDuration": "3h",
                  "category": "Culture",
                  "priority": 1,
                  "bestTimeToVisit": "Friday evening",
                  "bookingRequired": true,
                  "bookingInstructions": "Book 60 days ahead",
                  "tips": "Use Carrousel entrance"
                }
              ],
              "recommendedRestaurants": [
                {
                  "id": "rest-1",
                  "name": "Le Comptoir",
                  "cuisine": "French",
                  "mealType": "Dinner",
                  "location": { "name": "Saint-Germain", "address": "9 Carrefour de l'Odéon" },
                  "priceRange": "$$$",
                  "estimatedCost": { "cashAmount": 120 },
                  "description": "Classic bistro",
                  "reservationRequired": false,
                  "specialties": "Duck confit",
                  "tips": "Arrive by 6:45pm"
                }
              ]
            }
          ],
          "logistics": {
            "transportSegments": [
              {
                "id": "seg-1",
                "fromCity": "New York",
                "toCity": "Paris",
                "departureDate": "2026-05-11",
                "transportOptions": [
                  {
                    "id": "opt-1",
                    "transportType": "flight",
                    "priority": 1,
                    "duration": "7h 15m",
                    "bookingUrl": "https://www.airfrance.us",
                    "notes": "Business Class award",
                    "cost": {
                      "paymentType": "hybrid",
                      "cashAmount": 210,
                      "totalCashValue": 210,
                      "pointsAmount": 50000,
                      "pointsProgram": "Air France Flying Blue"
                    },
                    "details": {
                      "flightNumber": "AF 11",
                      "airline": "Air France",
                      "departureAirportName": "JFK International",
                      "arrivalAirportName": "Charles de Gaulle",
                      "class": "Business",
                      "aircraft": "B777-300ER",
                      "details": {
                        "departure": { "airportCode": "JFK", "time": "19:30", "date": "2026-05-11" },
                        "arrival": { "airportCode": "CDG", "time": "08:45", "date": "2026-05-12" },
                        "route": "JFK → CDG",
                        "showDateChange": "+1 day"
                      }
                    }
                  }
                ]
              }
            ],
            "bookingDeadlines": [],
            "generalInstructions": "Transfer points after verifying award space."
          },
          "totalCost": {
            "totalEstimate": 395,
            "flights": 210,
            "accommodation": 0,
            "activities": 65,
            "food": 120,
            "localTransport": 0,
            "miscellaneous": 0,
            "currency": "USD",
            "pointsUsed": {
              "Air France Flying Blue": 50000,
              "World of Hyatt": 90000
            }
          },
          "_schemaVersion": "2.1.0"
        }
        """.data(using: .utf8)!
        
        let decoded = try JSONDecoder().decode(AdminDestinationBasedRecommendation.self, from: json)
        XCTAssertEqual(decoded.costNotes, "Transfer 50k Chase UR to Air France Flying Blue and 90k Chase UR to Hyatt.")
        XCTAssertEqual(decoded.destinations.first?.overview, "Romantic stay near Place Vendôme.")
        XCTAssertEqual(decoded.destinations.first?.accommodationOptions.first?.effectiveBookingInstructions, "Transfer 90k Chase UR to World of Hyatt.")
        XCTAssertEqual(decoded.destinations.first?.recommendedActivities.first?.tips, "Use Carrousel entrance")
        XCTAssertEqual(decoded.destinations.first?.recommendedActivities.first?.bestTimeToVisit, "Friday evening")
        XCTAssertEqual(decoded.destinations.first?.recommendedRestaurants.first?.mealType, "Dinner")
        XCTAssertEqual(decoded.destinations.first?.recommendedRestaurants.first?.specialties, "Duck confit")
        let flightOpt = decoded.logistics.transportSegments.first?.transportOptions.first
        XCTAssertEqual(flightOpt?.details.details.departure.airportCode, "JFK")
        XCTAssertEqual(flightOpt?.details.details.arrival.airportCode, "CDG")
        XCTAssertTrue(flightOpt?.details.details.showDateChange ?? false)
        XCTAssertEqual(flightOpt?.details.details.dateChangeText, "+1 day")
        XCTAssertEqual(decoded.totalCost.pointsUsed?["World of Hyatt"], 90000)
    }
}