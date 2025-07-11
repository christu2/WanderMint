//
//  NotificationTestHelpers.swift
//  WanderMintTests
//
//  Created by Claude Code on 7/11/25.
//

import Foundation
import XCTest
import UserNotifications
import Firebase
import FirebaseFirestore
@testable import WanderMint

// MARK: - Notification Test Helpers

struct NotificationTestHelpers {
    
    // MARK: - Notification Content Validation
    
    static func validateTripReadyNotificationContent(_ content: UNNotificationContent) -> Bool {
        return content.title == "Itinerary Ready!" &&
               content.body.contains("itinerary is ready to view") &&
               content.userInfo["type"] as? String == "trip_ready" &&
               content.userInfo["action"] as? String == "open_trip"
    }
    
    static func validateAdminMessageNotificationContent(_ content: UNNotificationContent) -> Bool {
        return content.title == "New Message" &&
               content.userInfo["type"] as? String == "admin_message" &&
               content.userInfo["action"] as? String == "open_conversation"
    }
    
    static func validateItineraryUpdateNotificationContent(_ content: UNNotificationContent) -> Bool {
        return content.title == "Itinerary Updated" &&
               content.body.contains("has been updated with new details") &&
               content.userInfo["type"] as? String == "itinerary_updated" &&
               content.userInfo["action"] as? String == "open_trip"
    }
    
    // MARK: - Mock Data Factories
    
    static func createMockTripDocument(
        id: String = "test-trip",
        status: TripStatusType = .completed,
        destination: String = "Test Destination",
        destinations: [String]? = nil,
        hasRecommendation: Bool = false,
        updatedMinutesAgo: Int = 1
    ) -> MockQueryDocumentSnapshot {
        var data: [String: Any] = [
            "id": id,
            "userId": "test-user",
            "status": status.rawValue,
            "destination": destination,
            "updatedAt": Timestamp(date: Date().addingTimeInterval(-Double(updatedMinutesAgo * 60))),
            "createdAt": Timestamp(date: Date().addingTimeInterval(-86400))
        ]
        
        if let destinations = destinations {
            data["destinations"] = destinations
        }
        
        if hasRecommendation {
            data["recommendation"] = [
                "hotels": ["Hotel A", "Hotel B"],
                "activities": ["Activity 1", "Activity 2"]
            ]
        }
        
        return MockQueryDocumentSnapshot(documentID: id, data: data)
    }
    
    static func createMockConversationDocument(
        id: String = "test-conversation",
        tripId: String = "test-trip",
        unreadUserCount: Int = 1
    ) -> MockQueryDocumentSnapshot {
        let data: [String: Any] = [
            "id": id,
            "tripId": tripId,
            "userId": "test-user",
            "unreadUserCount": unreadUserCount,
            "updatedAt": Timestamp(date: Date())
        ]
        
        return MockQueryDocumentSnapshot(documentID: id, data: data)
    }
    
    static func createMockMessageDocument(
        id: String = "test-message",
        content: String = "Test admin message",
        senderType: String = "admin",
        isRead: Bool = false
    ) -> MockQueryDocumentSnapshot {
        let data: [String: Any] = [
            "id": id,
            "content": content,
            "senderType": senderType,
            "isRead": isRead,
            "timestamp": Timestamp(date: Date())
        ]
        
        return MockQueryDocumentSnapshot(documentID: id, data: data)
    }
    
    // MARK: - Notification Payload Builders
    
    static func buildTripReadyNotificationPayload(tripId: String) -> [AnyHashable: Any] {
        return [
            "type": "trip_ready",
            "tripId": tripId,
            "action": "open_trip"
        ]
    }
    
    static func buildAdminMessageNotificationPayload(
        tripId: String,
        conversationId: String
    ) -> [AnyHashable: Any] {
        return [
            "type": "admin_message",
            "tripId": tripId,
            "conversationId": conversationId,
            "action": "open_conversation"
        ]
    }
    
    static func buildItineraryUpdateNotificationPayload(tripId: String) -> [AnyHashable: Any] {
        return [
            "type": "itinerary_updated",
            "tripId": tripId,
            "action": "open_trip"
        ]
    }
    
    // MARK: - Test Assertion Helpers
    
    static func assertValidNotificationRequest(
        _ request: UNNotificationRequest,
        expectedType: String,
        expectedTripId: String
    ) {
        guard let userInfo = request.content.userInfo as? [String: Any] else {
            XCTFail("Notification request should have userInfo")
            return
        }
        
        XCTAssertEqual(userInfo["type"] as? String, expectedType)
        XCTAssertEqual(userInfo["tripId"] as? String, expectedTripId)
        XCTAssertNotNil(userInfo["action"])
    }
    
