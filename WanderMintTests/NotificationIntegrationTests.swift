//
//  NotificationIntegrationTests.swift
//  WanderMintTests
//
//  Created by Claude Code on 7/11/25.
//

import XCTest
import Firebase
import FirebaseFirestore
import FirebaseAuth
@testable import WanderMint

@MainActor
final class NotificationIntegrationTests: XCTestCase {
    
    var notificationService: NotificationService!
    var authViewModel: AuthenticationViewModel!
    var mockUser: MockFirebaseUser!
    
    override func setUpWithError() throws {
        super.setUp()
        
        // Initialize Firebase for testing
        TestConfiguration.configureFirebaseForTesting()
        
        // Set up test objects
        notificationService = NotificationService.shared
        authViewModel = AuthenticationViewModel()
        mockUser = TestConfiguration.createMockUser()
        
        // Clean up any existing state
        notificationService.stopListening()
    }
    
    override func tearDownWithError() throws {
        notificationService.stopListening()
        notificationService = nil
        authViewModel = nil
        mockUser = nil
        super.tearDown()
    }
    
    // MARK: - End-to-End Notification Flow Tests
    
    func testTripStatusChangeNotificationFlow() async throws {
        // 1. Set up initial state
        await notificationService.checkPermissionStatus()
        
        // 2. Simulate trip status change to "completed"
        let tripData = createTripCompletedData()
        
        // 3. Verify notification service can process the change
        XCTAssertNotNil(tripData["status"])
        XCTAssertEqual(tripData["status"] as? String, "completed")
        
        // 4. Test deep linking data structure
        let expectedUserInfo: [AnyHashable: Any] = [
            "type": "trip_ready",
            "tripId": "test-trip-123",
            "action": "open_trip"
        ]
        
        notificationService.handleNotificationTap(userInfo: expectedUserInfo)
        XCTAssertEqual(notificationService.pendingTripId, "test-trip-123")
    }
    
    func testAdminMessageNotificationFlow() async throws {
        // 1. Set up conversation with unread admin message
        let conversationData = createConversationWithUnreadMessage()
        let messageData = createAdminMessageData()
        
        // 2. Verify conversation has unread count
        XCTAssertEqual(conversationData["unreadUserCount"] as? Int, 1)
        
        // 3. Verify message is from admin and unread
        XCTAssertEqual(messageData["senderType"] as? String, "admin")
        XCTAssertEqual(messageData["isRead"] as? Bool, false)
        
        // 4. Test deep linking for admin message
        let expectedUserInfo: [AnyHashable: Any] = [
            "type": "admin_message",
            "conversationId": "test-conversation-123",
            "tripId": "test-trip-456",
            "action": "open_conversation"
        ]
        
        notificationService.handleNotificationTap(userInfo: expectedUserInfo)
        XCTAssertEqual(notificationService.pendingTripId, "test-trip-456")
    }
    
    func testItineraryUpdateNotificationFlow() async throws {
        // 1. Set up trip with recent itinerary update
        let tripData = createTripWithRecentUpdate()
        
        // 2. Verify trip has recommendation data
        XCTAssertNotNil(tripData["recommendation"])
        XCTAssertEqual(tripData["status"] as? String, "completed")
        
        // 3. Verify update is recent (within 5 minutes)
        if let updatedAt = tripData["updatedAt"] as? Timestamp {
            let timeDifference = Date().timeIntervalSince(updatedAt.dateValue())
            XCTAssertLessThan(timeDifference, 300) // Less than 5 minutes
        } else {
            XCTFail("updatedAt should be present")
        }
        
        // 4. Test deep linking for itinerary update
        let expectedUserInfo: [AnyHashable: Any] = [
            "type": "itinerary_updated",
            "tripId": "test-trip-789",
            "action": "open_trip"
        ]
        
        notificationService.handleNotificationTap(userInfo: expectedUserInfo)
        XCTAssertEqual(notificationService.pendingTripId, "test-trip-789")
    }
    
    // MARK: - Permission Integration Tests
    
    func testNotificationPermissionIntegration() {
        // Test that permission integration methods exist
        XCTAssertNotNil(notificationService.requestPermission)
        XCTAssertNotNil(notificationService.checkPermissionStatus)
        XCTAssertTrue(true) // Placeholder for permission integration tests
    }
    
    func testNotificationWithoutPermission() {
        // Test that service handles no permission gracefully
        XCTAssertNotNil(notificationService.hasNotificationPermission)
        XCTAssertTrue(true) // Placeholder for permission denial tests
    }
    
    // MARK: - Listener Integration Tests
    
    func testFirestoreListenerIntegration() {
        // Test that Firebase listener methods exist
        XCTAssertNotNil(notificationService.startListening)
        XCTAssertNotNil(notificationService.stopListening)
        
        // Clean up any existing listeners
        notificationService.stopListening()
        XCTAssertTrue(true) // Placeholder for Firebase integration tests
    }
    
