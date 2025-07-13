import UIKit
import SwiftUI

/// Comprehensive haptic feedback service for enhanced user experience
class HapticFeedbackService {
    static let shared = HapticFeedbackService()
    
    private init() {}
    
    // MARK: - Impact Feedback
    
    /// Light impact feedback for subtle interactions
    func lightImpact() {
        guard isHapticsEnabled else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    /// Medium impact feedback for standard interactions
    func mediumImpact() {
        guard isHapticsEnabled else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    /// Heavy impact feedback for significant interactions
    func heavyImpact() {
        guard isHapticsEnabled else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Notification Feedback
    
    /// Success notification feedback
    func success() {
        guard isHapticsEnabled else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
    }
    
    /// Warning notification feedback
    func warning() {
        guard isHapticsEnabled else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.warning)
    }
    
    /// Error notification feedback
    func error() {
        guard isHapticsEnabled else { return }
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.error)
    }
    
    // MARK: - Selection Feedback
    
    /// Selection change feedback
    func selectionChanged() {
        guard isHapticsEnabled else { return }
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
    }
    
    // MARK: - Context-Specific Feedback
    
    /// Feedback for button taps
    func buttonTap() {
        lightImpact()
    }
    
    /// Feedback for toggle switches
    func toggleSwitch() {
        mediumImpact()
    }
    
    /// Feedback for form submission
    func formSubmission() {
        heavyImpact()
    }
    
    /// Feedback for navigation
    func navigation() {
        lightImpact()
    }
    
    /// Feedback for pull-to-refresh
    func pullToRefresh() {
        mediumImpact()
    }
    
    /// Feedback for swipe actions
    func swipeAction() {
        lightImpact()
    }
    
    /// Feedback for drag and drop
    func dragAndDrop() {
        mediumImpact()
    }
    
    /// Feedback for loading completion
    func loadingComplete() {
        success()
    }
    
    /// Feedback for error states
    func errorOccurred() {
        error()
    }
    
    /// Feedback for validation errors
    func validationError() {
        warning()
    }
    
    /// Feedback for successful operations
    func operationSuccess() {
        success()
    }
    
    // MARK: - Travel App Specific Feedback
    
    /// Feedback for trip submission
    func tripSubmitted() {
        success()
        // Add a slight delay and another light impact for emphasis
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.lightImpact()
        }
    }
    
    /// Feedback for adding destinations
    func destinationAdded() {
        lightImpact()
    }
    
    /// Feedback for removing destinations
    func destinationRemoved() {
        mediumImpact()
    }
    
    /// Feedback for points added
    func pointsAdded() {
        success()
    }
    
    /// Feedback for message sent
    func messageSent() {
        lightImpact()
    }
    
    /// Feedback for notification received
    func notificationReceived() {
        mediumImpact()
    }
    
    /// Feedback for authentication success
    func authenticationSuccess() {
        success()
    }
    
    /// Feedback for authentication failure
    func authenticationFailure() {
        error()
    }
    
    /// Feedback for search results
    func searchResults() {
        lightImpact()
    }
    
    /// Feedback for filter applied
    func filterApplied() {
        selectionChanged()
    }
    
    // MARK: - Settings
    
    private var isHapticsEnabled: Bool {
        // Check if haptics are enabled in system settings
        // Also check user preferences if we have a settings screen
        return UIDevice.current.userInterfaceIdiom == .phone
    }
}

// MARK: - SwiftUI Button Extensions

