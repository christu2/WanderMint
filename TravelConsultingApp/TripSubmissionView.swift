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
                .padding(.horizontal, 16)
                .padding(.vertical, 12) // Increased for better touch target
                .frame(minHeight: 44) // Accessibility touch target
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
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
    @State private var destination = ""
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
            Form {
                Section(header: Text("Trip Details")) {
                    TextField("Destination", text: $destination)
                        .textInputAutocapitalization(.words)
                    
                    Toggle("I have flexible dates", isOn: $flexibleDates)
                    
                    if flexibleDates {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Date Flexibility")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            CustomDatePicker(
                                title: "Earliest I can start",
                                date: $earliestStartDate,
                                minimumDate: Date()
                            )
                            
                            CustomDatePicker(
                                title: "Latest I can start",
                                date: $latestStartDate,
                                minimumDate: earliestStartDate
                            )
                            
                            VStack(alignment: .leading) {
                                Text("Trip Duration: \(tripDuration) days")
                                    .font(.subheadline)
                                Slider(value: Binding(
                                    get: { Double(tripDuration) },
                                    set: { tripDuration = Int($0) }
                                ), in: 1...30, step: 1)
                                HStack {
                                    Text("1 day")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("30 days")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    } else {
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
                
                Section(header: Text("Travel Preferences")) {
                    TextField("Budget (optional)", text: $budget)
                        .keyboardType(.numberPad)
                    
                    Picker("Travel Style", selection: $travelStyle) {
                        ForEach(travelStyles, id: \.self) { style in
                            Text(style).tag(style)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Stepper("Group Size: \(groupSize)", value: $groupSize, in: 1...20)
                }
                
                Section(header: Text("Interests (select all that apply)")) {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 10) {
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
                }
                
                Section(header: Text("Special Requests")) {
                    TextField("Any special requests or requirements?", text: $specialRequests, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                
                Section {
                    PrimaryButton(
                        title: "Submit Trip Request",
                        icon: "paperplane.fill",
                        isLoading: viewModel.isLoading,
                        isEnabled: isFormValid
                    ) {
                        submitTrip()
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Plan My Trip")
            .disabled(viewModel.isLoading) // Prevent form interaction while submitting
            .overlay(
                Group {
                    if viewModel.isLoading {
                        LoadingOverlay(message: "Creating your perfect trip...")
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
        }
    }
    
    private var isFormValid: Bool {
        let destinationValid = !destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        if flexibleDates {
            return destinationValid && latestStartDate >= earliestStartDate
        } else {
            return destinationValid && endDate > startDate
        }
    }
    
    private func submitTrip() {
        let dateFormatter = ISO8601DateFormatter()
        
        let submission = EnhancedTripSubmission(
            destinations: [destination.trimmingCharacters(in: .whitespacesAndNewlines)],
            startDate: dateFormatter.string(from: flexibleDates ? earliestStartDate : startDate),
            endDate: dateFormatter.string(from: flexibleDates ? latestStartDate : endDate),
            flexibleDates: flexibleDates,
            tripDuration: flexibleDates ? tripDuration : nil,
            budget: budget.isEmpty ? nil : budget,
            travelStyle: travelStyle,
            groupSize: groupSize,
            specialRequests: specialRequests.trimmingCharacters(in: .whitespacesAndNewlines),
            interests: Array(selectedInterests),
            flightClass: nil
        )
        
        viewModel.submitTrip(submission)
    }
    
    private func clearForm() {
        destination = ""
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
}

// MARK: - ViewModel
@MainActor
class TripSubmissionViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var submissionSuccess = false
    
    private let tripService = TripService()
    
    func submitTrip(_ submission: EnhancedTripSubmission) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                try await tripService.submitEnhancedTrip(submission)
                submissionSuccess = true
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    func clearError() {
        errorMessage = nil
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
        VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                tempDate = date
                showingDatePicker = true
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Image(systemName: "calendar")
                        .foregroundColor(.blue)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
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
