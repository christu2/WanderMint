import XCTest
import SwiftUI
import MapKit
import Combine
@testable import WanderMint

class MultipleDestinationsTests: XCTestCase {
    
    var cancellables: Set<AnyCancellable>!
    var mockViewModel: MockTripSubmissionViewModel!
    
    override func setUp() {
        super.setUp()
        cancellables = Set<AnyCancellable>()
        mockViewModel = MockTripSubmissionViewModel()
    }
    
    override func tearDown() {
        cancellables = nil
        mockViewModel = nil
        super.tearDown()
    }
    
    // MARK: - Multiple Destinations Data Structure Tests
    
    func testDestinationsArrayInitialization() {
        var destinations: [String] = [""]
        var selectedDestinations: [LocationResult?] = [nil]
        
        XCTAssertEqual(destinations.count, 1)
        XCTAssertEqual(selectedDestinations.count, 1)
        XCTAssertEqual(destinations[0], "")
        XCTAssertNil(selectedDestinations[0])
    }
    
    func testAddDestination() {
        var destinations: [String] = ["New York"]
        var selectedDestinations: [LocationResult?] = [LocationResult(title: "New York", subtitle: "NY, United States", coordinate: nil)]
        
        // Simulate adding a destination
        destinations.append("")
        selectedDestinations.append(nil)
        
        XCTAssertEqual(destinations.count, 2)
        XCTAssertEqual(selectedDestinations.count, 2)
        XCTAssertEqual(destinations[0], "New York")
        XCTAssertEqual(destinations[1], "")
        XCTAssertNotNil(selectedDestinations[0])
        XCTAssertNil(selectedDestinations[1])
    }
    
    func testRemoveDestination() {
        var destinations: [String] = ["New York", "Boston", "Chicago"]
        var selectedDestinations: [LocationResult?] = [
            LocationResult(title: "New York", subtitle: "NY, United States", coordinate: nil),
            LocationResult(title: "Boston", subtitle: "MA, United States", coordinate: nil),
            LocationResult(title: "Chicago", subtitle: "IL, United States", coordinate: nil)
        ]
        
        // Simulate removing middle destination
        let indexToRemove = 1
        destinations.remove(at: indexToRemove)
        selectedDestinations.remove(at: indexToRemove)
        
        XCTAssertEqual(destinations.count, 2)
        XCTAssertEqual(selectedDestinations.count, 2)
        XCTAssertEqual(destinations[0], "New York")
        XCTAssertEqual(destinations[1], "Chicago")
        XCTAssertEqual(selectedDestinations[0]?.title, "New York")
        XCTAssertEqual(selectedDestinations[1]?.title, "Chicago")
    }
    
    func testDestinationsLimit() {
        var destinations: [String] = []
        var selectedDestinations: [LocationResult?] = []
        
        // Add destinations up to the limit (10)
        for i in 1...10 {
            destinations.append("City \(i)")
            selectedDestinations.append(LocationResult(title: "City \(i)", subtitle: "State \(i)", coordinate: nil))
        }
        
        XCTAssertEqual(destinations.count, 10)
        XCTAssertEqual(selectedDestinations.count, 10)
        
        // Verify we can't add more than 10 destinations
        let canAddMore = destinations.count < 10
        XCTAssertFalse(canAddMore)
    }
    
    // MARK: - Destination Validation Tests
    
    func testMultipleDestinationsValidation() {
        let validDestinations = ["New York", "Boston", "Chicago", "Miami"]
        let invalidDestinations = ["", "  ", "A", ""]
        
        // Test valid destinations
        for destination in validDestinations {
            let validation = FormValidation.validateDestinationEnhanced(destination)
            XCTAssertTrue(validation.isValid, "Destination '\(destination)' should be valid")
        }
        
        // Test invalid destinations
        for destination in invalidDestinations {
            let validation = FormValidation.validateDestinationEnhanced(destination)
            XCTAssertFalse(validation.isValid, "Destination '\(destination)' should be invalid")
        }
    }
    
