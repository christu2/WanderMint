import XCTest
import FirebaseFirestore
@testable import WanderMint

/// High-signal production readiness unit tests covering real iOS-to-Backend contracts,
/// Firestore parsing & NaN sanitization, points schema consistency, and security invariants.
final class ProductionReadinessTests: XCTestCase {
    
    // MARK: - 1. PointsType Firestore Schema Consistency (Regression for credit_cardPoints bug)
    
    func testPointsTypeFirestoreFieldNamesMatchBackendAndAdmin() {
        XCTAssertEqual(PointsType.creditCard.firestoreFieldName, "creditCardPoints")
        XCTAssertEqual(PointsType.hotel.firestoreFieldName, "hotelPoints")
        XCTAssertEqual(PointsType.airline.firestoreFieldName, "airlinePoints")
    }
    
    // MARK: - 2. TripService Contract Payload Serialization
    
    func testBuildEnhancedTripPayloadOmitsNilBudgetAndEmptyDeparture() {
        let submission = EnhancedTripSubmission(
            destinations: ["Madison, WI"],
            departureLocation: "   ",
            startDate: "2026-11-15",
            endDate: "2026-11-18",
            flexibleDates: false,
            tripDuration: nil,
            budget: nil,
            travelStyle: "Comfortable",
            groupSize: 2,
            petFriendly: true,
            optInEmailNotifications: false,
            specialRequests: "Walkable downtown",
            interests: ["Food"],
            flightClass: nil
        )
        
        let payload = TripService.buildEnhancedTripPayload(submission)
        
        // Optional enum / minLength fields MUST be omitted when nil/blank to satisfy backend AJV schema
        XCTAssertNil(payload["budget"], "Nil budget must be omitted instead of sending empty string")
        XCTAssertNil(payload["departureLocation"], "Whitespace departureLocation must be omitted")
        XCTAssertNil(payload["flightClass"], "Nil flightClass must be omitted")
        XCTAssertNil(payload["tripDuration"], "Nil tripDuration must be omitted")
        
        // Required and boolean preference fields must be accurately populated
        XCTAssertEqual(payload["destinations"] as? [String], ["Madison, WI"])
        XCTAssertEqual(payload["startDate"] as? String, "2026-11-15")
        XCTAssertEqual(payload["endDate"] as? String, "2026-11-18")
        XCTAssertEqual(payload["travelStyle"] as? String, "Comfortable")
        XCTAssertEqual(payload["groupSize"] as? Int, 2)
        XCTAssertEqual(payload["petFriendly"] as? Bool, true)
        XCTAssertEqual(payload["optInEmailNotifications"] as? Bool, false)
        XCTAssertTrue(JSONSerialization.isValidJSONObject(payload))
    }
    
    func testBuildEnhancedTripPayloadIncludesValidOptionalFields() {
        let submission = EnhancedTripSubmission(
            destinations: ["Paris", "Amsterdam"],
            departureLocation: "  New York (JFK)  ",
            startDate: "2026-05-12",
            endDate: "2026-05-20",
            flexibleDates: true,
            tripDuration: 8,
            budget: "Luxury",
            travelStyle: "Luxury",
            groupSize: 2,
            petFriendly: false,
            optInEmailNotifications: true,
            specialRequests: "Business class on points",
            interests: ["Culture", "Food"],
            flightClass: "Business"
        )
        
        let payload = TripService.buildEnhancedTripPayload(submission)
        
        XCTAssertEqual(payload["departureLocation"] as? String, "New York (JFK)")
        XCTAssertEqual(payload["budget"] as? String, "Luxury")
        XCTAssertEqual(payload["flightClass"] as? String, "Business")
        XCTAssertEqual(payload["tripDuration"] as? Int, 8)
        XCTAssertEqual(payload["flexibleDates"] as? Bool, true)
        XCTAssertEqual(payload["petFriendly"] as? Bool, false)
        XCTAssertEqual(payload["optInEmailNotifications"] as? Bool, true)
        XCTAssertTrue(JSONSerialization.isValidJSONObject(payload))
    }
    
