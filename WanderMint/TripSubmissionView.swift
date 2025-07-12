import SwiftUI

// MARK: - Interest Button Component (defined first)
struct InterestButton: View {
    let interest: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(interest)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, AppTheme.Spacing.md)
                .padding(.vertical, AppTheme.Spacing.md)
                .frame(minHeight: 44)
                .background(
                    isSelected ? 
                    AppTheme.Colors.gradientPrimary : 
                    LinearGradient(colors: [AppTheme.Colors.backgroundSecondary], startPoint: .top, endPoint: .bottom)
                )
                .foregroundColor(isSelected ? .white : AppTheme.Colors.textPrimary)
                .cornerRadius(AppTheme.CornerRadius.md)
                .applyShadow(isSelected ? AppTheme.Shadows.cardShadow : Shadow(color: .clear, radius: 0, x: 0, y: 0))
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(interest)
        .accessibilityHint(isSelected ? "Selected. Double tap to deselect" : "Not selected. Double tap to select")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Main Trip Submission View
struct TripSubmissionView: View {
    @StateObject private var viewModel = TripSubmissionViewModel()
    @State private var destinations: [String] = [""]
    @State private var departureLocation = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days from now
    @State private var flexibleDates = false
    
    // Flexible dates fields
    @State private var earliestStartDate = Date()
    @State private var latestStartDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var tripDuration = 7 // days
    
    // New preference fields
    @State private var budget = ""
    @State private var travelStyle = "Comfortable"
    @State private var groupSize = 1
    @State private var specialRequests = ""
    @State private var selectedInterests: Set<String> = []
    
