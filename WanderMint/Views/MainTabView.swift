import SwiftUI
import StoreKit

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @EnvironmentObject var notificationService: NotificationService
    @State private var selectedTab = 1 // Default to "My Trips" tab
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TripSubmissionView(selectedTab: $selectedTab)
            }
            .tabItem {
                Image(systemName: "plus.circle.fill")
                Text("New Trip")
            }
            .tag(0)
            .accessibilityHint("Create a new trip request")
            
            NavigationStack {
                TripsListView(selectedTab: $selectedTab)
            }
            .tabItem {
                Image(systemName: "list.bullet.rectangle.fill")
                Text("My Trips")
            }
            .tag(1)
            .accessibilityHint("View your planned trips")
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
                .tag(2)
                .accessibilityHint("Manage your profile and settings")
        }
        .accentColor(AppTheme.Colors.primary)
        .onReceive(notificationService.$pendingTripId) { tripId in
            if tripId != nil {
                // Switch to trips tab and navigate to specific trip
                selectedTab = 1
                // The TripsListView will handle navigation to the specific trip
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    notificationService.clearPendingNavigation()
                }
            }
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingPointsView = false
    @State private var showingEditProfile = false
    @State private var editingName = ""
    @State private var showingTravelHistory = false
    @State private var showingNotifications = false
    @State private var showingPrivacySecurity = false
    @State private var showingHelpSupport = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [AppTheme.Colors.backgroundPrimary, AppTheme.Colors.primaryLight],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.xl) {
                        // Header Section
                        headerSection
                        
                        // User Info Card
                        userInfoCard
                        
                        // Quick Actions
                        quickActionsSection
                        
                        // Settings Section
                        settingsSection
                        
                        Spacer(minLength: AppTheme.Spacing.xxl)
                        
                        // Sign Out Button
                        signOutButton
                    }
                    .padding(AppTheme.Spacing.lg)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingPointsView) {
                PointsManagementView()
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(name: $editingName, onSave: {
                    Task {
                        await authViewModel.updateUserProfile(name: editingName)
                        showingEditProfile = false
                    }
                })
            }
            .sheet(isPresented: $showingTravelHistory) {
                TravelHistoryView()
            }
            .sheet(isPresented: $showingNotifications) {
                NotificationSettingsView()
            }
            .sheet(isPresented: $showingPrivacySecurity) {
                PrivacySecurityView()
                    .environmentObject(authViewModel)
            }
            .sheet(isPresented: $showingHelpSupport) {
                HelpSupportView()
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(AppTheme.Colors.primary)
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Profile")
                        .font(AppTheme.Typography.h1)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text("Manage your travel preferences")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
            }
        }
    }
    
    private var userInfoCard: some View {
        VStack(spacing: AppTheme.Spacing.lg) {
            HStack {
                ZStack {
                    Circle()
                        .fill(AppTheme.Colors.gradientPrimary)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    if let userProfile = authViewModel.userProfile, !userProfile.name.isEmpty {
                        Text("Welcome Back, \(userProfile.name)!")
                            .font(AppTheme.Typography.h3)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    } else {
                        Text("Welcome Back!")
                            .font(AppTheme.Typography.h3)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                    }
                    
                    if let user = authViewModel.currentUser {
                        Text(user.email ?? "No email")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }
                    
                    Text("Travel Enthusiast")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.primary)
                }
                
                Spacer()
            }
        }
        .padding(AppTheme.Spacing.lg)
        .background(Color.white)
        .cornerRadius(AppTheme.CornerRadius.lg)
        .applyShadow(AppTheme.Shadows.cardShadow)
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Quick Actions")
                    .font(AppTheme.Typography.h3)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Spacer()
            }
            
            VStack(spacing: AppTheme.Spacing.sm) {
                ProfileActionCard(
                    icon: "creditcard.fill",
                    title: "Points & Miles",
                    subtitle: "Track your rewards",
                    color: AppTheme.Colors.secondary
                ) {
                    showingPointsView = true
                }
                
                ProfileActionCard(
                    icon: "airplane.departure",
                    title: "Travel History",
                    subtitle: "View past trips",
                    color: AppTheme.Colors.accent
                ) {
                    showingTravelHistory = true
                }
                
                ProfileActionCard(
                    icon: "person.circle.fill",
                    title: "Edit Profile",
                    subtitle: "Update your information",
                    color: AppTheme.Colors.primary
                ) {
                    editingName = authViewModel.userProfile?.name ?? ""
                    showingEditProfile = true
                }
            }
        }
    }
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                Text("Settings")
                    .font(AppTheme.Typography.h3)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                Spacer()
            }
            
            VStack(spacing: AppTheme.Spacing.sm) {
                SettingsRow(icon: "bell.fill", title: "Notifications", color: AppTheme.Colors.warning) {
                    showingNotifications = true
                }
                
                SettingsRow(icon: "lock.fill", title: "Privacy & Security", color: AppTheme.Colors.primary) {
                    showingPrivacySecurity = true
                }
                
                SettingsRow(icon: "questionmark.circle.fill", title: "Help & Support", color: AppTheme.Colors.info) {
                    showingHelpSupport = true
                }
                
                SettingsRow(icon: "star.fill", title: "Rate the App", color: AppTheme.Colors.secondary) {
                    rateTheApp()
                }
            }
            .padding(AppTheme.Spacing.lg)
            .background(Color.white)
            .cornerRadius(AppTheme.CornerRadius.lg)
            .applyShadow(AppTheme.Shadows.cardShadow)
        }
    }
    
    private var signOutButton: some View {
        Button(action: {
            authViewModel.signOut()
        }) {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Sign Out")
            }
            .font(AppTheme.Typography.button)
            .foregroundColor(AppTheme.Colors.error)
            .frame(minHeight: 44)
            .frame(maxWidth: .infinity)
            .background(AppTheme.Colors.error.opacity(0.1))
            .cornerRadius(AppTheme.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                    .stroke(AppTheme.Colors.error, lineWidth: 1)
            )
        }
    }
    
    private func rateTheApp() {
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        } else if let url = AppConfig.App.appStoreURL {
            UIApplication.shared.open(url)
        }
    }
}

