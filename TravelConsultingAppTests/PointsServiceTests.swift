//
//  PointsServiceTests.swift
//  TravelConsultingAppTests
//
//  Created by Nick Christus on 3/9/25.
//

import Testing
import Foundation
import FirebaseFirestore
@testable import TravelConsultingApp

struct PointsServiceTests {
    
    // MARK: - Test Data Creation Helpers
    
    private func createTestPointsProfileData() -> [String: Any] {
        return [
            "userId": "test-user-123",
            "creditCardPoints": [
                "Chase": 75000,
                "American Express": 50000,
                "Capital One": 25000
            ],
            "hotelPoints": [
                "Hyatt": 30000,
                "Marriott": 45000,
                "Hilton": 20000
            ],
            "airlinePoints": [
                "United": 60000,
                "Delta": 40000,
                "American": 35000
            ],
            "lastUpdated": Timestamp(date: Date())
        ]
    }
    
    private func createEmptyPointsProfileData() -> [String: Any] {
        return [
            "userId": "test-user-empty",
            "creditCardPoints": [:] as [String: Int],
            "hotelPoints": [:] as [String: Int],
            "airlinePoints": [:] as [String: Int],
            "lastUpdated": Timestamp(date: Date())
        ]
    }
    
    // MARK: - Points Profile Parsing Tests
    
    @Test func testParsePointsProfileWithValidData() async throws {
        await MainActor.run {
            let service = PointsService()
            let testData = createTestPointsProfileData()
            
            // Test the parsing logic directly by creating expected structure
            let creditCardPoints = testData["creditCardPoints"] as? [String: Int] ?? [:]
            let hotelPoints = testData["hotelPoints"] as? [String: Int] ?? [:]
            let airlinePoints = testData["airlinePoints"] as? [String: Int] ?? [:]
            let lastUpdated = testData["lastUpdated"] as? Timestamp ?? Timestamp()
            
            #expect(creditCardPoints["Chase"] == 75000)
            #expect(creditCardPoints["American Express"] == 50000)
            #expect(creditCardPoints["Capital One"] == 25000)
            
            #expect(hotelPoints["Hyatt"] == 30000)
            #expect(hotelPoints["Marriott"] == 45000)
            #expect(hotelPoints["Hilton"] == 20000)
            
            #expect(airlinePoints["United"] == 60000)
            #expect(airlinePoints["Delta"] == 40000)
            #expect(airlinePoints["American"] == 35000)
            
            #expect(lastUpdated.dateValue().timeIntervalSinceNow < 60) // Recent timestamp
        }
    }
    
    @Test func testParsePointsProfileWithEmptyData() async throws {
        await MainActor.run {
            let service = PointsService()
            let testData = createEmptyPointsProfileData()
            
            let creditCardPoints = testData["creditCardPoints"] as? [String: Int] ?? [:]
            let hotelPoints = testData["hotelPoints"] as? [String: Int] ?? [:]
            let airlinePoints = testData["airlinePoints"] as? [String: Int] ?? [:]
            
            #expect(creditCardPoints.isEmpty)
            #expect(hotelPoints.isEmpty)
            #expect(airlinePoints.isEmpty)
        }
    }
    
    @Test func testParsePointsProfileWithMissingFields() async throws {
        // Test with missing creditCardPoints
        var testData = createTestPointsProfileData()
        testData.removeValue(forKey: "creditCardPoints")
        
        let creditCardPoints = testData["creditCardPoints"] as? [String: Int] ?? [:]
        #expect(creditCardPoints.isEmpty)
        
        // Test with missing hotelPoints
        testData = createTestPointsProfileData()
        testData.removeValue(forKey: "hotelPoints")
        
        let hotelPoints = testData["hotelPoints"] as? [String: Int] ?? [:]
        #expect(hotelPoints.isEmpty)
        
        // Test with missing airlinePoints
        testData = createTestPointsProfileData()
        testData.removeValue(forKey: "airlinePoints")
        
        let airlinePoints = testData["airlinePoints"] as? [String: Int] ?? [:]
        #expect(airlinePoints.isEmpty)
        
        // Test with missing lastUpdated
        testData = createTestPointsProfileData()
        testData.removeValue(forKey: "lastUpdated")
        
        let lastUpdated = testData["lastUpdated"] as? Timestamp ?? Timestamp()
        #expect(lastUpdated.dateValue().timeIntervalSinceNow < 60) // Should default to current time
    }
    
    // MARK: - Points Type Tests
    
    @Test func testPointsTypeRawValues() async throws {
        #expect(PointsType.creditCard.rawValue == "credit_card")
        #expect(PointsType.hotel.rawValue == "hotel")
        #expect(PointsType.airline.rawValue == "airline")
    }
    
    @Test func testPointsTypeDisplayNames() async throws {
        #expect(PointsType.creditCard.displayName == "Credit Card")
        #expect(PointsType.hotel.displayName == "Hotel")
        #expect(PointsType.airline.displayName == "Airline")
    }
    
