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
                .foregroundColor(AppTheme.Colors.primary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(AppTheme.Typography.h2)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(subtitle)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.lg)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(actionTitle)
                    }
                    .font(AppTheme.Typography.button)
                    .foregroundColor(.white)
                    .frame(minHeight: 44)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.vertical, AppTheme.Spacing.md)
                    .background(AppTheme.Colors.gradientPrimary)
                    .cornerRadius(AppTheme.CornerRadius.xl)
                }
                .accessibilityLabel(actionTitle)
                .accessibilityHint("Double tap to start planning your trip")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.backgroundPrimary)
    }
}

// MARK: - Enhanced Loading View
struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.primary))
            
            Text(message)
                .font(AppTheme.Typography.h4)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.backgroundPrimary)
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
                .font(AppTheme.Typography.captionBold)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(backgroundColorForStatus(status))
        .foregroundColor(.white)
        .cornerRadius(AppTheme.CornerRadius.md)
        .applyShadow(Shadow(color: backgroundColorForStatus(status).opacity(0.3), radius: 2, x: 0, y: 1))
    }
    
    private func iconForStatus(_ status: TripStatusType) -> String {
        switch status {
        case .pending: return "clock.fill"
        case .inProgress: return "gearshape.fill"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }
    
    private func backgroundColorForStatus(_ status: TripStatusType) -> Color {
        switch status {
        case .pending: return AppTheme.Colors.warning
        case .inProgress: return AppTheme.Colors.primary
        case .completed: return AppTheme.Colors.success
        case .cancelled: return AppTheme.Colors.error
        case .failed: return AppTheme.Colors.error
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
            .font(AppTheme.Typography.button)
            .foregroundColor(.white)
            .frame(minHeight: 44)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppTheme.Spacing.lg)
            .background(
                isEnabled && !isLoading ? 
                AppTheme.Colors.gradientPrimary : 
                LinearGradient(colors: [Color.gray], startPoint: .top, endPoint: .bottom)
            )
            .cornerRadius(AppTheme.CornerRadius.md)
            .applyShadow(AppTheme.Shadows.buttonShadow)
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
                .foregroundColor(AppTheme.Colors.error)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(AppTheme.Typography.h3)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(message)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppTheme.Spacing.lg)
            }
            
            if let retryAction = retryAction {
                Button(action: retryAction) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(AppTheme.Typography.button)
                    .foregroundColor(.white)
                    .frame(minHeight: 44)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .background(AppTheme.Colors.gradientPrimary)
                    .cornerRadius(AppTheme.CornerRadius.md)
                }
                .accessibilityLabel("Try Again")
                .accessibilityHint("Double tap to retry the failed operation")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.backgroundPrimary)
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
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.primary))
                
                Text(message)
                    .font(AppTheme.Typography.h4)
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            .padding(AppTheme.Spacing.xxl)
            .background(AppTheme.Colors.surfaceElevated)
            .cornerRadius(AppTheme.CornerRadius.lg)
            .applyShadow(Shadow(color: AppTheme.Shadows.heavy, radius: 10, x: 0, y: 4))
        }
    }
}