struct ProfileActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text(title)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Text(subtitle)
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            .padding(AppTheme.Spacing.lg)
            .background(Color.white)
            .cornerRadius(AppTheme.CornerRadius.md)
            .applyShadow(Shadow(color: AppTheme.Shadows.light, radius: 2, x: 0, y: 1))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    init(icon: String, title: String, color: Color, action: @escaping () -> Void = {}) {
        self.icon = icon
        self.title = title
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(AppTheme.Colors.textPrimary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            .padding(.vertical, AppTheme.Spacing.sm)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EditProfileView: View {
    @Binding var name: String
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        let nameField = TextField("Enter your name", text: $name)
            .font(AppTheme.Typography.body)
            .padding(AppTheme.Spacing.md)
            .background(Color.white)
            .cornerRadius(AppTheme.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                    .stroke(AppTheme.Colors.surfaceBorder, lineWidth: 1)
            )
        
        let nameSection = VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Text("Your Name")
                .font(AppTheme.Typography.body)
                .foregroundColor(AppTheme.Colors.textPrimary)
            
            nameField
        }
        
        let cancelButton = Button("Cancel") {
            dismiss()
        }
        
        let saveButton = Button("Save") {
            onSave()
        }
        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        
        return NavigationStack {
            VStack(spacing: AppTheme.Spacing.lg) {
                nameSection
                Spacer()
            }
            .padding(AppTheme.Spacing.lg)
            .background(AppTheme.Colors.backgroundSecondary)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: cancelButton, trailing: saveButton)
        }
    }
}

// MARK: - Profile Detail & Settings Views

