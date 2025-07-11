//
//  NotificationServiceBasicTests.swift
//  WanderMintTests
//
//  Created by Claude Code on 7/11/25.
//

import XCTest
import UserNotifications
import Firebase
import FirebaseFirestore
@testable import WanderMint

@MainActor
final class NotificationServiceBasicTests: XCTestCase {
    
    var notificationService: NotificationService!
    
    override func setUpWithError() throws {
        super.setUp()
        
        // Initialize Firebase if not already initialized
        if FirebaseApp.app() == nil {
            TestConfiguration.configureFirebaseForTesting()
        }
        
        // Get the shared notification service
        notificationService = NotificationService.shared
        
        // Reset state
        notificationService.stopListening()
        notificationService.clearPendingNavigation()
    }
    
    override func tearDownWithError() throws {
        notificationService.stopListening()
        notificationService.clearPendingNavigation()
        super.tearDown()
    }
    
    // MARK: - Basic Functionality Tests
    
    func testNotificationServiceInitialization() throws {
        XCTAssertNotNil(notificationService)
        XCTAssertNil(notificationService.pendingTripId)
    }
    
    func testStartAndStopListening() {
        // Test that listener methods exist and can be called
        // Note: Actual Firebase listeners would require authentication
        // So we just test the methods are available and stopping works
        notificationService.stopListening()
        
        // Should complete without crashing
        XCTAssertTrue(true)
    }
    
    func testPermissionMethods() {
        // Test that permission methods exist and can be called
        // Note: Actual permission requests would show system dialogs
        // So we just test the methods are available
        XCTAssertNotNil(notificationService.requestPermission)
        XCTAssertNotNil(notificationService.checkPermissionStatus)
    }
    
    // MARK: - Deep Linking Tests
    
    func testHandleNotificationTapOpenTrip() {
        let userInfo: [AnyHashable: Any] = [
            "action": "open_trip",
            "tripId": "test-trip-123",
            "type": "trip_ready"
        ]
        
        notificationService.handleNotificationTap(userInfo: userInfo)
        
        XCTAssertEqual(notificationService.pendingTripId, "test-trip-123")
    }
    
    func testHandleNotificationTapOpenConversation() {
        let userInfo: [AnyHashable: Any] = [
            "action": "open_conversation",
            "tripId": "test-trip-456",
            "conversationId": "test-conversation-123",
            "type": "admin_message"
        ]
        
        notificationService.handleNotificationTap(userInfo: userInfo)
        
        XCTAssertEqual(notificationService.pendingTripId, "test-trip-456")
    }
    
    func testHandleNotificationTapInvalidAction() {
        let userInfo: [AnyHashable: Any] = [
            "action": "invalid_action",
            "tripId": "test-trip-789"
        ]
        
        notificationService.handleNotificationTap(userInfo: userInfo)
        
        XCTAssertNil(notificationService.pendingTripId)
    }
    
    func testHandleNotificationTapMissingAction() {
        let userInfo: [AnyHashable: Any] = [
            "tripId": "test-trip-999"
        ]
        
        notificationService.handleNotificationTap(userInfo: userInfo)
        
        XCTAssertNil(notificationService.pendingTripId)
    }
    
    func testHandleNotificationTapMissingTripId() {
        let userInfo: [AnyHashable: Any] = [
            "action": "open_trip"
        ]
        
        notificationService.handleNotificationTap(userInfo: userInfo)
        
        XCTAssertNil(notificationService.pendingTripId)
    }
    
    func testClearPendingNavigation() {
        // Set up a pending navigation
        let userInfo: [AnyHashable: Any] = [
            "action": "open_trip",
            "tripId": "test-trip-123"
        ]
        
        notificationService.handleNotificationTap(userInfo: userInfo)
        XCTAssertEqual(notificationService.pendingTripId, "test-trip-123")
        
        // Clear it
        notificationService.clearPendingNavigation()
        XCTAssertNil(notificationService.pendingTripId)
    }
    
