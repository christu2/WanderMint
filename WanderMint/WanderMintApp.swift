import SwiftUI
import Firebase

@main
struct WanderMintApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @State private var showingSplash = true
    
    init() {
        FirebaseApp.configure()
        setupAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            if showingSplash {
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            withAnimation(AppTheme.Animation.medium) {
                                showingSplash = false
                            }
                        }
                    }
            } else {
                if authViewModel.isAuthenticated {
                    if authViewModel.needsOnboarding {
                        ProfileSetupView()
                            .environmentObject(authViewModel)
                    } else {
                        MainTabView()
                            .environmentObject(authViewModel)
                    }
                } else {
                    AuthenticationView()
                        .environmentObject(authViewModel)
                }
            }
        }
    }
    
    private func setupAppearance() {
        // Customize navigation bar appearance
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(AppTheme.Colors.backgroundPrimary)
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(AppTheme.Colors.textPrimary)]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(AppTheme.Colors.textPrimary)]
        
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance
        
        // Customize tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(AppTheme.Colors.backgroundPrimary)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}