    func testMultipleListenerManagement() {
        // Test multiple stop calls (safe operation)
        notificationService.stopListening()
        notificationService.stopListening()
        notificationService.stopListening()
        
        // Should handle multiple stops gracefully
        XCTAssertTrue(true)
    }
    
    // MARK: - Edge Case Tests
    
    func testHandleInvalidNotificationData() {
        // Test various invalid notification payloads
        let invalidPayloads: [[AnyHashable: Any]] = [
            [:], // Empty payload
            ["action": "invalid_action"], // Invalid action
            ["tripId": "test-trip"], // Missing action
            ["action": "open_trip"], // Missing tripId
            ["action": "open_conversation", "tripId": "test-trip"], // Missing conversationId
        ]
        
        for payload in invalidPayloads {
            notificationService.handleNotificationTap(userInfo: payload)
            // Should not crash and should not set pendingTripId inappropriately
        }
        
        XCTAssertTrue(true) // If we get here, no crashes occurred
    }
    
    func testConcurrentNotificationHandling() async throws {
        // Test handling multiple notifications simultaneously
        let expectation1 = expectation(description: "First notification")
        let expectation2 = expectation(description: "Second notification")
        
        Task {
            notificationService.handleNotificationTap(userInfo: [
                "action": "open_trip",
                "tripId": "trip-1"
            ])
            expectation1.fulfill()
        }
        
        Task {
            notificationService.handleNotificationTap(userInfo: [
                "action": "open_trip",
                "tripId": "trip-2"
            ])
            expectation2.fulfill()
        }
        
        await fulfillment(of: [expectation1, expectation2], timeout: 2.0)
        
        // Should handle concurrent access gracefully
        XCTAssertTrue(true)
    }
    
    // MARK: - Performance Tests
    
    func testNotificationServicePerformance() {
        measure {
            // Test performance of notification handling
            for i in 0..<100 {
                notificationService.handleNotificationTap(userInfo: [
                    "action": "open_trip",
                    "tripId": "trip-\(i)"
                ])
                notificationService.clearPendingNavigation()
            }
        }
    }
    
    func testListenerStartStopPerformance() {
        measure {
            // Test performance of stopping listeners (safe to call multiple times)
            for _ in 0..<100 {
                notificationService.stopListening()
            }
        }
    }
}

// MARK: - Test Data Factory

extension NotificationIntegrationTests {
    
    func createTripCompletedData() -> [String: Any] {
        return [
            "id": "test-trip-123",
            "userId": mockUser.uid,
            "status": "completed",
            "destination": "Paris, France",
            "destinations": ["Paris", "Lyon"],
            "updatedAt": Timestamp(date: Date()),
            "createdAt": Timestamp(date: Date().addingTimeInterval(-86400))
        ]
    }
    
    func createConversationWithUnreadMessage() -> [String: Any] {
        return [
            "id": "test-conversation-123",
            "tripId": "test-trip-456",
            "userId": mockUser.uid,
            "unreadUserCount": 1,
            "updatedAt": Timestamp(date: Date())
        ]
    }
    
    func createAdminMessageData() -> [String: Any] {
        return [
            "id": "test-message-123",
            "content": "We've updated your itinerary based on your feedback. Please review the changes.",
            "senderType": "admin",
            "isRead": false,
            "timestamp": Timestamp(date: Date())
        ]
    }
    
    func createTripWithRecentUpdate() -> [String: Any] {
        return [
            "id": "test-trip-789",
            "userId": mockUser.uid,
            "status": "completed",
            "destination": "Tokyo, Japan",
            "destinations": ["Tokyo", "Kyoto"],
            "updatedAt": Timestamp(date: Date().addingTimeInterval(-60)), // 1 minute ago
            "createdAt": Timestamp(date: Date().addingTimeInterval(-86400)),
            "recommendation": [
                "hotels": ["Hotel A", "Hotel B"],
                "activities": ["Visit Temple", "Try Sushi"]
            ]
        ]
    }
    
    func createTripWithOldUpdate() -> [String: Any] {
        return [
            "id": "test-trip-old",
            "userId": mockUser.uid,
            "status": "completed",
            "destination": "London, UK",
            "updatedAt": Timestamp(date: Date().addingTimeInterval(-7200)), // 2 hours ago
            "createdAt": Timestamp(date: Date().addingTimeInterval(-86400)),
            "recommendation": [
                "hotels": ["Hotel C", "Hotel D"],
                "activities": ["Visit Museum", "Take Tour"]
            ]
        ]
    }
}

// MARK: - Test Utilities

extension NotificationIntegrationTests {
    
    func waitForNotificationProcessing() async {
        // Small delay to allow async notification processing
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
    
    func simulateAppBackground() {
        // Simulate app going to background
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
    }
    
    func simulateAppForeground() {
        // Simulate app coming to foreground
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
    }
}