    let travelStyles = ["Budget", "Comfortable", "Luxury", "Adventure", "Relaxation"]
    let interests = ["Culture", "Food", "Nature", "History", "Nightlife", "Shopping", "Adventure Sports", "Art", "Music", "Architecture"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [AppTheme.Colors.backgroundPrimary, AppTheme.Colors.secondaryLight],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Hero Section
                        heroSection
                        
                        // Form Content
                        VStack(spacing: AppTheme.Spacing.lg) {
                            destinationSection
                            preferencesSection
                            interestsSection
                            specialRequestsSection
                            submitSection
                        }
                        .padding(AppTheme.Spacing.lg)
                    }
                }
            }
            .navigationBarHidden(true)
            .disabled(viewModel.isLoading)
            .overlay(
                Group {
                    if viewModel.isLoading {
                        TripSubmissionLoadingView()
                    }
                }
            )
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("Try Again") {
                    viewModel.clearError()
                    if isFormValid {
                        submitTrip()
                    }
                }
                Button("Cancel", role: .cancel) {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("Success", isPresented: .constant(viewModel.submissionSuccess)) {
                Button("OK") {
                    viewModel.clearSuccess()
                    clearForm()
                }
            } message: {
                Text("Your trip request has been submitted! I'll personally plan your perfect itinerary and you'll be notified when it's ready.")
            }
            .onAppear {
                AnalyticsService.shared.trackScreenView(AnalyticsService.ScreenNames.tripSubmission)
            }
            .errorRecovery(
                error: $viewModel.currentError,
                context: .tripSubmission,
                onAction: handleRecoveryAction
            )
        }
    }
    
    private var heroSection: some View {
        ZStack {
            AppTheme.Colors.gradientHero
            
            VStack(spacing: AppTheme.Spacing.lg) {
                VStack(spacing: AppTheme.Spacing.sm) {
                    Image(systemName: "airplane.departure")
                        .font(.system(size: 60, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text("Plan Your Dream Trip")
                        .font(AppTheme.Typography.h1)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Tell us where you want to go and we'll create the perfect itinerary just for you")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, AppTheme.Spacing.lg)
                }
            }
            .padding(.vertical, AppTheme.Spacing.xxl)
        }
        .frame(minHeight: 200)
    }
    
    private var destinationSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            HStack {
                sectionHeader("Where To?", icon: "location.fill")
                Spacer()
                if destinations.count < 10 { // Limit to 10 destinations
                    Button(action: addDestination) {
                        HStack(spacing: AppTheme.Spacing.xs) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Stop")
                        }
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.primary)
                    }
                    .accessibilityLabel("Add destination")
                    .accessibilityHint("Add another destination to your trip")
                }
            }
            
            VStack(spacing: AppTheme.Spacing.md) {
                // Departure location field
                VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                    Text("Departure Location")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    TextField("Where are you departing from?", text: $departureLocation)
                        .textInputAutocapitalization(.words)
                        .padding(AppTheme.Spacing.md)
                        .background(Color.white)
                        .cornerRadius(AppTheme.CornerRadius.md)
                        .applyShadow(Shadow(color: AppTheme.Shadows.light, radius: 2, x: 0, y: 1))
                        .accessibilityLabel("Departure location")
                        .accessibilityHint("Enter your departure city or airport")
                }
                
                // Multiple destination fields
                ForEach(Array(destinations.enumerated()), id: \.offset) { index, destination in
                    HStack(spacing: AppTheme.Spacing.sm) {
                        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                            if destinations.count > 1 {
                                Text("Destination \(index + 1)")
                                    .font(AppTheme.Typography.bodySmall)
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                            }
                            
                            TextField(index == 0 ? "Enter your dream destination" : "Add another destination", 
                                    text: Binding(
                                        get: { destinations[index] },
                                        set: { destinations[index] = $0 }
                                    ))
                                .textInputAutocapitalization(.words)
                                .padding(AppTheme.Spacing.md)
                                .background(Color.white)
                                .cornerRadius(AppTheme.CornerRadius.md)
                                .applyShadow(Shadow(color: AppTheme.Shadows.light, radius: 2, x: 0, y: 1))
                                .accessibilityLabel("Destination \(index + 1)")
                                .accessibilityHint("Enter travel destination")
                        }
                        
                        if destinations.count > 1 {
                            Button(action: {
                                removeDestination(at: index)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppTheme.Colors.error)
                            }
                            .padding(.top, destinations.count > 1 ? AppTheme.Spacing.lg : 0)
                            .accessibilityLabel("Remove destination \(index + 1)")
                            .accessibilityHint("Remove this destination from your trip")
                        }
                    }
                }
                
                Toggle("I have flexible dates", isOn: $flexibleDates)
                    .toggleStyle(SwitchToggleStyle(tint: AppTheme.Colors.primary))
                    .padding(AppTheme.Spacing.md)
                    .background(Color.white)
                    .accessibilityLabel("Flexible dates")
                    .accessibilityHint("Toggle flexible travel dates option")
                    .cornerRadius(AppTheme.CornerRadius.md)
                    .applyShadow(Shadow(color: AppTheme.Shadows.light, radius: 2, x: 0, y: 1))
                
                if flexibleDates {
                    flexibleDatesView
                } else {
                    fixedDatesView
                }
            }
        }
    }
    
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionHeader("Your Preferences", icon: "heart.fill")
            
            VStack(spacing: AppTheme.Spacing.md) {
                HStack(spacing: AppTheme.Spacing.md) {
                    VStack(alignment: .leading) {
                        Text("Budget")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        TextField("Optional", text: $budget)
                            .keyboardType(.numberPad)
                            .padding(AppTheme.Spacing.md)
                            .background(Color.white)
                            .cornerRadius(AppTheme.CornerRadius.md)
                            .applyShadow(Shadow(color: AppTheme.Shadows.light, radius: 2, x: 0, y: 1))
                            .accessibilityLabel("Trip budget")
                            .accessibilityHint("Enter your estimated trip budget")
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Group Size")
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                        Stepper("\(groupSize)", value: $groupSize, in: 1...20)
                            .padding(AppTheme.Spacing.md)
                            .background(Color.white)
                            .cornerRadius(AppTheme.CornerRadius.md)
                            .applyShadow(Shadow(color: AppTheme.Shadows.light, radius: 2, x: 0, y: 1))
                            .accessibilityLabel("Group size: \(groupSize) people")
                            .accessibilityHint("Adjust number of travelers")
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Travel Style")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                    
                    Menu {
                        ForEach(travelStyles, id: \.self) { style in
                            Button(style) {
                                travelStyle = style
                            }
                        }
                    } label: {
                        HStack {
                            Text(travelStyle)
                                .foregroundColor(AppTheme.Colors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppTheme.Colors.textTertiary)
                        }
                        .padding(AppTheme.Spacing.md)
                        .background(Color.white)
                        .cornerRadius(AppTheme.CornerRadius.md)
                        .applyShadow(Shadow(color: AppTheme.Shadows.light, radius: 2, x: 0, y: 1))
                    }
                }
            }
        }
    }
    
    private var interestsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionHeader("What Interests You?", icon: "star.fill")
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: AppTheme.Spacing.sm) {
                ForEach(interests, id: \.self) { interest in
                    InterestButton(
                        interest: interest,
                        isSelected: selectedInterests.contains(interest)
                    ) {
                        if selectedInterests.contains(interest) {
                            selectedInterests.remove(interest)
                        } else {
                            selectedInterests.insert(interest)
                        }
                    }
                }
            }
            .padding(AppTheme.Spacing.lg)
            .background(Color.white)
            .cornerRadius(AppTheme.CornerRadius.md)
            .applyShadow(Shadow(color: AppTheme.Shadows.light, radius: 2, x: 0, y: 1))
        }
    }
    
    private var specialRequestsSection: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            sectionHeader("Special Requests", icon: "message.fill")
            
            TextField("Any special requests or requirements?", text: $specialRequests, axis: .vertical)
                .lineLimit(3...6)
                .padding(AppTheme.Spacing.md)
                .background(Color.white)
                .cornerRadius(AppTheme.CornerRadius.md)
                .applyShadow(Shadow(color: AppTheme.Shadows.light, radius: 2, x: 0, y: 1))
        }
    }
    
    private var submitSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            Button(action: submitTrip) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "paperplane.fill")
                    }
                    Text(viewModel.isLoading ? "Creating Trip..." : "Submit Trip Request")
                }
                .font(AppTheme.Typography.button)
                .foregroundColor(.white)
                .frame(minHeight: 44)
                .frame(maxWidth: .infinity)
                .background(
                    isFormValid && !viewModel.isLoading ? 
                    AppTheme.Colors.gradientSecondary : 
                    LinearGradient(colors: [Color.gray], startPoint: .top, endPoint: .bottom)
                )
                .cornerRadius(AppTheme.CornerRadius.md)
                .applyShadow(AppTheme.Shadows.buttonShadow)
            }
            .disabled(!isFormValid || viewModel.isLoading)
            .accessibilityLabel(viewModel.isLoading ? "Creating trip request" : "Submit trip request")
            .accessibilityHint("Submit your trip details for planning")
            
            Text("We'll personally craft your perfect itinerary and notify you when it's ready!")
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var flexibleDatesView: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            HStack(spacing: AppTheme.Spacing.md) {
                CustomDatePicker(
                    title: "Earliest Start",
                    date: $earliestStartDate,
                    minimumDate: Date()
                )
                
                CustomDatePicker(
                    title: "Latest Start",
                    date: $latestStartDate,
                    minimumDate: earliestStartDate
                )
            }
            
            VStack(alignment: .leading) {
                Text("Trip Duration: \(tripDuration) days")
                    .font(AppTheme.Typography.bodySmall)
                    .foregroundColor(AppTheme.Colors.textSecondary)
                Slider(value: Binding(
                    get: { Double(tripDuration) },
                    set: { tripDuration = Int($0) }
                ), in: 1...30, step: 1)
                .accentColor(AppTheme.Colors.primary)
                .padding(AppTheme.Spacing.md)
                .background(Color.white)
                .cornerRadius(AppTheme.CornerRadius.md)
                .applyShadow(Shadow(color: AppTheme.Shadows.light, radius: 2, x: 0, y: 1))
            }
        }
    }
    
    private var fixedDatesView: some View {
        HStack(spacing: AppTheme.Spacing.md) {
            CustomDatePicker(
                title: "Start Date",
                date: $startDate,
                minimumDate: Date()
            )
            
            CustomDatePicker(
                title: "End Date",
                date: $endDate,
                minimumDate: startDate
            )
        }
    }
    
    private func sectionHeader(_ title: String, icon: String) -> some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.Colors.primary)
            
            Text(title)
                .font(AppTheme.Typography.h3)
                .foregroundColor(AppTheme.Colors.textPrimary)
        }
    }
    
    private func addDestination() {
        withAnimation(AppTheme.Animation.quick) {
            destinations.append("")
        }
    }
    
    private func removeDestination(at index: Int) {
        withAnimation(AppTheme.Animation.quick) {
            if destinations.count > 1 {
                destinations.remove(at: index)
            }
        }
    }
    
    private var isFormValid: Bool {
        // Enhanced validation with content filtering
        let destinationsValid = destinations.contains { destination in
            let validation = FormValidation.validateDestinationEnhanced(destination)
            return validation.isValid
        }
        
        let departureValidation = FormValidation.validateDestinationEnhanced(departureLocation)
        let departureLocationValid = departureValidation.isValid
        
        // Budget validation if provided
        let budgetValid = budget.isEmpty || FormValidation.validateBudgetEnhanced(budget).isValid
        
        // Special requests validation if provided
        let specialRequestsValid = specialRequests.isEmpty || FormValidation.validateMessageEnhanced(specialRequests).isValid
        
        let dateValidation: Bool
        if flexibleDates {
            dateValidation = latestStartDate >= earliestStartDate
        } else {
            dateValidation = endDate > startDate
        }
        
        return destinationsValid && departureLocationValid && budgetValid && specialRequestsValid && dateValidation
    }
    
    private func submitTrip() {
        // Validate and sanitize destinations
        let validDestinations = destinations
            .compactMap { destination in
                let validation = FormValidation.validateDestinationEnhanced(destination)
                return validation.value
            }
            .filter { !$0.isEmpty }
        
        // Use timezone-agnostic date strings to prevent day shifting
        let startDateString = DateUtils.toAPIDateString(flexibleDates ? earliestStartDate : startDate)
        let endDateString = DateUtils.toAPIDateString(flexibleDates ? latestStartDate : endDate)
        
        // Sanitize other inputs
        let sanitizedDeparture = FormValidation.validateDestinationEnhanced(departureLocation).value ?? ""
        let sanitizedBudget = FormValidation.validateBudgetEnhanced(budget).value ?? ""
        let sanitizedSpecialRequests = FormValidation.validateMessageEnhanced(specialRequests).value ?? ""
        
        let submission = EnhancedTripSubmission(
            destinations: validDestinations,
            departureLocation: sanitizedDeparture,
            startDate: startDateString,
            endDate: endDateString,
            flexibleDates: flexibleDates,
            tripDuration: flexibleDates ? tripDuration : nil,
            budget: sanitizedBudget.isEmpty ? nil : sanitizedBudget,
            travelStyle: travelStyle,
            groupSize: groupSize,
            specialRequests: sanitizedSpecialRequests,
            interests: Array(selectedInterests),
            flightClass: nil
        )
        
        // Track trip submission analytics
        AnalyticsService.shared.trackTripSubmission(
            destinationCount: destinations.filter { !$0.isEmpty }.count,
            hasBudget: !budget.isEmpty,
            flexibleDates: flexibleDates
        )
        
        viewModel.submitTrip(submission)
    }
    
    private func clearForm() {
        destinations = [""]
        departureLocation = ""
        startDate = Date()
        endDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        flexibleDates = false
        budget = ""
        travelStyle = "Comfortable"
        groupSize = 1
        specialRequests = ""
        selectedInterests = []
        earliestStartDate = Date()
        latestStartDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        tripDuration = 7
    }
    
    private func handleRecoveryAction(_ action: RecoveryAction) {
        switch action {
        case .retry:
            if isFormValid {
                submitTrip()
            }
        case .editAndResubmit:
            // Form is already editable, just clear error
            viewModel.clearError()
        case .saveDraft:
            // Save form data locally (implement if needed)
            saveDraftLocally()
        case .clearFormAndRestart:
            clearForm()
            viewModel.clearError()
        case .contactSupport:
            // Open support contact (implement if needed)
            contactSupport()
        default:
            viewModel.clearError()
        }
    }
    
    private func saveDraftLocally() {
        // Save current form state to UserDefaults for later recovery
        let draftData: [String: Any] = [
            "destinations": destinations,
            "departureLocation": departureLocation,
            "budget": budget,
            "specialRequests": specialRequests,
            "groupSize": groupSize,
            "travelStyle": travelStyle
        ]
        
        UserDefaults.standard.set(draftData, forKey: "trip_draft")
        
        // Show confirmation
        // Could show a toast or temporary message
    }
    
    private func contactSupport() {
        // Open email or support URL
        if let url = URL(string: "mailto:support@travelconsulting.app?subject=Trip Submission Issue") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - ViewModel
@MainActor
class TripSubmissionViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var submissionSuccess = false
    @Published var currentError: Error?
    
    private let tripService = TripService()
    
    func submitTrip(_ submission: EnhancedTripSubmission) {
        isLoading = true
        errorMessage = nil
        currentError = nil
        
        Task {
            do {
                try await tripService.submitEnhancedTrip(submission)
                submissionSuccess = true
            } catch {
                errorMessage = error.localizedDescription
                currentError = error
                
                // Track error for analytics
                AnalyticsService.shared.trackError(error, context: "TripSubmission")
            }
            isLoading = false
        }
    }
    
    func clearError() {
        errorMessage = nil
        currentError = nil
    }
    
    func clearSuccess() {
        submissionSuccess = false
    }
}

