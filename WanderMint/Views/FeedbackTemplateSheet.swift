import SwiftUI

struct FeedbackTemplateSheet: View {
    let conversation: TripConversation?
    let conversationService: ConversationService
    let onTemplateSent: () async -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplate: FeedbackTemplate?
    @State private var customMessage = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Template categories
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(templateCategories, id: \.title) { category in
                            templateCategorySection(category)
                        }
                        
                        // Custom message section
                        customMessageSection
                    }
                    .padding()
                }
                
                // Send button
                if selectedTemplate != nil || !customMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    sendButtonView
                }
            }
            .navigationTitle("Quick Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What would you like to discuss?")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Choose a template or write your own message to start the conversation.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.Colors.backgroundSecondary)
    }
    
    // MARK: - Template Categories
    
    private var templateCategories: [(title: String, icon: String, templates: [FeedbackTemplate])] {
        [
            (
                title: "Flight Changes",
                icon: "airplane",
                templates: FeedbackTemplate.templates.filter { 
                    $0.changeRequestType == .flightChange 
                }
            ),
            (
                title: "Hotel & Accommodation",
                icon: "bed.double",
                templates: FeedbackTemplate.templates.filter { 
                    $0.changeRequestType == .hotelChange 
                }
            ),
            (
                title: "Activities & Experiences",
                icon: "star",
                templates: FeedbackTemplate.templates.filter { 
                    $0.changeRequestType == .activityChange 
                }
            ),
            (
                title: "Budget & Pricing",
                icon: "dollarsign.circle",
                templates: FeedbackTemplate.templates.filter { 
                    $0.changeRequestType == .budgetConcern 
                }
            ),
            (
                title: "Accessibility & Special Needs",
                icon: "accessibility",
                templates: FeedbackTemplate.templates.filter { 
                    $0.changeRequestType == .accessibility 
                }
            ),
            (
                title: "General Feedback",
                icon: "message",
                templates: FeedbackTemplate.templates.filter { 
                    $0.changeRequestType == .generalFeedback 
                }
            )
        ]
    }
    
    private func templateCategorySection(_ category: (title: String, icon: String, templates: [FeedbackTemplate])) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category header
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .foregroundColor(AppTheme.Colors.primary)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(category.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            // Templates in category
            ForEach(category.templates, id: \.id) { template in
                templateCard(template)
            }
        }
    }
    
    private func templateCard(_ template: FeedbackTemplate) -> some View {
        Button(action: {
            selectedTemplate = template
            customMessage = template.template
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(template.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if selectedTemplate?.id == template.id {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
                
                Text(template.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(
                selectedTemplate?.id == template.id 
                    ? AppTheme.Colors.primary.opacity(0.1)
                    : Color.gray.opacity(0.05)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        selectedTemplate?.id == template.id 
                            ? AppTheme.Colors.primary 
                            : Color.gray.opacity(0.2), 
                        lineWidth: selectedTemplate?.id == template.id ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    
    // MARK: - Custom Message Section
    
    private var customMessageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "pencil")
                    .foregroundColor(AppTheme.Colors.primary)
                    .font(.system(size: 16, weight: .semibold))
                
                Text("Custom Message")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Write your own message")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Type your message here...", text: $customMessage, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...8)
                    .onChange(of: customMessage) {
                        // Clear template selection if user types custom message
                        if !customMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
                           selectedTemplate != nil &&
                           customMessage != selectedTemplate?.template {
                            selectedTemplate = nil
                        }
                    }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Send Button
    
    private var sendButtonView: some View {
        VStack(spacing: 0) {
            Divider()
            
            VStack(spacing: 12) {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Button(action: sendFeedback) {
                    HStack {
                        if isSending {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                        
                        Text(isSending ? "Sending..." : "Send Message")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.Colors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isSending || 
                         (selectedTemplate == nil && customMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
            }
            .padding()
        }
        .background(AppTheme.Colors.backgroundSecondary)
    }
    
    // MARK: - Actions
    
    private func sendFeedback() {
        guard let conversation = conversation else { return }
        
        let content = customMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        isSending = true
        errorMessage = nil
        
        Task {
            do {
                if let template = selectedTemplate {
                    try await conversationService.sendFeedbackWithTemplate(
                        conversationId: conversation.id,
                        template: template,
                        customContent: content != template.template ? content : nil
                    )
                } else {
                    try await conversationService.sendMessage(
                        conversationId: conversation.id,
                        content: content,
                        messageType: .text
                    )
                }
                
                await onTemplateSent()
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            
            isSending = false
        }
    }
}