    // MARK: - Edge Cases
    
    func testHandleEmptyNotificationData() {
        let userInfo: [AnyHashable: Any] = [:]
        
        notificationService.handleNotificationTap(userInfo: userInfo)
        
        XCTAssertNil(notificationService.pendingTripId)
    }
    
    func testHandleNilValues() {
        let userInfo: [AnyHashable: Any] = [
            "action": NSNull(),
            "tripId": NSNull()
        ]
        
        notificationService.handleNotificationTap(userInfo: userInfo)
        
        XCTAssertNil(notificationService.pendingTripId)
    }
    
    func testMultipleNotificationHandling() {
        // Handle first notification
        let userInfo1: [AnyHashable: Any] = [
            "action": "open_trip",
            "tripId": "trip-1"
        ]
        
        notificationService.handleNotificationTap(userInfo: userInfo1)
        XCTAssertEqual(notificationService.pendingTripId, "trip-1")
        
        // Handle second notification (should override)
        let userInfo2: [AnyHashable: Any] = [
            "action": "open_trip",
            "tripId": "trip-2"
        ]
        
        notificationService.handleNotificationTap(userInfo: userInfo2)
        XCTAssertEqual(notificationService.pendingTripId, "trip-2")
    }
    
    // MARK: - Performance Tests
    
    func testNotificationHandlingPerformance() {
        measure {
            for i in 0..<1000 {
                let userInfo: [AnyHashable: Any] = [
                    "action": "open_trip",
                    "tripId": "trip-\(i)"
                ]
                
                notificationService.handleNotificationTap(userInfo: userInfo)
                notificationService.clearPendingNavigation()
            }
        }
    }
    
    func testConcurrentNotificationHandling() async throws {
        let expectation1 = expectation(description: "First notification")
        let expectation2 = expectation(description: "Second notification")
        let expectation3 = expectation(description: "Third notification")
        
        Task {
            notificationService.handleNotificationTap(userInfo: [
                "action": "open_trip",
                "tripId": "concurrent-trip-1"
            ])
            expectation1.fulfill()
        }
        
        Task {
            notificationService.handleNotificationTap(userInfo: [
                "action": "open_trip", 
                "tripId": "concurrent-trip-2"
            ])
            expectation2.fulfill()
        }
        
        Task {
            notificationService.handleNotificationTap(userInfo: [
                "action": "open_trip",
                "tripId": "concurrent-trip-3"
            ])
            expectation3.fulfill()
        }
        
        await fulfillment(of: [expectation1, expectation2, expectation3], timeout: 2.0)
        
        // Should handle concurrent access gracefully
        XCTAssertNotNil(notificationService.pendingTripId)
    }
    
    // MARK: - State Management Tests
    
    func testStateConsistency() {
        // Test that state changes are consistent
        XCTAssertNil(notificationService.pendingTripId)
        
        // Set state
        notificationService.handleNotificationTap(userInfo: [
            "action": "open_trip",
            "tripId": "consistency-test"
        ])
        
        XCTAssertEqual(notificationService.pendingTripId, "consistency-test")
        
        // Clear state
        notificationService.clearPendingNavigation()
        XCTAssertNil(notificationService.pendingTripId)
    }
    
    func testNotificationTypes() {
        // Test different notification types
        let notificationTypes = [
            ("trip_ready", "open_trip"),
            ("admin_message", "open_conversation"),
            ("itinerary_updated", "open_trip")
        ]
        
        for (type, action) in notificationTypes {
            let userInfo: [AnyHashable: Any] = [
                "type": type,
                "action": action,
                "tripId": "test-trip-\(type)"
            ]
            
            notificationService.handleNotificationTap(userInfo: userInfo)
            XCTAssertEqual(notificationService.pendingTripId, "test-trip-\(type)")
            
            notificationService.clearPendingNavigation()
        }
    }
}