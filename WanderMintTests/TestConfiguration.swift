//
//  TestConfiguration.swift
//  WanderMintTests
//
//  Created by Claude Code on 7/10/25.
//

import Foundation
import Firebase
@testable import WanderMint

// MARK: - Test Models

struct Trip {
    let id: String
    let title: String
    let description: String
    let destination: String
    let startDate: Date
    let endDate: Date
    let userId: String
    let status: TripStatus
    let createdAt: Date
    let updatedAt: Date
}

enum TripStatus {
    case planning
    case confirmed
    case inProgress
    case completed
    case cancelled
}

struct PointsTransaction {
    let id: String
    let userId: String
    let type: PointsTransactionType
    let amount: Int
    let description: String
    let provider: String
    let date: Date
    let category: PointsCategory
}

enum PointsTransactionType {
    case earned
    case redeemed
    case transferred
}

enum PointsCategory {
    case creditCard
    case hotel
    case airline
}

// MARK: - Mock Firebase User

class MockFirebaseUser {
    let uid: String
    let email: String?
    let displayName: String?
    
    init(uid: String, email: String?, displayName: String?) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
    }
    
    func getIDToken() async throws -> String {
        return "mock-id-token"
    }
}

/// Configuration and utilities for testing WanderMint
class TestConfiguration {
    
    static let shared = TestConfiguration()
    
    private init() {}
    
    /// Configure Firebase for testing
    static func configureFirebaseForTesting() {
        // Only configure if not already configured
        guard FirebaseApp.app() == nil else { return }
        
        // Use a test Firebase configuration
        let options = FirebaseOptions(googleAppID: "test-app-id", gcmSenderID: "test-sender-id")
        options.projectID = "wandermint-test"
        options.apiKey = "test-api-key"
        
        FirebaseApp.configure(options: options)
    }
    
    /// Create a mock user for testing
    static func createMockUser(
        uid: String = "test-uid-\(UUID().uuidString)",
        email: String = "test@wandermint.com",
        displayName: String = "Test User"
    ) -> MockFirebaseUser {
        return MockFirebaseUser(uid: uid, email: email, displayName: displayName)
    }
    
    /// Create a test trip
    static func createTestTrip(
        id: String = "test-trip-\(UUID().uuidString)",
        userId: String = "test-user",
        title: String = "Test Trip",
        destination: String = "Test Destination"
    ) -> TravelTrip {
        return TravelTrip(
            id: id,
            userId: userId,
            destination: destination,
            destinations: [destination],
            departureLocation: "Test Departure",
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
    }
    
    /// Create a test user profile
    static func createTestUserProfile(
        userId: String = "test-user",
        onboardingCompleted: Bool = false
    ) -> UserProfile {
        return UserProfile(
            userId: userId,
            name: "Test User",
            email: "test@wandermint.com",
            createdAt: Timestamp(),
            lastLoginAt: Timestamp(),
            profilePictureUrl: nil,
            onboardingCompleted: onboardingCompleted,
            onboardingCompletedAt: onboardingCompleted ? Timestamp() : nil
        )
    }
    
    /// Create test points profile
    static func createTestPointsProfile(
        userId: String = "test-user"
    ) -> UserPointsProfile {
        return UserPointsProfile(
            userId: userId,
            creditCardPoints: [
                "Test Chase": 50000,
                "Test Amex": 25000
            ],
            hotelPoints: [
                "Test Marriott": 100000,
                "Test Hilton": 75000
            ],
            airlinePoints: [
                "Test United": 60000,
                "Test Delta": 40000
            ],
            lastUpdated: Timestamp()
        )
    }
}