import SwiftUI
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

struct ProfileSetupView: View {
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var name = ""
    @State private var showingPointsSetup = false
    @State private var isSubmitting = false
    @State private var currentStep = 0
    
    // Points data
    @State private var creditCardPoints: [String: Int] = [:]
    @State private var hotelPoints: [String: Int] = [:]
    @State private var airlinePoints: [String: Int] = [:]
    
    @State private var selectedCreditCards: Set<String> = []
    @State private var selectedHotels: Set<String> = []
    @State private var selectedAirlines: Set<String> = []
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.Colors.backgroundPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Progress indicator
                    progressView
                    
                    // Content
                    TabView(selection: $currentStep) {
                        welcomeStepView
                            .tag(0)
                        
                        nameStepView
                            .tag(1)
                        
                        pointsStepView
                            .tag(2)
                        
                        completionStepView
                            .tag(3)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    
                    // Navigation buttons
                    navigationButtons
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // Pre-populate name if available
            if let userProfile = authViewModel.userProfile, !userProfile.name.isEmpty {
                name = userProfile.name
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()
                Button("Skip") {
                    completeOnboarding()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppTheme.Colors.primary)
                .opacity(currentStep == 0 ? 0 : 1)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            Text("Welcome to WanderMint!")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppTheme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .padding(.bottom, 20)
    }
    
    private var progressView: some View {
        HStack(spacing: 8) {
            ForEach(0..<4) { index in
                Rectangle()
                    .fill(index <= currentStep ? AppTheme.Colors.primary : Color.gray.opacity(0.3))
                    .frame(height: 4)
                    .cornerRadius(2)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
        .accessibilityLabel("Step \(currentStep + 1) of 4")
        .accessibilityHint("Onboarding progress indicator")
    }
    
    private var welcomeStepView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Image(systemName: "airplane.departure")
                    .font(.system(size: 80))
                    .foregroundColor(AppTheme.Colors.primary)
                
                Text("Let's personalize your experience")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("We'll help you get the most value from your points and miles by setting up your profile.")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    private var nameStepView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppTheme.Colors.primary)
                
                Text("What should we call you?")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Your name helps us personalize your travel recommendations.")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            VStack(spacing: 16) {
                TextField("Enter your name", text: $name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 16))
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 24)
                    .accessibilityLabel("Name input field")
                    .accessibilityHint("Enter your full name for personalized travel recommendations")
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    private var pointsStepView: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.Colors.primary)
                    
                    Text("Add your points & miles")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Tell us about your points and miles so we can find the best redemption opportunities.")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                
                VStack(spacing: 20) {
                    // Credit Cards
                    pointsSectionView(
                        title: "Credit Card Points",
                        providers: PointsProvider.creditCardProviders,
                        selectedProviders: $selectedCreditCards,
                        pointsData: $creditCardPoints,
                        icon: "creditcard.fill"
                    )
                    
                    // Hotels
                    pointsSectionView(
                        title: "Hotel Points",
                        providers: PointsProvider.hotelProviders,
                        selectedProviders: $selectedHotels,
                        pointsData: $hotelPoints,
                        icon: "building.2.fill"
                    )
                    
                    // Airlines
                    pointsSectionView(
                        title: "Airline Miles",
                        providers: PointsProvider.airlineProviders,
                        selectedProviders: $selectedAirlines,
                        pointsData: $airlinePoints,
                        icon: "airplane.fill"
                    )
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var completionStepView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                Text("You're all set!")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Welcome to WanderMint! Start planning your next adventure.")
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
    
    private var navigationButtons: some View {
        HStack {
            if currentStep > 0 {
                Button("Back") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep -= 1
                    }
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppTheme.Colors.primary)
                .frame(maxWidth: .infinity)
            }
            
            Spacer()
            
            Button(currentStep == 3 ? "Get Started" : "Continue") {
                handleContinue()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(AppTheme.Colors.primary)
            .cornerRadius(12)
            .disabled(isSubmitting || (currentStep == 1 && name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty))
            .opacity(isSubmitting ? 0.6 : 1)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
    }
    
    private func pointsSectionView(
        title: String,
        providers: [String],
        selectedProviders: Binding<Set<String>>,
        pointsData: Binding<[String: Int]>,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.Colors.primary)
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.textPrimary)
            }
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
                ForEach(providers, id: \.self) { provider in
                    VStack(spacing: 8) {
                        HStack {
                            Button(action: {
                                if selectedProviders.wrappedValue.contains(provider) {
                                    selectedProviders.wrappedValue.remove(provider)
                                    pointsData.wrappedValue.removeValue(forKey: provider)
                                } else {
                                    selectedProviders.wrappedValue.insert(provider)
                                    pointsData.wrappedValue[provider] = 0
                                }
                            }) {
                                HStack {
                                    Image(systemName: selectedProviders.wrappedValue.contains(provider) ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(selectedProviders.wrappedValue.contains(provider) ? AppTheme.Colors.primary : .gray)
                                    
                                    Text(provider)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                    
                                    Spacer()
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        if selectedProviders.wrappedValue.contains(provider) {
                            TextField("Points", value: Binding(
                                get: { pointsData.wrappedValue[provider] ?? 0 },
                                set: { pointsData.wrappedValue[provider] = $0 }
                            ), format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .font(.system(size: 14))
                        }
                    }
                    .padding(12)
                    .background(AppTheme.Colors.backgroundSecondary)
                    .cornerRadius(12)
                }
            }
        }
    }
    
    private func handleContinue() {
        switch currentStep {
        case 0:
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = 1
            }
        case 1:
            if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentStep = 2
                }
            }
        case 2:
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = 3
            }
        case 3:
            completeOnboarding()
        default:
            break
        }
    }
    
    private func completeOnboarding() {
        isSubmitting = true
        
        Task {
            do {
                // Update user profile with name
                if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    await authViewModel.updateUserProfile(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
                }
                
                // Save points data if any
                if !creditCardPoints.isEmpty || !hotelPoints.isEmpty || !airlinePoints.isEmpty {
                    try await savePointsData()
                }
                
                // Track onboarding completion
                let hasPointsData = !creditCardPoints.isEmpty || !hotelPoints.isEmpty || !airlinePoints.isEmpty
                AnalyticsService.shared.trackOnboardingCompleted(hasPointsData: hasPointsData)
                
                // Mark onboarding as complete
                await authViewModel.completeOnboarding()
                
            } catch {
                // Handle error - for now just continue
                print("Error during onboarding: \(error)")
            }
            
            await MainActor.run {
                isSubmitting = false
            }
        }
    }
    
    private func savePointsData() async throws {
        guard let user = authViewModel.currentUser else { return }
        
        let pointsProfile = UserPointsProfile(
            userId: user.uid,
            creditCardPoints: creditCardPoints,
            hotelPoints: hotelPoints,
            airlinePoints: airlinePoints,
            lastUpdated: createTimestamp()
        )
        
        let db = Firestore.firestore()
        let data = try JSONEncoder().encode(pointsProfile)
        
        guard let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw TravelAppError.dataError("Failed to serialize points profile")
        }
        
        try await db.collection("userPoints").document(user.uid).setData(dict)
    }
    
}

#Preview {
    ProfileSetupView()
        .environmentObject(AuthenticationViewModel())
}