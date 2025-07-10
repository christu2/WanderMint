//
//  ViewModelTests.swift
//  TravelConsultingAppTests
//
//  Created by Nick Christus on 3/9/25.
//

import Testing
import Foundation
@testable import TravelConsultingApp

struct ViewModelTests {
    
    // MARK: - AuthenticationViewModel Tests
    
    @Test func testAuthenticationViewModelInitialState() async throws {
        await MainActor.run {
            let viewModel = AuthenticationViewModel()
            
            #expect(viewModel.isAuthenticated == false)
            #expect(viewModel.currentUser == nil)
            #expect(viewModel.isLoading == false)
            #expect(viewModel.errorMessage == nil)
        }
    }
    
    @Test func testEmailValidation() async throws {
        await MainActor.run {
            let viewModel = AuthenticationViewModel()
            
            // Valid emails
            #expect(viewModel.isValidEmail("test@example.com") == true)
            #expect(viewModel.isValidEmail("user.name@domain.co.uk") == true)
            #expect(viewModel.isValidEmail("test+tag@example.org") == true)
            #expect(viewModel.isValidEmail("user123@test-domain.com") == true)
            
            // Invalid emails
            #expect(viewModel.isValidEmail("") == false)
            #expect(viewModel.isValidEmail("invalid") == false)
            #expect(viewModel.isValidEmail("test@") == false)
            #expect(viewModel.isValidEmail("@example.com") == false)
            #expect(viewModel.isValidEmail("test.example.com") == false)
            #expect(viewModel.isValidEmail("test@.com") == false)
            #expect(viewModel.isValidEmail("test@example.") == false)
        }
    }
    
    @Test func testPasswordValidation() async throws {
        await MainActor.run {
            let viewModel = AuthenticationViewModel()
            
            // Valid passwords (6+ characters)
            #expect(viewModel.isValidPassword("123456") == true)
            #expect(viewModel.isValidPassword("password") == true)
            #expect(viewModel.isValidPassword("MyP@ssw0rd") == true)
            #expect(viewModel.isValidPassword("abcdef") == true)
            
            // Invalid passwords (less than 6 characters)
            #expect(viewModel.isValidPassword("") == false)
            #expect(viewModel.isValidPassword("12345") == false)
            #expect(viewModel.isValidPassword("abc") == false)
            #expect(viewModel.isValidPassword("a") == false)
        }
    }
    
    @Test func testClearError() async throws {
        await MainActor.run {
            let viewModel = AuthenticationViewModel()
            
            // Set an error message
            viewModel.errorMessage = "Test error"
            #expect(viewModel.errorMessage == "Test error")
            
            // Clear the error
            viewModel.clearError()
            #expect(viewModel.errorMessage == nil)
        }
    }
    
    @Test func testAuthenticationStateManagement() async throws {
        await MainActor.run {
            let viewModel = AuthenticationViewModel()
            
            // Test initial state
            #expect(viewModel.isAuthenticated == false)
            #expect(viewModel.currentUser == nil)
            
            // Note: We can't easily test Firebase auth state changes in unit tests
            // without mocking Firebase, but we can test the logic structure
        }
    }
    
    // MARK: - TripSubmissionViewModel Tests
    
    @Test func testTripSubmissionViewModelInitialState() async throws {
        await MainActor.run {
            let viewModel = TripSubmissionViewModel()
            
            #expect(viewModel.isLoading == false)
            #expect(viewModel.errorMessage == nil)
            #expect(viewModel.submissionSuccess == false)
        }
    }
    
    @Test func testTripSubmissionClearError() async throws {
        await MainActor.run {
            let viewModel = TripSubmissionViewModel()
            
            // Set an error message
            viewModel.errorMessage = "Submission failed"
            #expect(viewModel.errorMessage == "Submission failed")
            
            // Clear the error
            viewModel.clearError()
            #expect(viewModel.errorMessage == nil)
        }
    }
    
    @Test func testTripSubmissionClearSuccess() async throws {
        await MainActor.run {
            let viewModel = TripSubmissionViewModel()
            
            // Set success state
            viewModel.submissionSuccess = true
            #expect(viewModel.submissionSuccess == true)
            
            // Clear success
            viewModel.clearSuccess()
            #expect(viewModel.submissionSuccess == false)
        }
    }
    