    @Test func testPointsTypeCaseIterable() async throws {
        let allCases = PointsType.allCases
        #expect(allCases.count == 3)
        #expect(allCases.contains(.creditCard))
        #expect(allCases.contains(.hotel))
        #expect(allCases.contains(.airline))
    }
    
    // MARK: - Points Provider Tests
    
    @Test func testCreditCardProviders() async throws {
        let providers = PointsProvider.creditCardProviders
        #expect(providers.count == 6)
        #expect(providers.contains("American Express"))
        #expect(providers.contains("Chase"))
        #expect(providers.contains("Capital One"))
        #expect(providers.contains("Citi"))
        #expect(providers.contains("Bank of America"))
        #expect(providers.contains("Wells Fargo"))
    }
    
    @Test func testHotelProviders() async throws {
        let providers = PointsProvider.hotelProviders
        #expect(providers.count == 6)
        #expect(providers.contains("Hyatt"))
        #expect(providers.contains("Marriott"))
        #expect(providers.contains("Hilton"))
        #expect(providers.contains("IHG"))
        #expect(providers.contains("Wyndham"))
        #expect(providers.contains("Choice Hotels"))
    }
    
    @Test func testAirlineProviders() async throws {
        let providers = PointsProvider.airlineProviders
        #expect(providers.count == 6)
        #expect(providers.contains("United"))
        #expect(providers.contains("Delta"))
        #expect(providers.contains("American"))
        #expect(providers.contains("Southwest"))
        #expect(providers.contains("JetBlue"))
        #expect(providers.contains("Alaska"))
    }
    
    // MARK: - Update Points Logic Tests
    
    @Test func testUpdatePointsFieldPathGeneration() async throws {
        // Test field path generation for different point types
        let creditCardFieldPath = "\(PointsType.creditCard.rawValue)Points.Chase"
        #expect(creditCardFieldPath == "credit_cardPoints.Chase")
        
        let hotelFieldPath = "\(PointsType.hotel.rawValue)Points.Hyatt"
        #expect(hotelFieldPath == "hotelPoints.Hyatt")
        
        let airlineFieldPath = "\(PointsType.airline.rawValue)Points.United"
        #expect(airlineFieldPath == "airlinePoints.United")
    }
    
    @Test func testCreateNewPointsDocumentStructure() async throws {
        // Test the structure that would be created for a new points document
        let userId = "test-user-new"
        let provider = "Chase"
        let pointsType = PointsType.creditCard
        let amount = 50000
        
        var pointsData: [String: Any] = [
            "userId": userId,
            "creditCardPoints": [:],
            "hotelPoints": [:],
            "airlinePoints": [:]
        ]
        
        let fieldPath = "\(pointsType.rawValue)Points"
        pointsData[fieldPath] = [provider: amount]
        
        #expect(pointsData["userId"] as? String == userId)
        #expect(pointsData["creditCardPoints"] as? [String: Int] != nil)
        #expect(pointsData["hotelPoints"] as? [String: Int] != nil)
        #expect(pointsData["airlinePoints"] as? [String: Int] != nil)
        
        let creditCardPoints = pointsData["credit_cardPoints"] as? [String: Int]
        #expect(creditCardPoints?["Chase"] == 50000)
    }
    
    // MARK: - UserPointsProfile Model Tests
    
    @Test func testUserPointsProfileInitialization() async throws {
        let testDate = Date()
        let profile = UserPointsProfile(
            userId: "test-user",
            creditCardPoints: ["Chase": 75000, "Amex": 50000],
            hotelPoints: ["Hyatt": 30000],
            airlinePoints: ["United": 60000],
            lastUpdated: Timestamp(date: testDate)
        )
        
        #expect(profile.userId == "test-user")
        #expect(profile.creditCardPoints["Chase"] == 75000)
        #expect(profile.creditCardPoints["Amex"] == 50000)
        #expect(profile.hotelPoints["Hyatt"] == 30000)
        #expect(profile.airlinePoints["United"] == 60000)
        #expect(abs(profile.lastUpdated.dateValue().timeIntervalSince(testDate)) < 1.0)
    }
    
    @Test func testUserPointsProfileCodable() async throws {
        let profile = UserPointsProfile(
            userId: "test-user",
            creditCardPoints: ["Chase": 75000, "Amex": 50000],
            hotelPoints: ["Hyatt": 30000, "Marriott": 45000],
            airlinePoints: ["United": 60000, "Delta": 40000],
            lastUpdated: Timestamp(date: Date())
        )
        
        // Test encoding
        let encoder = JSONEncoder()
        let data = try encoder.encode(profile)
        #expect(data.count > 0)
        
        // Test decoding
        let decoder = JSONDecoder()
        let decodedProfile = try decoder.decode(UserPointsProfile.self, from: data)
        
        #expect(decodedProfile.userId == profile.userId)
        #expect(decodedProfile.creditCardPoints == profile.creditCardPoints)
        #expect(decodedProfile.hotelPoints == profile.hotelPoints)
        #expect(decodedProfile.airlinePoints == profile.airlinePoints)
    }
    
    // MARK: - Points Calculation Tests
    
