import SwiftUI

struct TripConversationView: View {
    let trip: TravelTrip
    @StateObject private var conversationService = ConversationService()
    @State private var conversation: TripConversation?
    @State private var messages: [ConversationMessage] = []
    @State private var newMessageText = ""
    @State private var showingTemplateSheet = false
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with trip info
                tripHeaderView
                
                if isLoading {
                    ProgressView("Loading conversation...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let conversation = conversation {
                    // Messages list
                    messagesListView
                    
                    // Message input
                    messageInputView
                } else {
                    errorView
                }
            }
            .navigationTitle("Request Changes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Templates") {
                        showingTemplateSheet = true
                    }
                }
            }
            .sheet(isPresented: $showingTemplateSheet) {
                FeedbackTemplateSheet(
                    conversation: conversation,
                    conversationService: conversationService,
                    onTemplateSent: loadMessages
                )
            }
        }
        .task {
            await loadConversation()
        }
    }
    
    // MARK: - Header View
    
    private var tripHeaderView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "airplane")
                    .foregroundColor(AppTheme.Colors.primary)
                Text(trip.destination ?? trip.destinations?.joined(separator: " → ") ?? "Your Trip")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                Text("\(trip.startDate.dateValue(), formatter: DateFormatter.shortDate) - \(trip.endDate.dateValue(), formatter: DateFormatter.shortDate)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let conversation = conversation {
                    conversationStatusBadge(conversation.status)
                }
            }
        }
        .padding()
        .background(AppTheme.Colors.backgroundSecondary)
        .border(Color.gray.opacity(0.3), width: 0.5)
    }
    
    private func conversationStatusBadge(_ status: TripConversation.ConversationStatus) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor(status))
                .frame(width: 8, height: 8)
            Text(statusText(status))
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor(status).opacity(0.1))
        .cornerRadius(8)
    }
    
    private func statusColor(_ status: TripConversation.ConversationStatus) -> Color {
        switch status {
        case .active: return .blue
        case .needsResponse: return .orange
        case .waitingForUser: return .purple
        case .resolved: return .green
        }
    }
    
    private func statusText(_ status: TripConversation.ConversationStatus) -> String {
        switch status {
        case .active: return "Active"
        case .needsResponse: return "Pending Response"
        case .waitingForUser: return "Your Turn"
        case .resolved: return "Resolved"
        }
    }
    
    // MARK: - Messages List
    
    private var messagesListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    if messages.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "message.circle")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary)
                            
                            Text("Start a conversation")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            Text("Ask questions, request changes, or provide feedback about your itinerary.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button("Use Quick Templates") {
                                showingTemplateSheet = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ForEach(messages) { message in
                            MessageBubbleView(message: message)
                                .id(message.id)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)
            }
            .onChange(of: messages.count) { _ in
                if let lastMessage = messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
            .onAppear {
                // Auto-scroll to bottom when view loads
                if let lastMessage = messages.last {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    // MARK: - Message Input
    
    private var messageInputView: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                Button(action: { showingTemplateSheet = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(AppTheme.Colors.primary)
                }
                
                TextField("Type your message...", text: $newMessageText, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : AppTheme.Colors.primary)
                }
                .disabled(newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .background(AppTheme.Colors.backgroundSecondary)
    }
    
    // MARK: - Error View
    
    private var errorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Unable to load conversation")
                .font(.title3)
                .fontWeight(.semibold)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button("Try Again") {
                Task {
                    await loadConversation()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func loadConversation() async {
        isLoading = true
        errorMessage = nil
        
        do {
            conversation = try await conversationService.getOrCreateConversation(for: trip.id)
            await loadMessages()
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func loadMessages() async {
        guard let conversation = conversation else { return }
        
        do {
            let (_, loadedMessages) = try await conversationService.getConversationWithMessages(conversationId: conversation.id)
            self.messages = loadedMessages
            
            // Mark messages as read
            try await conversationService.markMessagesAsRead(conversationId: conversation.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    private func sendMessage() {
        let content = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty, let conversation = conversation else { return }
        
        newMessageText = ""
        
        Task {
            do {
                // Set default medium urgency for user messages (hidden from UI)
                let metadata = MessageMetadata(
                    itinerarySection: nil,
                    requestType: nil,
                    urgency: .medium,
                    relatedItemId: nil
                )
                
                try await conversationService.sendMessage(
                    conversationId: conversation.id,
                    content: content,
                    metadata: metadata
                )
                await loadMessages()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Message Bubble View

struct MessageBubbleView: View {
    let message: ConversationMessage
    
    private var isFromUser: Bool {
        message.senderType == .user
    }
    
    private var isFromAdmin: Bool {
        message.senderType == .admin
    }
    
    var body: some View {
        HStack {
            if isFromUser {
                Spacer(minLength: 50)
            }
            
            VStack(alignment: isFromUser ? .trailing : .leading, spacing: 4) {
                // Message type indicator
                if message.messageType != .text {
                    messageTypeIndicator
                }
                
                // Message content
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(messageBackgroundColor)
                    .foregroundColor(messageForegroundColor)
                    .cornerRadius(16)
                
                // Timestamp and metadata
                HStack(spacing: 8) {
                    if isFromAdmin {
                        Text("Travel Consultant")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.Colors.primary)
                    }
                    
                    Text(message.timestamp.dateValue(), formatter: DateFormatter.timeOnly)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    if message.metadata?.urgency == .high || message.metadata?.urgency == .urgent {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                }
            }
            
            if isFromAdmin {
                Spacer(minLength: 50)
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var messageTypeIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: messageTypeIcon)
                .font(.caption2)
            Text(messageTypeText)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(Color.blue.opacity(0.1))
        .foregroundColor(.blue)
        .cornerRadius(8)
    }
    
    private var messageTypeIcon: String {
        switch message.messageType {
        case .changeRequest: return "arrow.triangle.2.circlepath"
        case .itineraryFeedback: return "star.circle"
        case .systemUpdate: return "info.circle"
        default: return "message"
        }
    }
    
    private var messageTypeText: String {
        switch message.messageType {
        case .changeRequest: return "Change Request"
        case .itineraryFeedback: return "Feedback"
        case .systemUpdate: return "Update"
        default: return "Message"
        }
    }
    
    private var messageBackgroundColor: Color {
        switch message.senderType {
        case .user:
            return AppTheme.Colors.primary
        case .admin:
            return Color.gray.opacity(0.2)
        case .system:
            return Color.blue.opacity(0.1)
        }
    }
    
    private var messageForegroundColor: Color {
        switch message.senderType {
        case .user:
            return .white
        case .admin, .system:
            return AppTheme.Colors.textPrimary
        }
    }
}

// MARK: - Date Formatters

private extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}