struct TravelHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var completedTrips: [TravelTrip] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    LoadingView(message: "Loading travel history...")
                } else if let errorMessage = errorMessage {
                    ErrorView(
                        title: "Unable to Load History",
                        message: errorMessage,
                        retryAction: { Task { await loadCompletedTrips() } }
                    )
                } else if completedTrips.isEmpty {
                    VStack(spacing: AppTheme.Spacing.lg) {
                        Image(systemName: "airplane.departure")
                            .font(.system(size: 60))
                            .foregroundColor(AppTheme.Colors.accent)

                        Text("No Completed Trips Yet")
                            .font(AppTheme.Typography.h2)
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Text("Your completed itineraries will appear here once your travel consultant finalizes your trip.")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Spacer()
                    }
                    .padding(.top, AppTheme.Spacing.xxl)
                    .padding(.horizontal)
                } else {
                    ScrollView {
                        LazyVStack(spacing: AppTheme.Spacing.md) {
                            ForEach(completedTrips) { trip in
                                NavigationLink(destination: TripDetailView(initialTrip: trip)) {
                                    EnhancedTripCard(trip: trip, canDelete: false)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(AppTheme.Spacing.lg)
                    }
                }
            }
            .navigationTitle("Travel History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await loadCompletedTrips()
            }
        }
    }

    private func loadCompletedTrips() async {
        isLoading = true
        errorMessage = nil
        do {
            let allTrips = try await TripService().fetchUserTrips()
            completedTrips = allTrips.filter { $0.status == .completed }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

struct NotificationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("notif_trip_updates") private var tripUpdates = true
    @AppStorage("notif_email_updates") private var emailUpdates = true

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Trip Notifications")) {
                    Toggle("Itinerary Ready Alerts", isOn: $tripUpdates)
                        .onChange(of: tripUpdates) { newValue in
                            Task {
                                await NotificationService.shared.updatePushPreference(enabled: newValue)
                            }
                        }
                    Toggle("Email Updates", isOn: $emailUpdates)
                    Text("Get notified when your travel consultant completes or updates your itinerary.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("System Settings")) {
                    Button(action: openSystemNotificationSettings) {
                        HStack {
                            Label("Manage iOS Notification Settings", systemImage: "gear")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func openSystemNotificationSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

struct PrivacySecurityView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingDeleteConfirmation = false
    @State private var showingFinalDeleteAlert = false
    @State private var isDeleting = false
    @State private var deleteErrorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Data Protection")
                            .font(AppTheme.Typography.h3)
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Text("Your personal information is encrypted in transit and stored securely in Google Cloud Firestore. We never sell your data or share it with third-party advertisers.")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Account Security")
                            .font(AppTheme.Typography.h3)
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        Text("Your account is protected by Firebase Authentication with industry-standard security practices.")
                            .font(AppTheme.Typography.body)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                    }

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
                        Text("Legal")
                            .font(AppTheme.Typography.h3)
                            .foregroundColor(AppTheme.Colors.textPrimary)

                        if let privacyURL = URL(string: AppConfig.Support.privacyPolicyURL) {
                            Link(destination: privacyURL) {
                                HStack {
                                    Text("View Privacy Policy")
                                        .font(AppTheme.Typography.button)
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                }
                                .foregroundColor(AppTheme.Colors.primary)
                                .padding(.vertical, AppTheme.Spacing.xs)
                            }
                        }

                        if let termsURL = URL(string: AppConfig.Support.termsOfServiceURL) {
                            Link(destination: termsURL) {
                                HStack {
                                    Text("Terms of Service")
                                        .font(AppTheme.Typography.button)
                                    Spacer()
                                    Image(systemName: "arrow.up.right.square")
                                }
                                .foregroundColor(AppTheme.Colors.primary)
                                .padding(.vertical, AppTheme.Spacing.xs)
                            }
                        }
                    }

                    Divider()
                        .padding(.vertical, AppTheme.Spacing.sm)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Delete Account")
                            .font(AppTheme.Typography.h3)
                            .foregroundColor(AppTheme.Colors.error)

                        Text("Permanently delete your WanderMint account and all associated data, including your profile, points balances, trips, and messages. This action cannot be undone.")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)

                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            HStack {
                                if isDeleting {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "trash.fill")
                                }
                                Text(isDeleting ? "Deleting Account..." : "Delete Account")
                            }
                            .font(AppTheme.Typography.button)
                            .foregroundColor(.white)
                            .frame(minHeight: 44)
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.Colors.error)
                            .cornerRadius(AppTheme.CornerRadius.md)
                        }
                        .disabled(isDeleting)
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Privacy & Security")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .disabled(isDeleting)
                }
            }
            .alert("Delete Your Account?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Continue", role: .destructive) {
                    showingFinalDeleteAlert = true
                }
            } message: {
                Text("This will permanently remove your profile, points & miles data, all trips, and consultant messages.")
            }
            .alert("Confirm Permanent Deletion", isPresented: $showingFinalDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Permanently", role: .destructive) {
                    Task {
                        isDeleting = true
                        let deleted = await authViewModel.deleteAccount()
                        isDeleting = false
                        if deleted {
                            dismiss()
                        } else {
                            deleteErrorMessage = authViewModel.errorMessage ?? "Unable to delete account. Please try again or contact \(AppConfig.Support.email)."
                        }
                    }
                }
            } message: {
                Text("Are you absolutely sure? Your WanderMint account and all data will be permanently deleted and cannot be recovered.")
            }
            .alert("Account Deletion Failed", isPresented: .constant(deleteErrorMessage != nil)) {
                Button("OK") { deleteErrorMessage = nil }
            } message: {
                Text(deleteErrorMessage ?? "")
            }
        }
    }
}