    func testBuildEnhancedTripPayloadOmitsEmptyBudgetString() {
        let submission = EnhancedTripSubmission(
            destinations: ["Tokyo"],
            departureLocation: "SFO",
            startDate: "2026-09-01",
            endDate: "2026-09-10",
            flexibleDates: false,
            budget: "",
            travelStyle: "Adventure",
            groupSize: 1,
            specialRequests: "",
            interests: []
        )
        
        let payload = TripService.buildEnhancedTripPayload(submission)
        XCTAssertNil(payload["budget"], "Empty budget string must be omitted to prevent backend 400 enum failure")
    }
    
    // MARK: - 3. TripDataParser End-to-End Firestore Parsing & Sanitization
    
    func testTripDataParserParsesRichCopilotRecommendationWithPointsOnlyHotel() throws {
        let now = Timestamp(date: Date())
        let start = Timestamp(date: Date().addingTimeInterval(86400 * 10))
        let end = Timestamp(date: Date().addingTimeInterval(86400 * 13))
        
        let firestoreDoc: [String: Any] = [
            "id": "trip_madison_001",
            "userId": "user_abc",
            "destinations": ["Madison, WI"],
            "departureLocation": "Chicago, IL",
            "startDate": start,
            "endDate": end,
            "flexibleDates": false,
            "status": "completed",
            "createdAt": now,
            "updatedAt": now,
            "budget": "Comfortable",
            "travelStyle": "Relaxation",
            "groupSize": 2,
            "interests": ["Food"],
            "specialRequests": "Driveable trip",
            "destinationRecommendation": [
                "id": "trip_madison_001",
                "tripOverview": "Walkable downtown Madison getaway on Hyatt points.",
                "costNotes": "Transfer 36,000 Chase UR 1:1 to World of Hyatt.",
                "destinations": [
                    [
                        "id": "dest_1",
                        "cityName": "Madison, WI",
                        "arrivalDate": "2026-11-15",
                        "departureDate": "2026-11-18",
                        "numberOfNights": 3,
                        "overview": "Stay near Capitol Square",
                        "accommodationOptions": [
                            [
                                "id": "acc_1",
                                "priority": 1,
                                "bookingInstructions": "Book 3 nights via hyatt.com for 12k pts/night",
                                "hotel": [
                                    "name": "Hyatt Place Madison / Downtown",
                                    "rating": 4.5,
                                    "pricePerNight": 0.0,
                                    "pointsPerNight": 12000,
                                    "loyaltyProgram": "World of Hyatt",
                                    "location": "333 W Washington Ave, Madison, WI 53703",
                                    "bookingUrl": "https://www.hyatt.com",
                                    "detailedDescription": "Walkable downtown hotel near Capitol Square."
                                ]
                            ]
                        ],
                        "recommendedActivities": [
                            [
                                "id": "act_1",
                                "name": "Wisconsin State Capitol",
                                "description": "Free dome tours and observation deck.",
                                "category": "Culture",
                                "estimatedCost": 0.0,
                                "bookingRequired": false
                            ]
                        ],
                        "recommendedRestaurants": [
                            [
                                "id": "rest_1",
                                "name": "The Old Fashioned",
                                "cuisine": "Wisconsin Tavern",
                                "priceRange": "$$",
                                "description": "Famous cheese curds and brandy old fashioneds."
                            ]
                        ]
                    ]
                ],
                "logistics": [
                    "generalInstructions": "Driveable trip; no flights needed.",
                    "transportSegments": [
                        [
                            "id": "seg_1",
                            "fromCity": "New York (JFK)",
                            "toCity": "Paris (CDG)",
                            "departureDate": "2026-05-12",
                            "segmentType": "outbound",
                            "linkedSegmentId": NSNull(),
                            "transportOptions": [
                                [
                                    "id": "opt_1",
                                    "transportType": "flight",
                                    "priority": 1,
                                    "duration": "7h 15m",
                                    "cost": [
                                        "paymentType": "points",
                                        "cashAmount": 210.0,
                                        "pointsAmount": 50000,
                                        "pointsProgram": "Flying Blue"
                                    ],
                                    "details": [
                                        "flightNumber": "AF 11",
                                        "airline": "Air France",
                                        "details": [
                                            "departure": ["airportCode": "JFK", "time": "19:30"],
                                            "arrival": ["airportCode": "CDG", "time": "08:45"],
                                            "route": "Direct",
                                            "showDateChange": "+1 day"
                                        ]
                                    ]
                                ]
                            ]
                        ]
                    ]
                ],
                "totalCost": [
                    "totalEstimate": 210.0,
                    "flights": 210.0,
                    "accommodation": 0.0,
                    "activities": 0.0,
                    "food": 0.0,
                    "localTransport": 0.0,
                    "miscellaneous": 0.0,
                    "currency": "USD",
                    "pointsUsed": [
                        "World of Hyatt": 36000,
                        "Flying Blue": 50000
                    ]
                ]
            ] as [String: Any]
        ]
        
        let trip = try TripDataParser.parseTrip(from: firestoreDoc)
        
        XCTAssertEqual(trip.id, "trip_madison_001")
        XCTAssertEqual(trip.status, .completed)
        let rec = try XCTUnwrap(trip.destinationRecommendation)
        XCTAssertEqual(rec.costNotes, "Transfer 36,000 Chase UR 1:1 to World of Hyatt.")
        XCTAssertEqual(rec.destinations.count, 1)
        
        let hotel = try XCTUnwrap(rec.destinations.first?.accommodationOptions.first?.hotel)
        XCTAssertEqual(hotel.name, "Hyatt Place Madison / Downtown")
        XCTAssertEqual(hotel.pricePerNight, 0.0)
        XCTAssertEqual(hotel.pointsPerNight, 12000)
        XCTAssertEqual(hotel.loyaltyProgram, "World of Hyatt")
        
        let flightDetails = rec.logistics.transportSegments.first?.transportOptions.first?.details
        XCTAssertEqual(flightDetails?.details.departure.airportCode, "JFK")
        XCTAssertEqual(flightDetails?.details.arrival.airportCode, "CDG")
        XCTAssertEqual(flightDetails?.details.showDateChange, true)
        XCTAssertEqual(flightDetails?.details.dateChangeText, "+1 day")
        
        XCTAssertEqual(rec.totalCost.pointsUsed?["World of Hyatt"], 36000)
        XCTAssertEqual(rec.totalCost.pointsUsed?["Flying Blue"], 50000)
    }
    