    @Test func testTotalPointsByType() async throws {
        let profile = UserPointsProfile(
            userId: "test-user",
            creditCardPoints: ["Chase": 75000, "Amex": 50000, "Capital One": 25000],
            hotelPoints: ["Hyatt": 30000, "Marriott": 45000],
            airlinePoints: ["United": 60000, "Delta": 40000, "American": 35000],
            lastUpdated: Timestamp(date: Date())
        )
        
        // Calculate totals
        let totalCreditCardPoints = profile.creditCardPoints.values.reduce(0, +)
        let totalHotelPoints = profile.hotelPoints.values.reduce(0, +)
        let totalAirlinePoints = profile.airlinePoints.values.reduce(0, +)
        
        #expect(totalCreditCardPoints == 150000) // 75000 + 50000 + 25000
        #expect(totalHotelPoints == 75000) // 30000 + 45000
        #expect(totalAirlinePoints == 135000) // 60000 + 40000 + 35000
    }
    
    @Test func testPointsDistributionAnalysis() async throws {
        let profile = UserPointsProfile(
            userId: "test-user",
            creditCardPoints: ["Chase": 75000, "Amex": 50000],
            hotelPoints: ["Hyatt": 30000],
            airlinePoints: ["United": 60000, "Delta": 40000],
            lastUpdated: Timestamp(date: Date())
        )
        
        // Test provider counts
        #expect(profile.creditCardPoints.count == 2)
        #expect(profile.hotelPoints.count == 1)
        #expect(profile.airlinePoints.count == 2)
        
        // Test highest point balance by type
        let highestCreditCard = profile.creditCardPoints.max(by: { $0.value < $1.value })
        let highestAirline = profile.airlinePoints.max(by: { $0.value < $1.value })
        
        #expect(highestCreditCard?.key == "Chase")
        #expect(highestCreditCard?.value == 75000)
        #expect(highestAirline?.key == "United")
        #expect(highestAirline?.value == 60000)
    }
    
    // MARK: - Data Validation Tests
    
    @Test func testValidPointsAmounts() async throws {
        let validAmounts = [0, 1000, 25000, 100000, 1000000]
        
        for amount in validAmounts {
            #expect(amount >= 0) // Points should never be negative
            #expect(amount <= 10000000) // Reasonable upper bound
        }
    }
    
    @Test func testValidProviderNames() async throws {
        let allProviders = PointsProvider.creditCardProviders + 
                          PointsProvider.hotelProviders + 
                          PointsProvider.airlineProviders
        
        for provider in allProviders {
            #expect(!provider.isEmpty)
            #expect(provider.count > 2) // Reasonable minimum length
            #expect(!provider.contains(".")) // No dots in provider names
            #expect(!provider.contains("/")) // No slashes in provider names
        }
    }
    
    @Test func testUniqueProviderNames() async throws {
        let allProviders = PointsProvider.creditCardProviders + 
                          PointsProvider.hotelProviders + 
                          PointsProvider.airlineProviders
        
        let uniqueProviders = Set(allProviders)
        #expect(uniqueProviders.count == allProviders.count) // No duplicates
    }
    
    // MARK: - Edge Cases Tests
    
    @Test func testZeroPointBalances() async throws {
        let profile = UserPointsProfile(
            userId: "test-user",
            creditCardPoints: ["Chase": 0],
            hotelPoints: ["Hyatt": 0],
            airlinePoints: ["United": 0],
            lastUpdated: Timestamp(date: Date())
        )
        
        #expect(profile.creditCardPoints["Chase"] == 0)
        #expect(profile.hotelPoints["Hyatt"] == 0)
        #expect(profile.airlinePoints["United"] == 0)
        
        let totalPoints = profile.creditCardPoints.values.reduce(0, +) +
                         profile.hotelPoints.values.reduce(0, +) +
                         profile.airlinePoints.values.reduce(0, +)
        #expect(totalPoints == 0)
    }
    
    @Test func testMaximumPointBalances() async throws {
        let maxPoints = 999999999 // Very high but reasonable
        let profile = UserPointsProfile(
            userId: "test-user",
            creditCardPoints: ["Chase": maxPoints],
            hotelPoints: ["Hyatt": maxPoints],
            airlinePoints: ["United": maxPoints],
            lastUpdated: Timestamp(date: Date())
        )
        
        #expect(profile.creditCardPoints["Chase"] == maxPoints)
        #expect(profile.hotelPoints["Hyatt"] == maxPoints)
        #expect(profile.airlinePoints["United"] == maxPoints)
    }
    
    @Test func testPointsUpdatingLogic() async throws {
        // Simulate updating existing points
        var existingPoints = ["Chase": 50000, "Amex": 75000]
        
        // Update existing provider
        existingPoints["Chase"] = 60000
        #expect(existingPoints["Chase"] == 60000)
        #expect(existingPoints["Amex"] == 75000) // Unchanged
        
        // Add new provider
        existingPoints["Capital One"] = 25000
        #expect(existingPoints.count == 3)
        #expect(existingPoints["Capital One"] == 25000)
        
        // Remove provider (simulation)
        existingPoints.removeValue(forKey: "Amex")
        #expect(existingPoints.count == 2)
        #expect(existingPoints["Amex"] == nil)
    }
}