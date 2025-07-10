import SwiftUI

struct SplashView: View {
    @State private var isLoading = true
    @State private var scale = 0.7
    @State private var opacity = 0.5
    
    var body: some View {
        ZStack {
            // Background gradient
            AppTheme.Colors.gradientHero
                .ignoresSafeArea()
            
            VStack(spacing: AppTheme.Spacing.xl) {
                // App logo/icon
                VStack(spacing: AppTheme.Spacing.lg) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "airplane.circle.fill")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .scaleEffect(scale)
                    .opacity(opacity)
                    
                    VStack(spacing: AppTheme.Spacing.sm) {
                        Text("WanderMint")
                            .font(AppTheme.Typography.hero)
                            .foregroundColor(.white)
                            .opacity(opacity)
                        
                        Text("Your personal travel planner")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(.white.opacity(0.9))
                            .opacity(opacity)
                    }
                }
                
                // Loading indicator
                if isLoading {
                    VStack(spacing: AppTheme.Spacing.md) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        
                        Text("Preparing your journey...")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .opacity(opacity)
                }
            }
        }
        .onAppear {
            withAnimation(AppTheme.Animation.spring.delay(0.1)) {
                scale = 1.0
                opacity = 1.0
            }
            
            // Simulate loading time
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(AppTheme.Animation.medium) {
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    SplashView()
}