    func testTripDataParserSanitizesNaNAndInfinityWithoutCrashing() throws {
        let now = Timestamp(date: Date())
        let start = Timestamp(date: Date().addingTimeInterval(86400))
        let end = Timestamp(date: Date().addingTimeInterval(86400 * 4))
        
        let docWithNaN: [String: Any] = [
            "id": "trip_nan_test",
            "userId": "user_nan",
            "destinations": ["Rome"],
            "startDate": start,
            "endDate": end,
            "status": "completed",
            "createdAt": now,
            "destinationRecommendation": [
                "id": "trip_nan_test",
                "tripOverview": "Rome trip",
                "destinations": [
                    [
                        "id": "d1",
                        "cityName": "Rome",
                        "arrivalDate": "2026-06-01",
                        "departureDate": "2026-06-04",
                        "numberOfNights": 3,
                        "accommodationOptions": [
                            [
                                "id": "a1",
                                "priority": 1,
                                "hotel": [
                                    "name": "Hotel Artemide",
                                    "rating": Double.nan,
                                    "pricePerNight": Double.infinity,
                                    "location": "Via Nazionale, Rome",
                                    "bookingUrl": "",
                                    "detailedDescription": "Great central stay"
                                ]
                            ]
                        ]
                    ]
                ],
                "logistics": ["transportSegments": []],
                "totalCost": [
                    "totalEstimate": "NaN",
                    "flights": 0.0,
                    "accommodation": 0.0,
                    "activities": 0.0,
                    "food": 0.0,
                    "localTransport": 0.0,
                    "miscellaneous": 0.0,
                    "currency": "USD"
                ]
            ] as [String: Any]
        ]
        
        let trip = try TripDataParser.parseTrip(from: docWithNaN)
        let rec = try XCTUnwrap(trip.destinationRecommendation)
        XCTAssertEqual(rec.id, "trip_nan_test", "String IDs containing substring 'nan' must not be corrupted into 0.0")
        XCTAssertEqual(rec.destinations.first?.cityName, "Rome")
        XCTAssertEqual(rec.destinations.first?.accommodationOptions.first?.hotel.pricePerNight, 0.0)
        XCTAssertEqual(rec.totalCost.totalEstimate, 0.0)
    }
    
