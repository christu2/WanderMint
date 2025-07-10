import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class ConversationService: ObservableObject {
    private let db = Firestore.firestore()
    
    // MARK: - User Functions (iOS App)
    
    /// Start a new conversation for a trip or get existing one
    func getOrCreateConversation(for tripId: String) async throws -> TripConversation {
        guard let user = Auth.auth().currentUser else {
            throw TravelAppError.authenticationFailed
        }
        
        // Check if conversation already exists
        let query = db.collection("tripConversations")
            .whereField("tripId", isEqualTo: tripId)
            .whereField("userId", isEqualTo: user.uid)
            .limit(to: 1)
        
        let snapshot = try await query.getDocuments()
        
        if let existingDoc = snapshot.documents.first {
            return try parseConversation(from: existingDoc.data(), id: existingDoc.documentID)
        }
        
        // Create new conversation
        let conversationId = UUID().uuidString
        let newConversation = TripConversation(
            id: conversationId,
            tripId: tripId,
            userId: user.uid,
            messages: [],
            status: .active,
            createdAt: Timestamp(),
            lastMessageAt: Timestamp(),
            unreadAdminCount: 0,
            unreadUserCount: 0
        )
        
        let conversationData = try conversationToFirestore(newConversation)
        try await db.collection("tripConversations").document(conversationId).setData(conversationData)
        
        return newConversation
    }
    
    /// Send a message in a conversation
    func sendMessage(
        conversationId: String,
        content: String,
        messageType: ConversationMessage.MessageType = .text,
        metadata: MessageMetadata? = nil
    ) async throws {
        guard let user = Auth.auth().currentUser else {
            throw TravelAppError.authenticationFailed
        }
        
        let messageId = UUID().uuidString
        let message = ConversationMessage(
            id: messageId,
            conversationId: conversationId,
            senderId: user.uid,
            senderType: .user,
            messageType: messageType,
            content: content,
            attachments: nil,
            timestamp: Timestamp(),
            isRead: false,
            metadata: metadata
        )
        
        let messageData = try messageToFirestore(message)
        
        // Add message to subcollection
        try await db.collection("tripConversations")
            .document(conversationId)
            .collection("messages")
            .document(messageId)
            .setData(messageData)
        
        // Update conversation metadata
        try await db.collection("tripConversations")
            .document(conversationId)
            .updateData([
                "lastMessageAt": Timestamp(),
                "status": TripConversation.ConversationStatus.needsResponse.rawValue,
                "unreadAdminCount": FieldValue.increment(Int64(1))
            ])
        
        // Send notification to admin (you)
        try await sendAdminNotification(conversationId: conversationId, messageContent: content)
    }
    
    /// Send feedback using a template
    func sendFeedbackWithTemplate(
        conversationId: String,
        template: FeedbackTemplate,
        customContent: String? = nil,
        relatedItemId: String? = nil
    ) async throws {
        let content = customContent ?? template.template
        let metadata = MessageMetadata(
            itinerarySection: nil,
            requestType: template.changeRequestType,
            urgency: template.urgency,
            relatedItemId: relatedItemId
        )
        
        try await sendMessage(
            conversationId: conversationId,
            content: content,
            messageType: template.messageType,
            metadata: metadata
        )
    }
    
    /// Get conversation with messages
    func getConversationWithMessages(conversationId: String) async throws -> (TripConversation, [ConversationMessage]) {
        // Get conversation
        let conversationDoc = try await db.collection("tripConversations").document(conversationId).getDocument()
        
        guard let conversationData = conversationDoc.data() else {
            throw TravelAppError.dataError("Conversation not found")
        }
        
        let conversation = try parseConversation(from: conversationData, id: conversationDoc.documentID)
        
        // Get messages
        let messagesSnapshot = try await db.collection("tripConversations")
            .document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .getDocuments()
        
        let messages = try messagesSnapshot.documents.compactMap { doc in
            try parseMessage(from: doc.data(), id: doc.documentID)
        }
        
        return (conversation, messages)
    }
    
    /// Mark messages as read by user
    func markMessagesAsRead(conversationId: String) async throws {
        guard let user = Auth.auth().currentUser else {
            throw TravelAppError.authenticationFailed
        }
        
        // Get unread admin messages
        let unreadMessages = try await db.collection("tripConversations")
            .document(conversationId)
            .collection("messages")
            .whereField("senderType", isEqualTo: "admin")
            .whereField("isRead", isEqualTo: false)
            .getDocuments()
        
        let batch = db.batch()
        
        // Mark each message as read
        for messageDoc in unreadMessages.documents {
            batch.updateData(["isRead": true], forDocument: messageDoc.reference)
        }
        
        // Update conversation unread count
        batch.updateData([
            "unreadUserCount": 0
        ], forDocument: db.collection("tripConversations").document(conversationId))
        
        try await batch.commit()
    }
    
    // MARK: - Admin Functions (for your travelAdmin dashboard)
    
    /// Get all conversations that need attention
    func getConversationsNeedingResponse() async throws -> [TripConversation] {
        let snapshot = try await db.collection("tripConversations")
            .whereField("status", isEqualTo: TripConversation.ConversationStatus.needsResponse.rawValue)
            .order(by: "lastMessageAt", descending: true)
            .getDocuments()
        
        return try snapshot.documents.compactMap { doc in
            try parseConversation(from: doc.data(), id: doc.documentID)
        }
    }
    
    /// Send admin response
    func sendAdminResponse(
        conversationId: String,
        content: String,
        newStatus: TripConversation.ConversationStatus = .waitingForUser
    ) async throws {
        let messageId = UUID().uuidString
        let message = ConversationMessage(
            id: messageId,
            conversationId: conversationId,
            senderId: "admin", // Your admin ID
            senderType: .admin,
            messageType: .text,
            content: content,
            attachments: nil,
            timestamp: Timestamp(),
            isRead: false,
            metadata: nil
        )
        
        let messageData = try messageToFirestore(message)
        
        // Add message to subcollection
        try await db.collection("tripConversations")
            .document(conversationId)
            .collection("messages")
            .document(messageId)
            .setData(messageData)
        
        // Update conversation
        try await db.collection("tripConversations")
            .document(conversationId)
            .updateData([
                "lastMessageAt": Timestamp(),
                "status": newStatus.rawValue,
                "unreadUserCount": FieldValue.increment(Int64(1)),
                "unreadAdminCount": 0
            ])
    }
    
    // MARK: - Notification Functions
    
    private func sendAdminNotification(conversationId: String, messageContent: String) async throws {
        // This could integrate with email service, push notifications, etc.
        // For now, we'll store it as a simple notification record
        
        let notificationData: [String: Any] = [
            "type": "new_user_message",
            "conversationId": conversationId,
            "preview": String(messageContent.prefix(100)),
            "timestamp": Timestamp(),
            "isRead": false
        ]
        
        try await db.collection("adminNotifications").addDocument(data: notificationData)
    }
    
    // MARK: - Helper Functions
    
    private func parseConversation(from data: [String: Any], id: String) throws -> TripConversation {
        return TripConversation(
            id: id,
            tripId: data["tripId"] as? String ?? "",
            userId: data["userId"] as? String ?? "",
            messages: [], // Messages loaded separately
            status: TripConversation.ConversationStatus(rawValue: data["status"] as? String ?? "active") ?? .active,
            createdAt: data["createdAt"] as? Timestamp ?? Timestamp(),
            lastMessageAt: data["lastMessageAt"] as? Timestamp ?? Timestamp(),
            unreadAdminCount: data["unreadAdminCount"] as? Int ?? 0,
            unreadUserCount: data["unreadUserCount"] as? Int ?? 0
        )
    }
    
    private func parseMessage(from data: [String: Any], id: String) throws -> ConversationMessage {
        return ConversationMessage(
            id: id,
            conversationId: data["conversationId"] as? String ?? "",
            senderId: data["senderId"] as? String ?? "",
            senderType: ConversationMessage.SenderType(rawValue: data["senderType"] as? String ?? "user") ?? .user,
            messageType: ConversationMessage.MessageType(rawValue: data["messageType"] as? String ?? "text") ?? .text,
            content: data["content"] as? String ?? "",
            attachments: nil, // TODO: Parse attachments if needed
            timestamp: data["timestamp"] as? Timestamp ?? Timestamp(),
            isRead: data["isRead"] as? Bool ?? false,
            metadata: parseMessageMetadata(from: data["metadata"] as? [String: Any])
        )
    }
    
    private func parseMessageMetadata(from data: [String: Any]?) -> MessageMetadata? {
        guard let data = data else { return nil }
        
        return MessageMetadata(
            itinerarySection: data["itinerarySection"] as? String,
            requestType: MessageMetadata.ChangeRequestType(rawValue: data["requestType"] as? String ?? ""),
            urgency: MessageMetadata.MessageUrgency(rawValue: data["urgency"] as? String ?? "medium"),
            relatedItemId: data["relatedItemId"] as? String
        )
    }
    
    private func conversationToFirestore(_ conversation: TripConversation) throws -> [String: Any] {
        return [
            "tripId": conversation.tripId,
            "userId": conversation.userId,
            "status": conversation.status.rawValue,
            "createdAt": conversation.createdAt,
            "lastMessageAt": conversation.lastMessageAt,
            "unreadAdminCount": conversation.unreadAdminCount,
            "unreadUserCount": conversation.unreadUserCount
        ]
    }
    
    private func messageToFirestore(_ message: ConversationMessage) throws -> [String: Any] {
        var data: [String: Any] = [
            "conversationId": message.conversationId,
            "senderId": message.senderId,
            "senderType": message.senderType.rawValue,
            "messageType": message.messageType.rawValue,
            "content": message.content,
            "timestamp": message.timestamp,
            "isRead": message.isRead
        ]
        
        if let metadata = message.metadata {
            data["metadata"] = [
                "itinerarySection": metadata.itinerarySection as Any,
                "requestType": metadata.requestType?.rawValue as Any,
                "urgency": metadata.urgency?.rawValue as Any,
                "relatedItemId": metadata.relatedItemId as Any
            ]
        }
        
        return data
    }
}