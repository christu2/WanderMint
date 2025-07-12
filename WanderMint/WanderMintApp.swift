import SwiftUI
#if canImport(Firebase)
import Firebase
#endif
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif
#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics
#endif

@main
struct WanderMintApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()
    @StateObject private var notificationService = NotificationService.shared
    @State private var appState: AppState = .splash

    init() {
        FirebaseApp.configure()
        setupFirebaseServices()
        setupAppearance()
        _ = AppTheme.Animation.spring
    }

    var body: some Scene {
        WindowGroup {
            rootView
        }
    }

    @ViewBuilder
    private var rootView: some View {
        switch appState {
        case .splash:
            SplashView {
                updateAppState()
            }

        case .onboarding:
            ProfileSetupView()
                .environmentObject(authViewModel)

        case .main:
            MainTabView()
                .environmentObject(authViewModel)
                .environmentObject(notificationService)
                .onAppear {
                    Task {
                        await notificationService.startListening()
                    }
                }
                .onDisappear {
                    notificationService.stopListening()
                }

        case .authentication:
            AuthenticationView()
                .environmentObject(authViewModel)
        }
    }

    private func updateAppState() {
        if authViewModel.isAuthenticated {
            appState = authViewModel.needsOnboarding ? .onboarding : .main
        } else {
            appState = .authentication
        }
    }
    
    private func setupFirebaseServices() {
        // Enable Analytics data collection
        Analytics.setAnalyticsCollectionEnabled(true)
        
        // Configure Crashlytics
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        
        // Set user properties for better analytics segmentation
        Analytics.setUserProperty(nil, forName: "app_version")
        Analytics.setUserProperty(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String, forName: "app_version")
        
        // Log app launch event
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: [
            AnalyticsParameterSource: "ios_app"
        ])
        
        #if DEBUG
        // Disable analytics in debug mode
        Analytics.setAnalyticsCollectionEnabled(false)
        print("🔥 Firebase Analytics disabled in DEBUG mode")
        #else
        print("🔥 Firebase Analytics and Crashlytics enabled for production")
        #endif
    }


    private func setupAppearance() {
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.configureWithOpaqueBackground()
        navBarAppearance.backgroundColor = UIColor(AppTheme.Colors.backgroundPrimary)
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(AppTheme.Colors.textPrimary)]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(AppTheme.Colors.textPrimary)]
        UINavigationBar.appearance().standardAppearance = navBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navBarAppearance

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(AppTheme.Colors.backgroundPrimary)
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}

private enum AppState {
    case splash
    case onboarding
    case main
    case authentication
}