struct HelpSupportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingEmailAlert = false
    @State private var emailError: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Frequently Asked Questions")
                            .font(AppTheme.Typography.h3)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        VStack(spacing: AppTheme.Spacing.sm) {
                            FAQItem(question: "How do I submit a trip request?", answer: "Tap the 'New Trip' tab and fill out the form with your travel preferences.")
                            FAQItem(question: "How long does trip planning take?", answer: "Our travel consultants typically complete your itinerary within 24-48 hours.")
                            FAQItem(question: "Can I modify my trip after submission?", answer: "Yes, you can communicate with your consultant through the conversation feature.")
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
                        Text("Contact Support")
                            .font(AppTheme.Typography.h3)
                            .foregroundColor(AppTheme.Colors.textPrimary)
                        
                        Button(action: {
                            sendSupportEmail()
                        }) {
                            Text("Email Support")
                                .font(AppTheme.Typography.button)
                                .foregroundColor(AppTheme.Colors.primary)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Help & Support")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(leading: Button("Close") { dismiss() })
            .alert("Email Support", isPresented: $showingEmailAlert) {
                Button("OK") { }
            } message: {
                Text(emailError ?? "Unable to open email client. Please contact us at \(AppConfig.Support.email)")
            }
        }
    }
    
    private func sendSupportEmail() {
        let email = AppConfig.Support.email
        let subject = "WanderMint Support Request"
        let body = """
        
        
        ---
        App Version: \(AppConfig.App.version)
        Build: \(AppConfig.App.build)
        Device: \(UIDevice.current.model)
        iOS Version: \(UIDevice.current.systemVersion)
        """
        
        // Try different email URL formats
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? body
        
        let mailtoUrls = [
            "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)",
            "mailto:\(email)?subject=\(encodedSubject)",
            "mailto:\(email)"
        ]
        
        var emailOpened = false
        
        for urlString in mailtoUrls {
            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url) { success in
                    if !success {
                        emailError = "Unable to open email client. Please email us directly at \(email)"
                        showingEmailAlert = true
                    }
                }
                emailOpened = true
                break
            }
        }
        
        if !emailOpened {
            emailError = "No email client found. Please email us at \(email)"
            showingEmailAlert = true
        }
    }
}

struct FAQItem: View {
    let question: String
    let answer: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text(question)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Text(answer)
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .padding(.leading, AppTheme.Spacing.sm)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(Color.white)
        .cornerRadius(AppTheme.CornerRadius.md)
        .applyShadow(Shadow(color: AppTheme.Shadows.light, radius: 1, x: 0, y: 1))
    }
}