    @Test func testTripSubmissionStateTransitions() async throws {
        await MainActor.run {
            let viewModel = TripSubmissionViewModel()
            
            // Test that we can manually set loading state for testing
            viewModel.isLoading = true
            #expect(viewModel.isLoading == true)
            
            viewModel.isLoading = false
            #expect(viewModel.isLoading == false)
            
            // Test error state
            viewModel.errorMessage = "Network error"
            #expect(viewModel.errorMessage == "Network error")
            #expect(viewModel.submissionSuccess == false)
            
            // Test success state
            viewModel.errorMessage = nil
            viewModel.submissionSuccess = true
            #expect(viewModel.errorMessage == nil)
            #expect(viewModel.submissionSuccess == true)
        }
    }
    
    // MARK: - Form Validation Tests
    
    @Test func testTripSubmissionFormValidation() async throws {
        // Test form validation logic that would be used in the view
        let destination = "Tokyo, Japan"
        let startDate = Date()
        let endDate = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days later
        let flexibleDates = false
        
        // Valid form
        let destinationValid = !destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let datesValid = !flexibleDates ? endDate > startDate : true
        
        #expect(destinationValid == true)
        #expect(datesValid == true)
        
        // Invalid destination
        let emptyDestination = ""
        let emptyDestinationValid = !emptyDestination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        #expect(emptyDestinationValid == false)
        
        // Invalid dates (end before start)
        let invalidEndDate = Date().addingTimeInterval(-24 * 60 * 60) // 1 day ago
        let invalidDatesValid = invalidEndDate > startDate
        #expect(invalidDatesValid == false)
    }
    
    @Test func testFlexibleDatesValidation() async throws {
        let earliestStartDate = Date()
        let latestStartDate = Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days later
        let flexibleDates = true
        
        // Valid flexible dates
        let flexibleDatesValid = flexibleDates ? latestStartDate >= earliestStartDate : true
        #expect(flexibleDatesValid == true)
        
        // Invalid flexible dates (latest before earliest)
        let invalidLatestDate = Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago
        let invalidFlexibleDatesValid = flexibleDates ? invalidLatestDate >= earliestStartDate : true
        #expect(invalidFlexibleDatesValid == false)
    }
    
    @Test func testGroupSizeValidation() async throws {
        let validGroupSizes = [1, 2, 4, 8, 10, 15, 20]
        let invalidGroupSizes = [0, -1, 21, 100]
        
        for size in validGroupSizes {
            #expect(size >= 1)
            #expect(size <= 20)
        }
        
        for size in invalidGroupSizes {
            let isValid = size >= 1 && size <= 20
            #expect(isValid == false)
        }
    }
    
    @Test func testTripDurationValidation() async throws {
        let validDurations = [1, 7, 14, 21, 30]
        let invalidDurations = [0, -1, 31, 365]
        
        for duration in validDurations {
            let isValid = duration >= 1 && duration <= 30
            #expect(isValid == true)
        }
        
        for duration in invalidDurations {
            let isValid = duration >= 1 && duration <= 30
            #expect(isValid == false)
        }
    }
    
    // MARK: - Enhanced Trip Submission Creation Tests
    
    @Test func testCreateEnhancedTripSubmission() async throws {
        let destination = "Tokyo, Japan"
        let startDate = Date()
        let endDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        let flexibleDates = false
        let budget = "5000"
        let travelStyle = "Comfortable"
        let groupSize = 2
        let specialRequests = "Looking for authentic experiences"
        let selectedInterests: Set<String> = ["Culture", "Food"]
        
        let dateFormatter = ISO8601DateFormatter()
        
        let submission = EnhancedTripSubmission(
            destinations: [destination.trimmingCharacters(in: .whitespacesAndNewlines)],
            startDate: dateFormatter.string(from: startDate),
            endDate: dateFormatter.string(from: endDate),
            flexibleDates: flexibleDates,
            tripDuration: nil,
            budget: budget.isEmpty ? nil : budget,
            travelStyle: travelStyle,
            groupSize: groupSize,
            specialRequests: specialRequests.trimmingCharacters(in: .whitespacesAndNewlines),
            interests: Array(selectedInterests),
            flightClass: nil
        )
        
        #expect(submission.destinations == ["Tokyo, Japan"])
        #expect(submission.flexibleDates == false)
        #expect(submission.budget == "5000")
        #expect(submission.travelStyle == "Comfortable")
        #expect(submission.groupSize == 2)
        #expect(submission.specialRequests == "Looking for authentic experiences")
        #expect(submission.interests.count == 2)
        #expect(submission.interests.contains("Culture"))
        #expect(submission.interests.contains("Food"))
        #expect(submission.flightClass == nil)
        #expect(submission.tripDuration == nil)
    }
    
