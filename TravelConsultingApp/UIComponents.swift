import SwiftUI

// MARK: - Enhanced Empty State Component
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: icon)
                .font(.system(size: 64, weight: .thin))
                .foregroundColor(.blue)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(actionTitle)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(minHeight: 44) // Accessibility touch target
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(25)
                }
                .accessibilityLabel(actionTitle)
                .accessibilityHint("Double tap to start planning your trip")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
}

// MARK: - Enhanced Loading View
struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            
            Text(message)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
}

// MARK: - Enhanced Status Badge
struct StatusBadge: View {
    let status: TripStatusType
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: iconForStatus(status))
                .font(.caption.weight(.semibold))
            Text(status.displayText)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8) // Increased from 4 to 8 for better touch target
        .background(backgroundColorForStatus(status))
        .foregroundColor(.white)
        .cornerRadius(16)
        .shadow(color: backgroundColorForStatus(status).opacity(0.3), radius: 2, x: 0, y: 1)
    }
    
    private func iconForStatus(_ status: TripStatusType) -> String {
        switch status {
        case .pending: return "clock.fill"
        case .inProgress: return "gearshape.fill"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
    
    private func backgroundColorForStatus(_ status: TripStatusType) -> Color {
        switch status {
        case .pending: return .orange
        case .inProgress: return .blue
        case .completed: return .green
        case .cancelled: return .red
        }
    }
}

// MARK: - Enhanced Primary Button
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    init(title: String, icon: String? = nil, isLoading: Bool = false, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if let icon = icon {
                    Image(systemName: icon)
                }
                Text(isLoading ? "Loading..." : title)
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(minHeight: 44) // Accessibility touch target
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20)
            .background(isEnabled && !isLoading ? Color.blue : Color.gray)
            .cornerRadius(12)
        }
        .disabled(!isEnabled || isLoading)
        .accessibilityLabel(title)
        .accessibilityHint(isEnabled ? "Double tap to \(title.lowercased())" : "Button is disabled")
    }
}

// MARK: - Enhanced Error View
struct ErrorView: View {
    let title: String
    let message: String
    let retryAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if let retryAction = retryAction {
                Button(action: retryAction) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(minHeight: 44)
                    .padding(.horizontal, 24)
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .accessibilityLabel("Try Again")
                .accessibilityHint("Double tap to retry the failed operation")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
}

// MARK: - Loading Overlay
struct LoadingOverlay: View {
    let message: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                
                Text(message)
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(40)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
        }
    }
}