    static func assertNotificationIdentifierFormat(_ identifier: String, expectedPrefix: String) {
        XCTAssertTrue(identifier.hasPrefix(expectedPrefix), 
                     "Notification identifier should start with \(expectedPrefix)")
        XCTAssertTrue(identifier.contains("_"), 
                     "Notification identifier should contain underscore")
    }
}

// MARK: - Mock Firestore Types

class MockQueryDocumentSnapshot {
    let documentID: String
    private let _data: [String: Any]
    
    init(documentID: String, data: [String: Any]) {
        self.documentID = documentID
        self._data = data
    }
    
    func data() -> [String: Any] {
        return _data
    }
}

class MockQuerySnapshot {
    let documentChanges: [MockDocumentChange]
    
    init(documentChanges: [MockDocumentChange]) {
        self.documentChanges = documentChanges
    }
}

class MockDocumentChange {
    let type: DocumentChangeType
    let document: MockQueryDocumentSnapshot
    
    init(type: DocumentChangeType, document: MockQueryDocumentSnapshot) {
        self.type = type
        self.document = document
    }
}

// MARK: - Test Scenarios

struct NotificationTestScenarios {
    
    // MARK: - Trip Status Change Scenarios
    
    static func tripStatusChangedToCompleted() -> MockQuerySnapshot {
        let tripDocument = NotificationTestHelpers.createMockTripDocument(
            id: "trip-completed-123",
            status: .completed,
            destination: "Paris, France"
        )
        
        let documentChange = MockDocumentChange(
            type: .modified,
            document: tripDocument
        )
        
        return MockQuerySnapshot(documentChanges: [documentChange])
    }
    
    static func tripStatusChangedToInProgress() -> MockQuerySnapshot {
        let tripDocument = NotificationTestHelpers.createMockTripDocument(
            id: "trip-inprogress-123",
            status: .inProgress,
            destination: "London, UK"
        )
        
        let documentChange = MockDocumentChange(
            type: .modified,
            document: tripDocument
        )
        
        return MockQuerySnapshot(documentChanges: [documentChange])
    }
    
    // MARK: - Conversation Update Scenarios
    
    static func conversationWithNewAdminMessage() -> MockQuerySnapshot {
        let conversationDocument = NotificationTestHelpers.createMockConversationDocument(
            id: "conv-admin-msg-123",
            tripId: "trip-456",
            unreadUserCount: 1
        )
        
        let documentChange = MockDocumentChange(
            type: .modified,
            document: conversationDocument
        )
        
        return MockQuerySnapshot(documentChanges: [documentChange])
    }
    
    static func conversationWithNoUnreadMessages() -> MockQuerySnapshot {
        let conversationDocument = NotificationTestHelpers.createMockConversationDocument(
            id: "conv-no-unread-123",
            tripId: "trip-789",
            unreadUserCount: 0
        )
        
        let documentChange = MockDocumentChange(
            type: .modified,
            document: conversationDocument
        )
        
        return MockQuerySnapshot(documentChanges: [documentChange])
    }
    
    // MARK: - Itinerary Update Scenarios
    
    static func recentItineraryUpdate() -> MockQuerySnapshot {
        let tripDocument = NotificationTestHelpers.createMockTripDocument(
            id: "trip-recent-update-123",
            status: .completed,
            destination: "Tokyo, Japan",
            hasRecommendation: true,
            updatedMinutesAgo: 2 // 2 minutes ago
        )
        
        let documentChange = MockDocumentChange(
            type: .modified,
            document: tripDocument
        )
        
        return MockQuerySnapshot(documentChanges: [documentChange])
    }
    
    static func oldItineraryUpdate() -> MockQuerySnapshot {
        let tripDocument = NotificationTestHelpers.createMockTripDocument(
            id: "trip-old-update-123",
            status: .completed,
            destination: "Rome, Italy",
            hasRecommendation: true,
            updatedMinutesAgo: 10 // 10 minutes ago (too old)
        )
        
        let documentChange = MockDocumentChange(
            type: .modified,
            document: tripDocument
        )
        
        return MockQuerySnapshot(documentChanges: [documentChange])
    }
}

// MARK: - XCTest Extensions

extension XCTestCase {
    
    func waitForNotificationCenter(timeout: TimeInterval = 1.0) {
        let expectation = expectation(description: "Notification center processing")
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: timeout + 0.5)
    }
    
    func simulateNotificationTap(
        with userInfo: [AnyHashable: Any],
        on notificationService: NotificationService
    ) {
        Task { @MainActor in
            notificationService.handleNotificationTap(userInfo: userInfo)
        }
    }
    
    func assertDeepLinkNavigation(
        to expectedTripId: String,
        on notificationService: NotificationService
    ) {
        Task { @MainActor in
            XCTAssertEqual(notificationService.pendingTripId, expectedTripId,
                          "Should navigate to trip \(expectedTripId)")
        }
    }
}