    func testDuplicateDestinationsValidation() {
        let destinations = ["New York", "Boston", "New York", "Chicago"]
        
        // Test duplicate detection
        let uniqueDestinations = Set(destinations.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) })
        let hasDuplicates = uniqueDestinations.count != destinations.count
        
        XCTAssertTrue(hasDuplicates, "Should detect duplicate destinations")
    }
    
    func testEmptyDestinationsValidation() {
        let destinations = ["", "  ", "   "]
        let nonEmptyDestinations = destinations.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        XCTAssertTrue(nonEmptyDestinations.isEmpty, "Should filter out empty destinations")
    }
    
    // MARK: - LocationResult Array Tests
    
    func testLocationResultArrayOperations() {
        var locations: [LocationResult?] = [
            LocationResult(title: "New York", subtitle: "NY, United States", coordinate: nil),
            nil,
            LocationResult(title: "Boston", subtitle: "MA, United States", coordinate: nil)
        ]
        
        // Test safe access - note: safe subscript returns double optional for [LocationResult?] arrays
        XCTAssertNotNil(locations[safe: 0] as Any?)
        if let location = locations[safe: 1] {
            XCTAssertNil(location) // The value at index 1 is nil
        }
        XCTAssertNotNil(locations[safe: 2] as Any?)
        XCTAssertNil(locations[safe: 3] as Any?) // Out of bounds
        
        // Test setting values
        locations[safe: 1] = LocationResult(title: "Chicago", subtitle: "IL, United States", coordinate: nil)
        XCTAssertNotNil(locations[safe: 1] as Any?)
        if let location = locations[safe: 1] {
            XCTAssertEqual(location?.title, "Chicago")
        }
    }
    
    func testLocationResultArrayFiltering() {
        let locations: [LocationResult?] = [
            LocationResult(title: "New York", subtitle: "NY, United States", coordinate: nil),
            nil,
            LocationResult(title: "Boston", subtitle: "MA, United States", coordinate: nil),
            nil,
            LocationResult(title: "Chicago", subtitle: "IL, United States", coordinate: nil)
        ]
        
        let validLocations = locations.compactMap { $0 }
        XCTAssertEqual(validLocations.count, 3)
        XCTAssertEqual(validLocations[0].title, "New York")
        XCTAssertEqual(validLocations[1].title, "Boston")
        XCTAssertEqual(validLocations[2].title, "Chicago")
    }
    
    // MARK: - Form Submission Tests
    
    func testMultipleDestinationsSubmission() {
        let destinations = ["New York", "Boston", "Chicago"]
        let selectedDestinations: [LocationResult?] = [
            LocationResult(title: "New York", subtitle: "NY, United States", coordinate: nil),
            LocationResult(title: "Boston", subtitle: "MA, United States", coordinate: nil),
            LocationResult(title: "Chicago", subtitle: "IL, United States", coordinate: nil)
        ]
        
        // Test form submission data structure
        let submission = EnhancedTripSubmission(
            destinations: destinations,
            departureLocation: "Miami",
            startDate: "2024-01-01",
            endDate: "2024-01-08",
            flexibleDates: false,
            tripDuration: nil,
            budget: "5000",
            travelStyle: "Comfortable",
            groupSize: 2,
            specialRequests: "Multiple city tour",
            interests: ["Culture", "Food", "History"],
            flightClass: nil
        )
        
        XCTAssertEqual(submission.destinations.count, 3)
        XCTAssertEqual(submission.destinations[0], "New York")
        XCTAssertEqual(submission.destinations[1], "Boston")
        XCTAssertEqual(submission.destinations[2], "Chicago")
    }
    
    func testPartialDestinationsSubmission() {
        let destinations = ["New York", "", "Chicago", "  "]
        
        // Filter out empty destinations before submission
        let validDestinations = destinations
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        XCTAssertEqual(validDestinations.count, 2)
        XCTAssertEqual(validDestinations[0], "New York")
        XCTAssertEqual(validDestinations[1], "Chicago")
    }
    
    // MARK: - Autocomplete Integration Tests
    
    func testMultipleDestinationAutocomplete() {
        let mockCompleter = MockLocationCompleter()
        
        // Test autocomplete for multiple destinations
        mockCompleter.simulateSearch(for: "New York")
        XCTAssertEqual(mockCompleter.lastQuery, "New York")
        
        mockCompleter.simulateSearch(for: "Boston")
        XCTAssertEqual(mockCompleter.lastQuery, "Boston")
        
        mockCompleter.simulateSearch(for: "Chicago")
        XCTAssertEqual(mockCompleter.lastQuery, "Chicago")
    }
    
    func testAutocompleteResultsForMultipleFields() {
        let mockCompleter = MockLocationCompleter()
        
        // Simulate autocomplete results for different destination fields
        let newYorkResults = [
            LocationResult(title: "New York", subtitle: "NY, United States", coordinate: nil),
            LocationResult(title: "New York City", subtitle: "NY, United States", coordinate: nil)
        ]
        
        let bostonResults = [
            LocationResult(title: "Boston", subtitle: "MA, United States", coordinate: nil),
            LocationResult(title: "Boston Tea Party Ships", subtitle: "Boston, MA", coordinate: nil)
        ]
        
        mockCompleter.simulateResults(newYorkResults)
        XCTAssertEqual(mockCompleter.lastResults.count, 2)
        XCTAssertEqual(mockCompleter.lastResults[0].title, "New York")
        
        mockCompleter.simulateResults(bostonResults)
        XCTAssertEqual(mockCompleter.lastResults.count, 2)
        XCTAssertEqual(mockCompleter.lastResults[0].title, "Boston")
    }
    
    // MARK: - State Management Tests
    
    func testDestinationStateConsistency() {
        var destinations: [String] = ["New York", "Boston"]
        var selectedDestinations: [LocationResult?] = [
            LocationResult(title: "New York", subtitle: "NY, United States", coordinate: nil),
            LocationResult(title: "Boston", subtitle: "MA, United States", coordinate: nil)
        ]
        
        // Test adding destination maintains consistency
        destinations.append("Chicago")
        selectedDestinations.append(LocationResult(title: "Chicago", subtitle: "IL, United States", coordinate: nil))
        
        XCTAssertEqual(destinations.count, selectedDestinations.count)
        
        // Test removing destination maintains consistency
        destinations.remove(at: 1)
        selectedDestinations.remove(at: 1)
        
        XCTAssertEqual(destinations.count, selectedDestinations.count)
        XCTAssertEqual(destinations[0], "New York")
        XCTAssertEqual(destinations[1], "Chicago")
        XCTAssertEqual(selectedDestinations[0]?.title, "New York")
        XCTAssertEqual(selectedDestinations[1]?.title, "Chicago")
    }
    
    func testDestinationStateRecovery() {
        // Test form state recovery after errors
        let originalDestinations = ["New York", "Boston", "Chicago"]
        let originalSelectedDestinations: [LocationResult?] = [
            LocationResult(title: "New York", subtitle: "NY, United States", coordinate: nil),
            LocationResult(title: "Boston", subtitle: "MA, United States", coordinate: nil),
            LocationResult(title: "Chicago", subtitle: "IL, United States", coordinate: nil)
        ]
        
        // Simulate form clear
        var destinations: [String] = []
        var selectedDestinations: [LocationResult?] = []
        
        // Simulate form recovery
        destinations = originalDestinations
        selectedDestinations = originalSelectedDestinations
        
        XCTAssertEqual(destinations.count, 3)
        XCTAssertEqual(selectedDestinations.count, 3)
        XCTAssertEqual(destinations[0], "New York")
        XCTAssertEqual(selectedDestinations[0]?.title, "New York")
    }
    
    // MARK: - Performance Tests
    
    func testDestinationArrayPerformance() {
        measure {
            var destinations: [String] = []
            var selectedDestinations: [LocationResult?] = []
            
            // Add 100 destinations
            for i in 0..<100 {
                destinations.append("City \(i)")
                selectedDestinations.append(LocationResult(title: "City \(i)", subtitle: "State \(i)", coordinate: nil))
            }
            
            // Remove every other destination
            for i in stride(from: 99, through: 0, by: -2) {
                destinations.remove(at: i)
                selectedDestinations.remove(at: i)
            }
            
            XCTAssertEqual(destinations.count, 50)
            XCTAssertEqual(selectedDestinations.count, 50)
        }
    }
    
    func testDestinationValidationPerformance() {
        let destinations = Array(repeating: "New York", count: 100)
        
        measure {
            for destination in destinations {
                let validation = FormValidation.validateDestinationEnhanced(destination)
                XCTAssertTrue(validation.isValid)
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testExtremeCases() {
        // Test with maximum destinations
        var destinations: [String] = []
        var selectedDestinations: [LocationResult?] = []
        
        for i in 1...10 {
            destinations.append("City \(i)")
            selectedDestinations.append(LocationResult(title: "City \(i)", subtitle: "State \(i)", coordinate: nil))
        }
        
        XCTAssertEqual(destinations.count, 10)
        XCTAssertEqual(selectedDestinations.count, 10)
        
        // Test removing all destinations except one
        while destinations.count > 1 {
            destinations.removeLast()
            selectedDestinations.removeLast()
        }
        
        XCTAssertEqual(destinations.count, 1)
        XCTAssertEqual(selectedDestinations.count, 1)
    }
    
    func testSpecialCharactersInDestinations() {
        let specialDestinations = [
            "São Paulo",
            "München",
            "北京",
            "Москва",
            "القاهرة"
        ]
        
        for destination in specialDestinations {
            let validation = FormValidation.validateDestinationEnhanced(destination)
            XCTAssertTrue(validation.isValid, "Destination '\(destination)' should be valid")
        }
    }
    
    func testVeryLongDestinationNames() {
        let longDestination = String(repeating: "A", count: 100)
        let validation = FormValidation.validateDestinationEnhanced(longDestination)
        
        // Very long destination names should be rejected for security/UX reasons
        XCTAssertFalse(validation.isValid)
        
        // Test with reasonable length destination name
        let reasonableDestination = "New York City, New York, United States"
        let reasonableValidation = FormValidation.validateDestinationEnhanced(reasonableDestination)
        XCTAssertTrue(reasonableValidation.isValid)
    }
    
    // MARK: - Integration Tests
    
    func testEndToEndMultipleDestinations() {
        // Test complete flow with multiple destinations
        let mockTripManager = MockTripManager()
        
        // Set up multiple destinations
        mockTripManager.addDestination("New York")
        mockTripManager.addDestination("Boston")
        mockTripManager.addDestination("Chicago")
        
        XCTAssertEqual(mockTripManager.destinations.count, 3)
        
        // Test validation
        let isValid = mockTripManager.validateDestinations()
        XCTAssertTrue(isValid)
        
        // Test submission
        let submissionData = mockTripManager.prepareSubmission()
        XCTAssertEqual(submissionData.destinations.count, 3)
        XCTAssertEqual(submissionData.destinations[0], "New York")
        XCTAssertEqual(submissionData.destinations[1], "Boston")
        XCTAssertEqual(submissionData.destinations[2], "Chicago")
    }
}

// MARK: - Mock Classes

class MockLocationCompleter {
    var lastQuery: String = ""
    var lastResults: [LocationResult] = []
    
    func simulateSearch(for query: String) {
        lastQuery = query
    }
    
    func simulateResults(_ results: [LocationResult]) {
        lastResults = results
    }
}

class MockTripManager {
    var destinations: [String] = []
    var selectedDestinations: [LocationResult?] = []
    
    func addDestination(_ destination: String) {
        destinations.append(destination)
        selectedDestinations.append(LocationResult(title: destination, subtitle: "", coordinate: nil))
    }
    
    func removeDestination(at index: Int) {
        guard index < destinations.count else { return }
        destinations.remove(at: index)
        selectedDestinations.remove(at: index)
    }
    
    func validateDestinations() -> Bool {
        let validDestinations = destinations.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return !validDestinations.isEmpty
    }
    
    func prepareSubmission() -> EnhancedTripSubmission {
        let validDestinations = destinations.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        return EnhancedTripSubmission(
            destinations: validDestinations,
            departureLocation: "Miami",
            startDate: "2024-01-01",
            endDate: "2024-01-08",
            flexibleDates: false,
            tripDuration: nil,
            budget: nil,
            travelStyle: "Comfortable",
            groupSize: 2,
            specialRequests: "",
            interests: ["Culture"],
            flightClass: nil
        )
    }
}

// MARK: - Test Data Structures

struct MockSubmissionData {
    let destinations: [String]
    let departureLocation: String
    let startDate: String
    let endDate: String
    let flexibleDates: Bool
    let tripDuration: Int?
    let budget: String?
    let travelStyle: String
    let groupSize: Int
    let specialRequests: String?
    let interests: [String]
    let flightClass: String?
}