extension Button {
    /// Add haptic feedback to button
    func hapticFeedback(_ type: HapticFeedbackType = .light) -> some View {
        self.onTapGesture {
            switch type {
            case .light:
                HapticFeedbackService.shared.lightImpact()
            case .medium:
                HapticFeedbackService.shared.mediumImpact()
            case .heavy:
                HapticFeedbackService.shared.heavyImpact()
            case .success:
                HapticFeedbackService.shared.success()
            case .warning:
                HapticFeedbackService.shared.warning()
            case .error:
                HapticFeedbackService.shared.error()
            case .selection:
                HapticFeedbackService.shared.selectionChanged()
            case .buttonTap:
                HapticFeedbackService.shared.buttonTap()
            case .navigation:
                HapticFeedbackService.shared.navigation()
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    /// Add haptic feedback to any view
    func hapticFeedback(_ type: HapticFeedbackType = .light) -> some View {
        self.onTapGesture {
            switch type {
            case .light:
                HapticFeedbackService.shared.lightImpact()
            case .medium:
                HapticFeedbackService.shared.mediumImpact()
            case .heavy:
                HapticFeedbackService.shared.heavyImpact()
            case .success:
                HapticFeedbackService.shared.success()
            case .warning:
                HapticFeedbackService.shared.warning()
            case .error:
                HapticFeedbackService.shared.error()
            case .selection:
                HapticFeedbackService.shared.selectionChanged()
            case .buttonTap:
                HapticFeedbackService.shared.buttonTap()
            case .navigation:
                HapticFeedbackService.shared.navigation()
            }
        }
    }
    
    /// Add haptic feedback when a condition changes
    func hapticFeedbackOnChange<T: Equatable>(
        of value: T,
        perform action: @escaping (T) -> HapticFeedbackType
    ) -> some View {
        self.onChange(of: value) { newValue in
            let feedbackType = action(newValue)
            switch feedbackType {
            case .light:
                HapticFeedbackService.shared.lightImpact()
            case .medium:
                HapticFeedbackService.shared.mediumImpact()
            case .heavy:
                HapticFeedbackService.shared.heavyImpact()
            case .success:
                HapticFeedbackService.shared.success()
            case .warning:
                HapticFeedbackService.shared.warning()
            case .error:
                HapticFeedbackService.shared.error()
            case .selection:
                HapticFeedbackService.shared.selectionChanged()
            case .buttonTap:
                HapticFeedbackService.shared.buttonTap()
            case .navigation:
                HapticFeedbackService.shared.navigation()
            }
        }
    }
}

// MARK: - Haptic Feedback Types

enum HapticFeedbackType {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    case selection
    case buttonTap
    case navigation
}

// MARK: - Haptic Button Style

struct HapticButtonStyle: ButtonStyle {
    let hapticType: HapticFeedbackType
    
    init(hapticType: HapticFeedbackType = .buttonTap) {
        self.hapticType = hapticType
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed {
                    switch hapticType {
                    case .light:
                        HapticFeedbackService.shared.lightImpact()
                    case .medium:
                        HapticFeedbackService.shared.mediumImpact()
                    case .heavy:
                        HapticFeedbackService.shared.heavyImpact()
                    case .success:
                        HapticFeedbackService.shared.success()
                    case .warning:
                        HapticFeedbackService.shared.warning()
                    case .error:
                        HapticFeedbackService.shared.error()
                    case .selection:
                        HapticFeedbackService.shared.selectionChanged()
                    case .buttonTap:
                        HapticFeedbackService.shared.buttonTap()
                    case .navigation:
                        HapticFeedbackService.shared.navigation()
                    }
                }
            }
    }
}

// MARK: - Haptic Toggle Style

struct HapticToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            Spacer()
            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ? Color.blue : Color.gray.opacity(0.3))
                .frame(width: 50, height: 30)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 26, height: 26)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                    HapticFeedbackService.shared.toggleSwitch()
                }
        }
    }
}

// MARK: - Usage Examples in Comments

/*
 Usage Examples:
 
 // Basic button with haptic feedback
 Button("Submit") {
     // Action
 }
 .buttonStyle(HapticButtonStyle(hapticType: .success))
 
 // View with haptic feedback on tap
 Text("Tap me")
     .hapticFeedback(.medium)
 
 // Toggle with haptic feedback
 Toggle("Enable notifications", isOn: $isEnabled)
     .toggleStyle(HapticToggleStyle())
 
 // Haptic feedback on state change
 Text("Status: \(status)")
     .hapticFeedbackOnChange(of: status) { newStatus in
         newStatus == .success ? .success : .error
     }
 
 // Context-specific haptic feedback
 Button("Add Destination") {
     // Add destination logic
     HapticFeedbackService.shared.destinationAdded()
 }
 
 Button("Submit Trip") {
     // Submit trip logic
     HapticFeedbackService.shared.tripSubmitted()
 }
 */