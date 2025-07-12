import Foundation

// MARK: - Trip Conversation Models

struct TripConversation: Identifiable, Codable {
    let id: String
    let tripId: String
    let userId: String
    let messages: [ConversationMessage]
    let status: ConversationStatus
    let createdAt: AppTimestamp
    let lastMessageAt: AppTimestamp
    let unreadAdminCount: Int // Messages admin hasn't read
    let unreadUserCount: Int  // Messages user hasn't read
    
    enum ConversationStatus: String, Codable, CaseIterable {
        case active = "active"
        case resolved = "resolved"
        case needsResponse = "needs_response"
        case waitingForUser = "waiting_for_user"
    }
}

struct ConversationMessage: Identifiable, Codable {
    let id: String
    let conversationId: String
    let senderId: String
    let senderType: SenderType
    let messageType: MessageType
    let content: String
    let attachments: [MessageAttachment]?
    let timestamp: AppTimestamp
    let isRead: Bool
    let metadata: MessageMetadata?
    
    enum SenderType: String, Codable {
        case user = "user"
        case admin = "admin"
        case system = "system"
    }
    
    enum MessageType: String, Codable {
        case text = "text"
        case itineraryFeedback = "itinerary_feedback"
        case changeRequest = "change_request"
        case systemUpdate = "system_update"
    }
}

struct MessageAttachment: Codable {
    let id: String
    let fileName: String
    let fileType: String
    let fileSize: Int
    let downloadUrl: String
}

struct MessageMetadata: Codable {
    let itinerarySection: String? // "flights", "accommodations", "activities"
    let requestType: ChangeRequestType?
    let urgency: MessageUrgency?
    let relatedItemId: String? // ID of specific flight, hotel, etc.
    
    enum ChangeRequestType: String, Codable {
        case flightChange = "flight_change"
        case hotelChange = "hotel_change"
        case activityChange = "activity_change"
        case dateChange = "date_change"
        case generalFeedback = "general_feedback"
        case budgetConcern = "budget_concern"
        case accessibility = "accessibility"
        case groupSizeChange = "group_size_change"
    }
    
    enum MessageUrgency: String, Codable {
        case low = "low"
        case medium = "medium"
        case high = "high"
        case urgent = "urgent"
    }
}

// MARK: - Quick Feedback Templates

struct FeedbackTemplate {
    let id: String
    let title: String
    let description: String
    let messageType: ConversationMessage.MessageType
    let changeRequestType: MessageMetadata.ChangeRequestType?
    let urgency: MessageMetadata.MessageUrgency
    let template: String
    
    static let templates: [FeedbackTemplate] = [
        FeedbackTemplate(
            id: "flight_too_early",
            title: "Flight too early",
            description: "Request later departure time",
            messageType: .changeRequest,
            changeRequestType: .flightChange,
            urgency: .medium,
            template: "Hi! The departure time for my flight is too early. Could we look for flights departing after [TIME]? Thanks!"
        ),
        FeedbackTemplate(
            id: "hotel_location",
            title: "Hotel location concern",
            description: "Request different hotel area",
            messageType: .changeRequest,
            changeRequestType: .hotelChange,
            urgency: .medium,
            template: "I'd prefer to stay in a different area. Could we look for hotels in [AREA]? I'm concerned about [REASON]."
        ),
        FeedbackTemplate(
            id: "budget_too_high",
            title: "Over budget",
            description: "Request more budget-friendly options",
            messageType: .changeRequest,
            changeRequestType: .budgetConcern,
            urgency: .high,
            template: "The current itinerary is over my budget. Could we find more affordable options for [SPECIFIC ITEMS]?"
        ),
        FeedbackTemplate(
            id: "add_activity",
            title: "Add specific activity",
            description: "Request additional activities",
            messageType: .changeRequest,
            changeRequestType: .activityChange,
            urgency: .low,
            template: "I'd love to add [ACTIVITY] to my itinerary. Is this possible on [DATE]?"
        ),
        FeedbackTemplate(
            id: "accessibility_needs",
            title: "Accessibility requirements",
            description: "Request accessibility accommodations",
            messageType: .changeRequest,
            changeRequestType: .accessibility,
            urgency: .high,
            template: "I need to ensure accessibility for [SPECIFIC NEEDS]. Can we verify this for the hotels and activities?"
        ),
        FeedbackTemplate(
            id: "general_feedback",
            title: "General feedback",
            description: "Provide general comments or questions",
            messageType: .itineraryFeedback,
            changeRequestType: .generalFeedback,
            urgency: .low,
            template: "I have some feedback about the itinerary: [YOUR FEEDBACK]"
        )
    ]
}

// MARK: - Admin Response Templates

struct AdminResponseTemplate {
    let id: String
    let title: String
    let template: String
    let suggestedStatus: TripConversation.ConversationStatus
    
    static let adminTemplates: [AdminResponseTemplate] = [
        AdminResponseTemplate(
            id: "acknowledged",
            title: "Request acknowledged",
            template: "Thanks for your feedback! I'm looking into this and will get back to you with options within 24 hours.",
            suggestedStatus: .needsResponse
        ),
        AdminResponseTemplate(
            id: "options_provided",
            title: "Options provided",
            template: "I've found some alternatives for you. Please review the updated options and let me know which you prefer.",
            suggestedStatus: .waitingForUser
        ),
        AdminResponseTemplate(
            id: "clarification_needed",
            title: "Need more details",
            template: "To find the best options for you, could you provide more details about [SPECIFIC QUESTION]?",
            suggestedStatus: .waitingForUser
        ),
        AdminResponseTemplate(
            id: "changes_made",
            title: "Changes completed",
            template: "Great news! I've updated your itinerary with the changes you requested. Please review and let me know if you need any adjustments.",
            suggestedStatus: .resolved
        )
    ]
}