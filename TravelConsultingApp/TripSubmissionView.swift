import SwiftUI

// MARK: - Interest Button Component (defined first)
struct InterestButton: View {
    let interest: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(interest)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle()) // This fixes the selection issue
    }
}

// MARK: - Main Trip Submission View
struct TripSubmissionView: View {
    @StateObject private var viewModel = TripSubmissionViewModel()
    @State private var destination = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days from now
    @State private var paymentMethod = "Credit Card"
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
    
    let paymentMethods = ["Credit Card", "Debit Card", "PayPal", "Bank Transfer"]
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
                            
                            DatePicker("Earliest I can start", selection: $earliestStartDate, in: Date()..., displayedComponents: .date)
                            
                            DatePicker("Latest I can start", selection: $latestStartDate, in: earliestStartDate..., displayedComponents: .date)
                            
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
                        DatePicker("Start Date", selection: $startDate, in: Date()..., displayedComponents: .date)
                        
                        DatePicker("End Date", selection: $endDate, in: startDate..., displayedComponents: .date)
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
                    .pickerStyle(MenuPickerStyle())
                    
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
                
                Section(header: Text("Payment")) {
                    Picker("Payment Method", selection: $paymentMethod) {
                        ForEach(paymentMethods, id: \.self) { method in
                            Text(method).tag(method)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                Section {
                    Button(action: submitTrip) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(viewModel.isLoading ? "Submitting..." : "Submit Trip Request")
                        }
                    }
                    .disabled(!isFormValid || viewModel.isLoading)
                }
            }
            .navigationTitle("Plan My Trip")
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
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
        let submission = EnhancedTripSubmission(
            destination: destination.trimmingCharacters(in: .whitespacesAndNewlines),
            startDate: flexibleDates ? earliestStartDate : startDate,
            endDate: flexibleDates ? latestStartDate : endDate,
            paymentMethod: paymentMethod,
            flexibleDates: flexibleDates,
            tripDuration: flexibleDates ? tripDuration : nil,
            budget: budget.isEmpty ? nil : budget,
            travelStyle: travelStyle,
            groupSize: groupSize,
            specialRequests: specialRequests.trimmingCharacters(in: .whitespacesAndNewlines),
            interests: Array(selectedInterests)
        )
        
        viewModel.submitTrip(submission)
    }
    
    private func clearForm() {
        destination = ""
        startDate = Date()
        endDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        paymentMethod = "Credit Card"
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

#Preview {
    TripSubmissionView()
}