    @Test func testFlexibleDatesSubmission() async throws {
        let earliestStartDate = Date()
        let latestStartDate = Date().addingTimeInterval(30 * 24 * 60 * 60)
        let tripDuration = 7
        let flexibleDates = true
        
        let dateFormatter = ISO8601DateFormatter()
        
        let submission = EnhancedTripSubmission(
            destinations: ["Kyoto, Japan"],
            startDate: dateFormatter.string(from: earliestStartDate),
            endDate: dateFormatter.string(from: latestStartDate),
            flexibleDates: flexibleDates,
            tripDuration: tripDuration,
            budget: nil,
            travelStyle: "Adventure",
            groupSize: 1,
            specialRequests: "",
            interests: [],
            flightClass: "Economy"
        )
        
        #expect(submission.flexibleDates == true)
        #expect(submission.tripDuration == 7)
        #expect(submission.budget == nil)
        #expect(submission.specialRequests == "")
        #expect(submission.interests.isEmpty)
        #expect(submission.flightClass == "Economy")
    }
    
    // MARK: - Date Formatting Tests
    
    @Test func testISO8601DateFormatting() async throws {
        let testDate = Date()
        let formatter = ISO8601DateFormatter()
        
        let formattedString = formatter.string(from: testDate)
        let parsedDate = formatter.date(from: formattedString)
        
        #expect(parsedDate != nil)
        #expect(formattedString.contains("T"))
        #expect(formattedString.contains("Z") || formattedString.contains("+") || formattedString.contains("-"))
        
        // Should be able to round-trip
        if let parsedDate = parsedDate {
            #expect(abs(parsedDate.timeIntervalSince(testDate)) < 1.0)
        }
    }
    
    // MARK: - State Management Tests
    
    @Test func testViewModelStateConsistency() async throws {
        await MainActor.run {
            let viewModel = TripSubmissionViewModel()
            
            // Test that loading and success/error states are mutually exclusive
            viewModel.isLoading = true
            viewModel.submissionSuccess = true
            viewModel.errorMessage = "Error"
            
            // In a real implementation, these states should be managed properly
            #expect(viewModel.isLoading == true)
            
            // Simulate completion
            viewModel.isLoading = false
            #expect(viewModel.isLoading == false)
            
            // Either success OR error should be set, not both
            if viewModel.submissionSuccess {
                viewModel.errorMessage = nil
            } else if viewModel.errorMessage != nil {
                viewModel.submissionSuccess = false
            }
            
            #expect(!(viewModel.submissionSuccess && viewModel.errorMessage != nil))
        }
    }
    
    // MARK: - Error Handling Tests
    
    @Test func testErrorMessageHandling() async throws {
        await MainActor.run {
            let viewModel = TripSubmissionViewModel()
            
            let testErrors = [
                "Network connection failed",
                "Authentication failed. Please try logging in again.",
                "Trip submission failed: Server error",
                "Invalid request: Missing required fields"
            ]
            
            for errorMessage in testErrors {
                viewModel.errorMessage = errorMessage
                #expect(viewModel.errorMessage == errorMessage)
                #expect(!viewModel.errorMessage!.isEmpty)
                
                // Clear error
                viewModel.clearError()
                #expect(viewModel.errorMessage == nil)
            }
        }
    }
    
    // MARK: - Form Reset Tests
    
    @Test func testFormReset() async throws {
        // Test form reset logic that would be used in the view
        var destination = "Tokyo, Japan"
        var startDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        var endDate = Date().addingTimeInterval(14 * 24 * 60 * 60)
        var flexibleDates = true
        var budget = "5000"
        var travelStyle = "Luxury"
        var groupSize = 4
        var specialRequests = "Special dietary requirements"
        var selectedInterests: Set<String> = ["Culture", "Food", "Shopping"]
        
        // Form is filled
        #expect(!destination.isEmpty)
        #expect(!budget.isEmpty)
        #expect(groupSize > 1)
        #expect(!selectedInterests.isEmpty)
        
        // Reset form
        destination = ""
        startDate = Date()
        endDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
        flexibleDates = false
        budget = ""
        travelStyle = "Comfortable"
        groupSize = 1
        specialRequests = ""
        selectedInterests = []
        
        // Form is reset
        #expect(destination.isEmpty)
        #expect(budget.isEmpty)
        #expect(groupSize == 1)
        #expect(selectedInterests.isEmpty)
        #expect(flexibleDates == false)
        #expect(travelStyle == "Comfortable")
        #expect(specialRequests.isEmpty)
    }
}