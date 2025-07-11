import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var selectedTab = 1 // Default to "My Trips" tab
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TripSubmissionView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("New Trip")
                }
                .tag(0)
            
            TripsListView(selectedTab: $selectedTab)
                .tabItem {
                    Image(systemName: "list.bullet.rectangle.fill")
                    Text("My Trips")
                }
                .tag(1)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle.fill")
                    Text("Profile")
                }
                .tag(2)
        }
        .accentColor(AppTheme.Colors.primary)
    }
}

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingPointsView = false
    @State private var showingEditProfile = false
    @State private var editingName = ""
    
    var body: some View {
        NavigationView {
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
                    // Navigate to travel history
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
                SettingsRow(icon: "bell.fill", title: "Notifications", color: AppTheme.Colors.warning)
                
                SettingsRow(icon: "lock.fill", title: "Privacy & Security", color: AppTheme.Colors.primary)
                SettingsRow(icon: "questionmark.circle.fill", title: "Help & Support", color: AppTheme.Colors.info)
                SettingsRow(icon: "star.fill", title: "Rate the App", color: AppTheme.Colors.secondary)
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
    
    var body: some View {
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
        
        return NavigationView {
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
