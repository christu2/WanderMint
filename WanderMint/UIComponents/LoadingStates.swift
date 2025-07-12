import SwiftUI

// MARK: - Enhanced Loading States

struct SmartLoadingView: View {
    let message: String
    let isIndeterminate: Bool
    let progress: Double?
    let estimatedTimeRemaining: TimeInterval?
    
    init(
        message: String = "Loading...",
        isIndeterminate: Bool = true,
        progress: Double? = nil,
        estimatedTimeRemaining: TimeInterval? = nil
    ) {
        self.message = message
        self.isIndeterminate = isIndeterminate
        self.progress = progress
        self.estimatedTimeRemaining = estimatedTimeRemaining
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Loading Animation
            if isIndeterminate {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.primary))
            } else if let progress = progress {
                CircularProgressView(progress: progress)
            }
            
            // Loading Message
            VStack(spacing: 8) {
                Text(message)
                    .font(AppTheme.Typography.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                if let timeRemaining = estimatedTimeRemaining {
                    Text("Estimated time: \(timeRemainingText(timeRemaining))")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                if !isIndeterminate, let progress = progress {
                    Text("\(Int(progress * 100))% complete")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.backgroundPrimary)
    }
    
    private func timeRemainingText(_ time: TimeInterval) -> String {
        if time < 60 {
            return "\(Int(time)) seconds"
        } else {
            let minutes = Int(time / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }
}

struct CircularProgressView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(AppTheme.Colors.primary.opacity(0.3), lineWidth: 8)
                .frame(width: 60, height: 60)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(AppTheme.Colors.primary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.3), value: progress)
        }
    }
}

// MARK: - Contextual Loading States

struct TripSubmissionLoadingView: View {
    @State private var currentStage = 0
    @State private var timer: Timer?
    
    private let stages = [
        "Validating your request...",
        "Finding the best options...",
        "Creating your itinerary...",
        "Almost ready!"
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated Icon
            LottieAnimationView()
            
            // Stage Progress
            VStack(spacing: 12) {
                Text(stages[currentStage])
                    .font(AppTheme.Typography.h3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                // Progress Dots
                HStack(spacing: 8) {
                    ForEach(0..<stages.count, id: \.self) { index in
                        Circle()
                            .fill(index <= currentStage ? AppTheme.Colors.primary : AppTheme.Colors.primary.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentStage ? 1.2 : 1.0)
                            .animation(.spring(response: 0.3), value: currentStage)
                    }
                }
            }
            
            Text("This usually takes 30-60 seconds")
                .font(AppTheme.Typography.caption)
                .foregroundColor(AppTheme.Colors.textSecondary)
        }
        .padding(32)
        .background(AppTheme.Colors.backgroundPrimary)
        .onAppear {
            startStageTimer()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
    
    private func startStageTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.spring(response: 0.5)) {
                if currentStage < stages.count - 1 {
                    currentStage += 1
                } else {
                    currentStage = 0
                }
            }
        }
    }
}

struct LottieAnimationView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Placeholder animation using SwiftUI
            Circle()
                .stroke(AppTheme.Colors.primary.opacity(0.3), lineWidth: 4)
                .frame(width: 80, height: 80)
            
            Circle()
                .trim(from: 0, to: 0.8)
                .stroke(AppTheme.Colors.primary, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isAnimating)
            
            Image(systemName: "airplane")
                .font(.system(size: 24))
                .foregroundColor(AppTheme.Colors.primary)
                .rotationEffect(.degrees(isAnimating ? 15 : -15))
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Empty States

struct SmartEmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        title: String,
        message: String,
        systemImage: String = "tray",
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: systemImage)
                .font(.system(size: 60))
                .foregroundColor(AppTheme.Colors.primary.opacity(0.6))
            
            // Content
            VStack(spacing: 12) {
                Text(title)
                    .font(AppTheme.Typography.h2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Text(message)
                    .font(AppTheme.Typography.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding(.horizontal, 32)
            }
            
            // Action Button
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(actionTitle)
                    }
                    .font(AppTheme.Typography.button)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppTheme.Colors.gradientSecondary)
                    .cornerRadius(AppTheme.CornerRadius.lg)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.Colors.backgroundPrimary)
    }
}

// MARK: - Enhanced Loading Overlay

struct EnhancedLoadingOverlay: View {
    let message: String
    let showProgress: Bool
    let progress: Double
    
    init(message: String = "Loading...", showProgress: Bool = false, progress: Double = 0.0) {
        self.message = message
        self.showProgress = showProgress
        self.progress = progress
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                if showProgress {
                    CircularProgressView(progress: progress)
                } else {
                    ProgressView()
                        .scaleEffect(1.2)
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.Colors.primary))
                }
                
                Text(message)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
            .background(AppTheme.Colors.backgroundPrimary)
            .cornerRadius(AppTheme.CornerRadius.xl)
            .shadow(radius: 20)
        }
    }
}

// MARK: - Skeleton Loading

struct SkeletonView: View {
    @State private var isAnimating = false
    
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(height: CGFloat = 20, cornerRadius: CGFloat = 4) {
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.gray.opacity(0.3),
                        Color.gray.opacity(0.1),
                        Color.gray.opacity(0.3)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: height)
            .cornerRadius(cornerRadius)
            .offset(x: isAnimating ? UIScreen.main.bounds.width : -UIScreen.main.bounds.width)
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

struct SkeletonTripCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SkeletonView(height: 24, cornerRadius: 6)
                    .frame(maxWidth: 200)
                Spacer()
                SkeletonView(height: 20, cornerRadius: 10)
                    .frame(width: 80)
            }
            
            SkeletonView(height: 16, cornerRadius: 4)
                .frame(maxWidth: 150)
            
            SkeletonView(height: 16, cornerRadius: 4)
                .frame(maxWidth: 100)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(AppTheme.CornerRadius.lg)
        .shadow(radius: 2)
    }
}

// MARK: - View Extensions

extension View {
    func enhancedLoadingOverlay(isLoading: Bool, message: String = "Loading...") -> some View {
        self.overlay(
            Group {
                if isLoading {
                    EnhancedLoadingOverlay(message: message)
                }
            }
        )
    }
    
    func skeleton(isLoading: Bool, height: CGFloat = 20) -> some View {
        self.overlay(
            Group {
                if isLoading {
                    SkeletonView(height: height)
                }
            }
        )
        .opacity(isLoading ? 0 : 1)
    }
}