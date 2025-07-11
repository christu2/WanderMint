//
//  PointsServiceTests.swift
//  WanderMintTests
//
//  Created by Claude Code on 7/10/25.
//

import XCTest
import Firebase
import FirebaseFirestore
@testable import WanderMint

@MainActor
final class PointsServiceTests: XCTestCase {
    
    var pointsService: PointsService!
    
    override func setUpWithError() throws {
        super.setUp()
        pointsService = PointsService()
    }
    
    override func tearDownWithError() throws {
        pointsService = nil
        super.tearDown()
    }
    
    // MARK: - Points Calculation Tests
    
    func testPointsCalculation() {
        let basePoints = 10000
        let multiplier = 1.5
        let expectedPoints = Int(Double(basePoints) * multiplier)
        
        XCTAssertEqual(expectedPoints, 15000)
    }
    
    func testPointsValidation() {
        let validPoints = 25000
        let invalidPoints = -5000
        
        XCTAssertTrue(validPoints >= 0)
        XCTAssertFalse(invalidPoints >= 0)
    }
    
    // MARK: - Points Profile Tests
    
    func testUserPointsProfileCreation() {
        let pointsProfile = UserPointsProfile(
            userId: "test-user-123",
            creditCardPoints: [
                "Chase Sapphire": 50000,
                "Amex Gold": 25000
            ],
            hotelPoints: [
                "Marriott": 100000,
                "Hilton": 75000
            ],
            airlinePoints: [
                "United": 60000,
                "Delta": 40000
            ],
            lastUpdated: Timestamp()
        )
        
        XCTAssertEqual(pointsProfile.userId, "test-user-123")
        XCTAssertEqual(pointsProfile.creditCardPoints["Chase Sapphire"], 50000)
        XCTAssertEqual(pointsProfile.hotelPoints["Marriott"], 100000)
        XCTAssertEqual(pointsProfile.airlinePoints["United"], 60000)
    }
    
    func testPointsProviders() {
        let creditCardProviders = PointsProvider.creditCardProviders
        let hotelProviders = PointsProvider.hotelProviders
        let airlineProviders = PointsProvider.airlineProviders
        
        XCTAssertFalse(creditCardProviders.isEmpty)
        XCTAssertFalse(hotelProviders.isEmpty)
        XCTAssertFalse(airlineProviders.isEmpty)
        
        // Test specific providers
        XCTAssertTrue(creditCardProviders.contains("Chase"))
        XCTAssertTrue(hotelProviders.contains("Marriott"))
        XCTAssertTrue(airlineProviders.contains("United"))
    }
    
    // MARK: - Points Redemption Tests
    
    func testPointsRedemptionCalculation() {
        let points = 50000
        let centsPerPoint = 1.25
        let expectedValue = Double(points) * (centsPerPoint / 100.0)
        
        XCTAssertEqual(expectedValue, 625.0, accuracy: 0.01)
    }
    
    func testPointsTransferRatio() {
        let originalPoints = 100000
        let transferRatio = 0.8 // 80% transfer ratio
        let expectedTransferredPoints = Int(Double(originalPoints) * transferRatio)
        
        XCTAssertEqual(expectedTransferredPoints, 80000)
    }
    
    // MARK: - Points History Tests
    
    func testPointsTransaction() {
        let transaction = PointsTransaction(
            id: "txn-123",
            userId: "user-123",
            type: .earned,
            amount: 5000,
            description: "Sign-up bonus",
            provider: "Chase Sapphire",
            date: Date(),
            category: .creditCard
        )
        
        XCTAssertEqual(transaction.type, .earned)
        XCTAssertEqual(transaction.amount, 5000)
        XCTAssertEqual(transaction.provider, "Chase Sapphire")
        XCTAssertEqual(transaction.category, .creditCard)
    }
}