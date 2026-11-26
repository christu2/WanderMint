import SwiftUI
import UIKit
import Combine
import UserNotifications
#if canImport(Firebase)
import Firebase
#endif
#if canImport(FirebaseAnalytics)
import FirebaseAnalytics
#endif
#if canImport(FirebaseAppCheck)
import FirebaseAppCheck
#endif
#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics
#endif
#if canImport(FirebaseMessaging)
import FirebaseMessaging
#endif

#if canImport(FirebaseAppCheck)
/// Configures Firebase App Check: uses Debug provider on Simulator / Debug builds
/// and Apple App Attest (with DeviceCheck fallback) on Release physical devices.
final class WanderMintAppCheckProviderFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        #if DEBUG || targetEnvironment(simulator)
        return AppCheckDebugProvider(app: app)
        #else
        if #available(iOS 14.0, *) {
            return AppAttestProvider(app: app)
        }
        return DeviceCheckProvider(app: app)
        #endif
    }
}
#endif

/// Bridges UIKit APNs device-token callbacks and Firebase Cloud Messaging token updates into SwiftUI.
final class WanderMintAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        #if canImport(FirebaseMessaging)
        Messaging.messaging().delegate = self
        #endif
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        #if canImport(FirebaseMessaging)
        Messaging.messaging().apnsToken = deviceToken
        #endif
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Logger.warning("Remote notification registration failed: \(error.localizedDescription)", category: Logger.network)
    }
}

#if canImport(FirebaseMessaging)
extension WanderMintAppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken, !token.isEmpty else { return }
        Task { @MainActor in
            await NotificationService.shared.saveFCMToken(token)
        }
    }
}
#endif

@main
struct WanderMintApp: App {
    @UIApplicationDelegateAdaptor(WanderMintAppDelegate.self) private var appDelegate
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
        #if canImport(FirebaseAppCheck)
        AppCheck.setAppCheckProviderFactory(WanderMintAppCheckProviderFactory())
        #endif
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