    func testTripDataParserPreservesCityNamesContainingNanSubstring() throws {
        let now = Timestamp(date: Date())
        let start = Timestamp(date: Date().addingTimeInterval(86400))
        let end = Timestamp(date: Date().addingTimeInterval(86400 * 4))
        
        let doc: [String: Any] = [
            "id": "trip_nantucket",
            "userId": "user_1",
            "destinations": ["Nantucket, MA"],
            "startDate": start,
            "endDate": end,
            "status": "completed",
            "createdAt": now,
            "destinationRecommendation": [
                "id": "trip_nantucket",
                "tripOverview": "Weekend in Nantucket with great financial value on points",
                "destinations": [
                    [
                        "id": "d_nantucket",
                        "cityName": "Nantucket, MA",
                        "arrivalDate": "2026-07-10",
                        "departureDate": "2026-07-13",
                        "numberOfNights": 3,
                        "accommodationOptions": []
                    ]
                ],
                "logistics": ["transportSegments": []],
                "totalCost": [
                    "totalEstimate": 0.0,
                    "flights": 0.0,
                    "accommodation": 0.0,
                    "activities": 0.0,
                    "food": 0.0,
                    "localTransport": 0.0,
                    "miscellaneous": 0.0,
                    "currency": "USD"
                ]
            ] as [String: Any]
        ]
        
        let trip = try TripDataParser.parseTrip(from: doc)
        let rec = try XCTUnwrap(trip.destinationRecommendation)
        XCTAssertEqual(rec.destinations.first?.cityName, "Nantucket, MA")
        XCTAssertTrue(rec.tripOverview.contains("Nantucket"))
    }
    
    func testTripDataParserRejectsMissingRequiredFields() {
        let now = Timestamp(date: Date())
        
        // Missing destinations
        XCTAssertThrowsError(try TripDataParser.parseTrip(from: [
            "id": "t1",
            "userId": "u1",
            "startDate": now,
            "endDate": now,
            "status": "pending",
            "createdAt": now
        ]))
        
        // Invalid status
        XCTAssertThrowsError(try TripDataParser.parseTrip(from: [
            "id": "t1",
            "userId": "u1",
            "destinations": ["Paris"],
            "startDate": now,
            "endDate": now,
            "status": "unknown_status",
            "createdAt": now
        ]))
    }
    
    // MARK: - 4. Production Configuration & Security Invariants
    
    func testAppConfigAPIEndpointsUseHTTPS() {
        XCTAssertTrue(AppConfig.API.baseURL.hasPrefix("https://"), "API base URL must use HTTPS")
        XCTAssertTrue(AppConfig.API.Endpoints.submitTrip.hasPrefix("https://"), "submitTrip endpoint must use HTTPS")
        XCTAssertNotNil(URL(string: AppConfig.API.Endpoints.submitTrip))
        XCTAssertTrue(AppConfig.API.Endpoints.deleteUserAccount.hasPrefix("https://"), "deleteUserAccount endpoint must use HTTPS")
        XCTAssertNotNil(URL(string: AppConfig.API.Endpoints.deleteUserAccount))
    }
    
