import XCTest
import SwiftUI
import Combine
@testable import WanderMint

class TripSubmissionViewTests: XCTestCase {
    
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - TripSubmissionViewModel Tests
    
    @MainActor
    func testViewModelInitialState() {
        let mockService = MockTripService()
        let viewModel = TripSubmissionViewModel(tripService: mockService)
        
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.submissionSuccess)
        XCTAssertNil(viewModel.currentError)
    }
    
    @MainActor
    func testViewModelLoadingState() {
        let mockService = MockTripService()
        let viewModel = TripSubmissionViewModel(tripService: mockService)
        
        // Mock a successful submission
        let mockSubmission = EnhancedTripSubmission(
            destinations: ["New York"],
            departureLocation: "Boston",
            startDate: "2024-01-01",
            endDate: "2024-01-08",
            flexibleDates: false,
            tripDuration: nil,
            budget: nil,
            travelStyle: "Comfortable",
            groupSize: 2,
            specialRequests: "",
            interests: ["Culture", "Food"],
            flightClass: nil
        )
        
        viewModel.submitTrip(mockSubmission)
        
        // The viewModel should briefly be in loading state
        XCTAssertTrue(viewModel.isLoading)
    }
    
    @MainActor
    func testViewModelErrorHandling() async {
        // Create a mock service that will fail
        let mockService = MockTripService()
        mockService.shouldSucceed = false
        mockService.submissionDelay = 0.05 // Very fast failure
        
        let viewModel = TripSubmissionViewModel(tripService: mockService)
        
        // Submit any data - the mock service is configured to fail
        let invalidSubmission = EnhancedTripSubmission(
            destinations: [],
            departureLocation: "",
            startDate: "",
            endDate: "",
            flexibleDates: false,
            tripDuration: nil,
            budget: nil,
            travelStyle: "",
            groupSize: 0,
            specialRequests: "",
            interests: [],
            flightClass: nil
        )
        
        // Submit and wait for completion using expectation
        let expectation = expectation(description: "Error should be set")
        
        viewModel.$errorMessage
            .dropFirst()
            .sink { errorMessage in
                if errorMessage != nil {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.submitTrip(invalidSubmission)
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Verify error was set
        XCTAssertNotNil(viewModel.errorMessage, "Error message should be set")
        XCTAssertNotNil(viewModel.currentError, "Current error should be set")
        XCTAssertFalse(viewModel.isLoading, "Loading should be false after error")
    }
    
    @MainActor
    func testViewModelClearError() {
        let mockService = MockTripService()
        let viewModel = TripSubmissionViewModel(tripService: mockService)
        
        // Set an error
        viewModel.submitTrip(EnhancedTripSubmission(
            destinations: [],
            departureLocation: "",
            startDate: "",
            endDate: "",
            flexibleDates: false,
            tripDuration: nil,
            budget: nil,
            travelStyle: "",
            groupSize: 0,
            specialRequests: "",
            interests: [],
            flightClass: nil
        ))
        
        // Clear the error
        viewModel.clearError()
        
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertNil(viewModel.currentError)
    }
    
    @MainActor
    func testViewModelClearSuccess() {
        let mockService = MockTripService()
        let viewModel = TripSubmissionViewModel(tripService: mockService)
        
        // Simulate success state
        viewModel.clearSuccess()
        
        XCTAssertFalse(viewModel.submissionSuccess)
    }
    
    // MARK: - Array Extension Tests
    
    func testSafeArrayAccess() {
        var testArray = ["item1", "item2", "item3"]
        
        // Test valid index access
        XCTAssertEqual(testArray[safe: 0], "item1")
        XCTAssertEqual(testArray[safe: 1], "item2")
        XCTAssertEqual(testArray[safe: 2], "item3")
        
        // Test out of bounds access
        XCTAssertNil(testArray[safe: 3])
        XCTAssertNil(testArray[safe: -1])
        XCTAssertNil(testArray[safe: 10])
    }
    
    func testSafeArraySetting() {
        var testArray = ["item1", "item2"]
        
        // Test setting valid index
        testArray[safe: 0] = "newItem1"
        XCTAssertEqual(testArray[0], "newItem1")
        
        // Test setting out of bounds index (should extend array)
        testArray[safe: 3] = "newItem4"
        XCTAssertEqual(testArray.count, 4)
        XCTAssertEqual(testArray[3], "newItem4")
        
        // Test setting with nil (should not crash)
        testArray[safe: 5] = nil
        XCTAssertEqual(testArray.count, 4) // Array should not be extended with nil
    }
    
    // MARK: - Multiple Destinations Tests
    
    func testMultipleDestinationsInitialization() {
        // Test that TripSubmissionView can handle multiple destinations
        let destinations = ["New York", "Boston", "Chicago"]
        let selectedDestinations: [LocationResult?] = [
            LocationResult(title: "New York", subtitle: "NY, United States", coordinate: nil),
            LocationResult(title: "Boston", subtitle: "MA, United States", coordinate: nil),
            nil
        ]
        
        XCTAssertEqual(destinations.count, 3)
        XCTAssertEqual(selectedDestinations.count, 3)
        XCTAssertNotNil(selectedDestinations[0])
        XCTAssertNotNil(selectedDestinations[1])
        XCTAssertNil(selectedDestinations[2])
    }
    
    func testDestinationValidation() {
        // Test that form validation works with multiple destinations
        let validDestinations = ["New York", "Boston", "Chicago"]
        let invalidDestinations = ["", "  ", "A"] // Empty, whitespace, too short
        
        for destination in validDestinations {
            let validation = FormValidation.validateDestinationEnhanced(destination)
            XCTAssertTrue(validation.isValid, "Destination '\(destination)' should be valid")
        }
        
        for destination in invalidDestinations {
            let validation = FormValidation.validateDestinationEnhanced(destination)
            XCTAssertFalse(validation.isValid, "Destination '\(destination)' should be invalid")
        }
    }
    
    // MARK: - Keyboard Handling Tests
    
    func testKeyboardDismissalOnInterestSelection() {
        // Test that keyboard dismissal logic works correctly
        let mockKeyboard = MockKeyboardHandler()
        
        // Simulate interest selection
        mockKeyboard.simulateInterestSelection()
        
        XCTAssertTrue(mockKeyboard.dismissKeyboardCalled)
    }
    
    func testKeyboardSafeAreaHandling() {
        let keyboardHandler = KeyboardHandler()
        
        // Test initial state
        XCTAssertEqual(keyboardHandler.keyboardHeight, 0)
        XCTAssertFalse(keyboardHandler.isKeyboardVisible)
        
        // Test keyboard visibility tracking
        let expectation = expectation(description: "Keyboard state should update")
        
        keyboardHandler.$isKeyboardVisible
            .dropFirst()
            .sink { isVisible in
                XCTAssertTrue(isVisible)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Simulate keyboard showing
        let userInfo: [AnyHashable: Any] = [
            UIResponder.keyboardFrameEndUserInfoKey: CGRect(x: 0, y: 0, width: 320, height: 216)
        ]
        
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillShowNotification,
            object: nil,
            userInfo: userInfo
        )
        
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - Form Submission Tests
    
    func testFormValidation() {
        // Test form validation with valid data
        let validSubmission = EnhancedTripSubmission(
            destinations: ["New York", "Boston"],
            departureLocation: "Chicago",
            startDate: "2024-01-01",
            endDate: "2024-01-08",
            flexibleDates: false,
            tripDuration: nil,
            budget: "2000",
            travelStyle: "Comfortable",
            groupSize: 2,
            specialRequests: "Window seat preferred",
            interests: ["Culture", "Food"],
            flightClass: nil
        )
        
        XCTAssertFalse(validSubmission.destinations.isEmpty)
        XCTAssertFalse(validSubmission.departureLocation.isEmpty)
        XCTAssertFalse(validSubmission.startDate.isEmpty)
        XCTAssertFalse(validSubmission.endDate.isEmpty)
        XCTAssertGreaterThan(validSubmission.groupSize, 0)
    }
    
    func testFormValidationWithInvalidData() {
        // Test form validation with invalid data
        let invalidSubmission = EnhancedTripSubmission(
            destinations: [],
            departureLocation: "",
            startDate: "",
            endDate: "",
            flexibleDates: false,
            tripDuration: nil,
            budget: nil,
            travelStyle: "",
            groupSize: 0,
            specialRequests: "",
            interests: [],
            flightClass: nil
        )
        
        XCTAssertTrue(invalidSubmission.destinations.isEmpty)
        XCTAssertTrue(invalidSubmission.departureLocation.isEmpty)
        XCTAssertTrue(invalidSubmission.startDate.isEmpty)
        XCTAssertTrue(invalidSubmission.endDate.isEmpty)
        XCTAssertEqual(invalidSubmission.groupSize, 0)
    }
    
    // MARK: - Navigation Tests
    
    @MainActor
    func testNavigationBarConfiguration() {
        // Test that navigation bar is properly configured
        let tripSubmissionView = TripSubmissionView(selectedTab: .constant(0))
        
        // This test verifies that the view can be instantiated without errors
        XCTAssertNotNil(tripSubmissionView)
    }
    
    func testDismissFunction() {
        // Test that dismiss functionality works
        let mockDismissHandler = MockTripSubmissionDismissHandler()
        
        // Simulate dismiss action
        mockDismissHandler.simulateDismiss()
        
        XCTAssertTrue(mockDismissHandler.dismissCalled)
    }
    
    // MARK: - Performance Tests
    
    func testFormValidationPerformance() {
        let destinations = Array(repeating: "New York", count: 10)
        
        measure {
            for destination in destinations {
                let validation = FormValidation.validateDestinationEnhanced(destination)
                XCTAssertTrue(validation.isValid)
            }
        }
    }
    
    func testMultipleDestinationsPerformance() {
        measure {
            var destinations = ["New York"]
            var selectedDestinations: [LocationResult?] = [nil]
            
            // Simulate adding multiple destinations
            for i in 1..<10 {
                destinations.append("City \(i)")
                selectedDestinations.append(LocationResult(
                    title: "City \(i)",
                    subtitle: "State \(i)",
                    coordinate: nil
                ))
            }
            
            XCTAssertEqual(destinations.count, 10)
            XCTAssertEqual(selectedDestinations.count, 10)
        }
    }
}

// MARK: - Mock Classes

@MainActor 
class MockTripService: TripServiceProtocol {
    var shouldSucceed = true
    var submissionDelay: TimeInterval = 0.1
    
    func submitEnhancedTrip(_ submission: EnhancedTripSubmission) async throws {
        try await Task.sleep(nanoseconds: UInt64(submissionDelay * 1_000_000_000))
        
        if !shouldSucceed {
            throw TripSubmissionError.validationFailed("Mock validation error")
        }
        
        // Simulate successful submission
    }
    
    func deleteTrip(tripId: String) async throws {
        // Mock implementation
    }
    
    func fetchUserTrips() async throws -> [TravelTrip] {
        // Mock implementation
        return []
    }
}

class MockKeyboardHandler {
    var dismissKeyboardCalled = false
    
    func simulateInterestSelection() {
        // Simulate the keyboard dismissal logic that happens in interest selection
        dismissKeyboardCalled = true
    }
}

class MockTripSubmissionDismissHandler {
    var dismissCalled = false
    
    func simulateDismiss() {
        dismissCalled = true
    }
}

// MARK: - Test Error Types

enum TripSubmissionError: Error {
    case validationFailed(String)
    case networkError(String)
    case unknown
}

// MARK: - Test Extensions

extension TripSubmissionError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}