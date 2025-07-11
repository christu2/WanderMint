import Foundation
import UserNotifications
import Firebase
import FirebaseAuth
import FirebaseFirestore

@MainActor
class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    private let db = Firestore.firestore()
    private var tripListeners: [String: ListenerRegistration] = [:]
    private var conversationListeners: [String: ListenerRegistration] = [:]
    private let center = UNUserNotificationCenter.current()
    
    @Published var hasNotificationPermission = false
    @Published var pendingTripId: String? = nil // For deep linking
    
    private override init() {
        super.init()
        center.delegate = self
    }
    
    // MARK: - Permission Management
    
    func requestPermission() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                hasNotificationPermission = granted
            }
        } catch {
            await MainActor.run {
                hasNotificationPermission = false
            }
        }
    }
    
    func checkPermissionStatus() async {
        let settings = await center.notificationSettings()
        await MainActor.run {
            hasNotificationPermission = settings.authorizationStatus == .authorized
        }
    }
    
    // MARK: - Setup and Teardown
    
    func startListening() async {
        guard let user = Auth.auth().currentUser else { return }
        
        await checkPermissionStatus()
        
        if !hasNotificationPermission {
            await requestPermission()
        }
        
        // Start listening to user's trips for status changes
        await startListeningToTripUpdates(userId: user.uid)
        
        // Start listening to conversations for new admin messages
        await startListeningToConversationUpdates(userId: user.uid)
    }
    
    func stopListening() {
        // Remove all listeners
        for listener in tripListeners.values {
            listener.remove()
        }
        tripListeners.removeAll()
        
        for listener in conversationListeners.values {
            listener.remove()
        }
        conversationListeners.removeAll()
    }
    
    // MARK: - Trip Status Notifications
    
    private func startListeningToTripUpdates(userId: String) async {
        let tripsQuery = db.collection("trips")
            .whereField("userId", isEqualTo: userId)
        
        let listener = tripsQuery.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self, let snapshot = snapshot else { return }
            
            Task { @MainActor in
                await self.handleTripUpdates(snapshot: snapshot)
            }
        }
        
        tripListeners["userTrips"] = listener
    }
    
    private func handleTripUpdates(snapshot: QuerySnapshot) async {
        for change in snapshot.documentChanges {
            if change.type == .modified {
                await handleTripStatusChange(documentData: change.document.data(), tripId: change.document.documentID)
            }
        }
    }
    
    private func handleTripStatusChange(documentData: [String: Any], tripId: String) async {
        guard let statusString = documentData["status"] as? String else { return }
        
        // Only notify when trip becomes "completed" (Itinerary Ready)
        if statusString == "completed" {
            let destination = extractDestination(from: documentData)
            await sendTripReadyNotification(tripId: tripId, destination: destination)
        }
        
        // Check for itinerary updates by comparing updatedAt timestamp
        await checkForItineraryUpdate(documentData: documentData, tripId: tripId)
    }
    
    private func checkForItineraryUpdate(documentData: [String: Any], tripId: String) async {
        // Check if trip has a recommendation/itinerary and was recently updated
        guard let updatedAt = documentData["updatedAt"] as? Timestamp,
              let statusString = documentData["status"] as? String,
              statusString == "completed" else { return }
        
        // Check if update was recent (within last 5 minutes)
        let fiveMinutesAgo = Date().addingTimeInterval(-300)
        guard updatedAt.dateValue() > fiveMinutesAgo else { return }
        
        // Check if trip has recommendation data
        if documentData["recommendation"] != nil || documentData["destinationRecommendation"] != nil {
            let destination = extractDestination(from: documentData)
            await sendItineraryUpdatedNotification(tripId: tripId, destination: destination)
        }
    }
    
    private func extractDestination(from data: [String: Any]) -> String {
        if let destinations = data["destinations"] as? [String], !destinations.isEmpty {
            return destinations.joined(separator: ", ")
        } else if let destination = data["destination"] as? String {
            return destination
        }
        return "Your Trip"
    }
    
    // MARK: - Conversation Notifications
    
    private func startListeningToConversationUpdates(userId: String) async {
        let conversationsQuery = db.collection("tripConversations")
            .whereField("userId", isEqualTo: userId)
        
        let listener = conversationsQuery.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self, let snapshot = snapshot else { return }
            
            Task { @MainActor in
                await self.handleConversationUpdates(snapshot: snapshot, userId: userId)
            }
        }
        
        conversationListeners["userConversations"] = listener
    }
    
    private func handleConversationUpdates(snapshot: QuerySnapshot, userId: String) async {
        for change in snapshot.documentChanges {
            if change.type == .modified {
                let conversationId = change.document.documentID
                let data = change.document.data()
                
                // Check if there are new unread admin messages
                if let unreadUserCount = data["unreadUserCount"] as? Int, unreadUserCount > 0 {
                    await checkForNewAdminMessages(conversationId: conversationId, userId: userId)
                }
            }
        }
    }
    
    private func checkForNewAdminMessages(conversationId: String, userId: String) async {
        do {
            // Get the most recent admin message
            let messagesSnapshot = try await db.collection("tripConversations")
                .document(conversationId)
                .collection("messages")
                .whereField("senderType", isEqualTo: "admin")
                .whereField("isRead", isEqualTo: false)
                .order(by: "timestamp", descending: true)
                .limit(to: 1)
                .getDocuments()
            
            if let latestMessage = messagesSnapshot.documents.first {
                let messageData = latestMessage.data()
                let content = messageData["content"] as? String ?? "New message"
                let tripId = try await getTripIdForConversation(conversationId: conversationId)
                
                await sendAdminMessageNotification(
                    conversationId: conversationId,
                    tripId: tripId,
                    messageContent: content
                )
            }
        } catch {
            // Silently handle errors to avoid disrupting app flow
        }
    }
    
    private func getTripIdForConversation(conversationId: String) async throws -> String {
        let doc = try await db.collection("tripConversations").document(conversationId).getDocument()
        return doc.data()?["tripId"] as? String ?? ""
    }
    
    // MARK: - Notification Sending
    
    private func sendTripReadyNotification(tripId: String, destination: String) async {
        guard hasNotificationPermission else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Itinerary Ready!"
        content.body = "Your \(destination) itinerary is ready to view"
        content.sound = .default
        content.userInfo = [
            "type": "trip_ready",
            "tripId": tripId,
            "action": "open_trip"
        ]
        
        let request = UNNotificationRequest(
            identifier: "trip_ready_\(tripId)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Immediate delivery
        )
        
        do {
            try await center.add(request)
        } catch {
            // Silently handle notification delivery errors
        }
    }
    
    private func sendAdminMessageNotification(conversationId: String, tripId: String, messageContent: String) async {
        guard hasNotificationPermission else { return }
        
        let preview = String(messageContent.prefix(100))
        
        let content = UNMutableNotificationContent()
        content.title = "New Message"
        content.body = preview
        content.sound = .default
        content.userInfo = [
            "type": "admin_message",
            "conversationId": conversationId,
            "tripId": tripId,
            "action": "open_conversation"
        ]
        
        let request = UNNotificationRequest(
            identifier: "admin_message_\(conversationId)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Immediate delivery
        )
        
        do {
            try await center.add(request)
        } catch {
            // Silently handle notification delivery errors
        }
    }
    
    private func sendItineraryUpdatedNotification(tripId: String, destination: String) async {
        guard hasNotificationPermission else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Itinerary Updated"
        content.body = "Your \(destination) itinerary has been updated with new details"
        content.sound = .default
        content.userInfo = [
            "type": "itinerary_updated",
            "tripId": tripId,
            "action": "open_trip"
        ]
        
        let request = UNNotificationRequest(
            identifier: "itinerary_updated_\(tripId)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil // Immediate delivery
        )
        
        do {
            try await center.add(request)
        } catch {
            // Silently handle notification delivery errors
        }
    }
    
    // MARK: - Deep Linking Support
    
    func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let actionType = userInfo["action"] as? String else { return }
        
        switch actionType {
        case "open_trip":
            if let tripId = userInfo["tripId"] as? String {
                pendingTripId = tripId
            }
        case "open_conversation":
            if let tripId = userInfo["tripId"] as? String {
                pendingTripId = tripId
                // Could also store conversationId for direct navigation to conversation
            }
        default:
            break
        }
    }
    
    func clearPendingNavigation() {
        pendingTripId = nil
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        handleNotificationTap(userInfo: response.notification.request.content.userInfo)
        completionHandler()
    }
}