// MARK: - Custom Date Picker Component
struct CustomDatePicker: View {
    let title: String
    @Binding var date: Date
    let minimumDate: Date?
    
    @State private var showingDatePicker = false
    @State private var tempDate: Date
    
    init(title: String, date: Binding<Date>, minimumDate: Date? = nil) {
        self.title = title
        self._date = date
        self.minimumDate = minimumDate
        self._tempDate = State(initialValue: date.wrappedValue)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            Button(action: {
                tempDate = date
                showingDatePicker = true
            }) {
                HStack {
                    Text(DateUtils.displayString(for: date))
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "calendar")
                        .foregroundColor(AppTheme.Colors.primary)
                }
                .padding(.vertical, AppTheme.Spacing.sm)
                .padding(.horizontal, AppTheme.Spacing.md)
                .background(AppTheme.Colors.backgroundSecondary)
                .cornerRadius(AppTheme.CornerRadius.sm)
                .applyShadow(Shadow(color: AppTheme.Shadows.light, radius: 2, x: 0, y: 1))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .sheet(isPresented: $showingDatePicker) {
            NavigationView {
                VStack {
                    DatePicker(
                        title,
                        selection: $tempDate,
                        in: (minimumDate ?? Date.distantPast)...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            showingDatePicker = false
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("OK") {
                            date = tempDate
                            showingDatePicker = false
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
    TripSubmissionView()
}