    func testAppConfigLegalAndSupportLinksAreLive() {
        XCTAssertTrue(AppConfig.Support.privacyPolicyURL.hasPrefix("https://"))
        XCTAssertTrue(AppConfig.Support.termsOfServiceURL.hasPrefix("https://"))
        XCTAssertFalse(AppConfig.Support.privacyPolicyURL.contains("wandermint.app"), "Privacy Policy URL must point to live hosted page")
        XCTAssertFalse(AppConfig.Support.termsOfServiceURL.contains("wandermint.app"), "Terms URL must point to live hosted page")
        XCTAssertNotNil(URL(string: AppConfig.Support.privacyPolicyURL))
        XCTAssertNotNil(URL(string: AppConfig.Support.termsOfServiceURL))
        XCTAssertFalse(AppConfig.Support.email.contains("wandermint.app"), "Support email must be a monitored address")
        XCTAssertEqual(AppConfig.Limits.maxTripsPerDay, 10, "Client trip limit must match backend rate limit")
        XCTAssertNotEqual(AppConfig.App.appStoreId, "0000000000", "Dummy placeholder App Store ID must not ship")
    }
    
    func testInfoPlistAppStoreComplianceHygiene() {
        let info = Bundle.main.infoDictionary ?? [:]
        
        // Must not declare armv7 (rejected on modern iOS)
        let capabilities = info["UIRequiredDeviceCapabilities"] as? [String] ?? []
        XCTAssertFalse(capabilities.contains("armv7"), "armv7 must not be in UIRequiredDeviceCapabilities")
        
        // Must not reference unused sensitive permission descriptions
        let forbiddenPrivacyKeys = [
            "NSLocationWhenInUseUsageDescription",
            "NSLocationAlwaysAndWhenInUseUsageDescription",
            "NSCameraUsageDescription",
            "NSPhotoLibraryUsageDescription",
            "NSContactsUsageDescription",
            "NSCalendarsUsageDescription",
            "NSAppleMusicUsageDescription"
        ]
        for key in forbiddenPrivacyKeys {
            XCTAssertNil(info[key], "Unused privacy key \(key) should not be present in Info.plist")
        }
        
        // Must not reference phantom SceneDelegate inside UIApplicationSceneManifest
        let sceneManifest = info["UIApplicationSceneManifest"] as? [String: Any]
        XCTAssertNil(sceneManifest?["UISceneConfigurations"], "SwiftUI App lifecycle should not declare a phantom UISceneConfigurations SceneDelegate")
    }
    
    func testSafeExternalURLBlocksNonHttpSchemesAndMalformedURLs() {
        XCTAssertNotNil(AppConfig.safeExternalURL(from: "https://www.hyatt.com/hotels"))
        XCTAssertNotNil(AppConfig.safeExternalURL(from: "http://example.com/booking"))
        XCTAssertNil(AppConfig.safeExternalURL(from: "javascript:alert(1)"))
        XCTAssertNil(AppConfig.safeExternalURL(from: "tel:+15551234567"))
        XCTAssertNil(AppConfig.safeExternalURL(from: "file:///etc/passwd"))
        XCTAssertNil(AppConfig.safeExternalURL(from: "sms:+15551234567"))
        XCTAssertNil(AppConfig.safeExternalURL(from: "not a url"))
        XCTAssertNil(AppConfig.safeExternalURL(from: ""))
        XCTAssertNil(AppConfig.safeExternalURL(from: nil))
    }
    
    func testTripDataValidatorRejectsInvalidDateOrdering() {
        XCTAssertThrowsError(
            try TripDataValidator.validateUserInput(
                destinations: ["Paris"],
                startDate: "2027-06-20",
                endDate: "2027-06-15"
            )
        )
        XCTAssertThrowsError(
            try TripDataValidator.validateUserInput(
                destinations: [],
                startDate: "2027-06-15",
                endDate: "2027-06-20"
            )
        )
        XCTAssertNoThrow(
            try TripDataValidator.validateUserInput(
                destinations: ["Paris"],
                startDate: "2027-06-15",
                endDate: "2027-06-20"
            )
        )
    }
}
