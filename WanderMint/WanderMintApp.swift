import SwiftUI
import Combine
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
        #if canImport(Firebase)
        configureFirebase()
        #endif
        setupAppearance()
        suppressKeyboardConstraintWarnings()
        _ = AppTheme.Animation.spring
    }
    
    private func suppressKeyboardConstraintWarnings() {
        #if DEBUG
        // Suppress known iOS keyboard constraint warnings
        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        #endif
    }
    
    private func configureFirebase() {
        #if canImport(Firebase)
        FirebaseApp.configure()
        setupFirebaseServices()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            rootView
                .onReceive(authViewModel.$isAuthenticated) { isAuthenticated in
                    if !isAuthenticated {
                        notificationService.stopListening()
                    }
                    updateAppState()
                }
                .onReceive(authViewModel.$needsOnboarding) { _ in
                    updateAppState()
                }
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
        DispatchQueue.main.async {
            if self.authViewModel.isAuthenticated {
                self.appState = self.authViewModel.needsOnboarding ? .onboarding : .main
            } else {
                self.appState = .authentication
            }
        }
    }
    
    private func setupFirebaseServices() {
        #if canImport(FirebaseAnalytics) && canImport(FirebaseCrashlytics)
        do {
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
            #endif
        } catch {
            // Silently handle Firebase setup errors
        }
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
