import XCTest
import SwiftUI
import MapKit
import Combine
@testable import WanderMint

class LocationAutocompleteFieldTests: XCTestCase {
    
    var mockSearchCompleter: MockMKLocalSearchCompleter!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockSearchCompleter = MockMKLocalSearchCompleter()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        mockSearchCompleter = nil
        super.tearDown()
    }
    
    // MARK: - LocationResult Tests
    
    func testLocationResultInitialization() {
        let location = LocationResult(
            title: "New York",
            subtitle: "NY, United States",
            coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        )
        
        XCTAssertEqual(location.title, "New York")
        XCTAssertEqual(location.subtitle, "NY, United States")
        XCTAssertEqual(location.displayName, "New York, NY, United States")
        XCTAssertTrue(location.isCity)
        XCTAssertNotNil(location.coordinate)
    }
    
    func testLocationResultDisplayName() {
        let locationWithSubtitle = LocationResult(
            title: "Central Park",
            subtitle: "New York, NY",
            coordinate: nil
        )
        
        let locationWithoutSubtitle = LocationResult(
            title: "Manhattan",
            subtitle: "",
            coordinate: nil
        )
        
        XCTAssertEqual(locationWithSubtitle.displayName, "Central Park, New York, NY")
        XCTAssertEqual(locationWithoutSubtitle.displayName, "Manhattan")
    }
    
    func testLocationResultIsCityDetection() {
        let cityLocation = LocationResult(
            title: "Boston",
            subtitle: "MA, United States",
            coordinate: nil
        )
        
        let poiLocation = LocationResult(
            title: "Times Square",
            subtitle: "Tourist attraction",
            coordinate: nil
        )
        
        XCTAssertTrue(cityLocation.isCity)
        XCTAssertFalse(poiLocation.isCity)
    }
    
    func testLocationResultEquality() {
        let location1 = LocationResult(title: "Test", subtitle: "Test", coordinate: nil)
        let location2 = LocationResult(title: "Test", subtitle: "Test", coordinate: nil)
        
        // LocationResult uses UUID for equality, so they should be different
        XCTAssertNotEqual(location1, location2)
        XCTAssertEqual(location1, location1)
    }
    
    // MARK: - SearchCompleterDelegate Tests
    
    func testSearchCompleterDelegateResultsHandling() {
        let expectation = expectation(description: "Should receive search results")
        var receivedResults: [LocationResult] = []
        
        let delegate = SearchCompleterDelegate(
            onResults: { results in
                receivedResults = results
                expectation.fulfill()
            },
            onError: { _ in
                XCTFail("Should not receive error")
            },
            onSearchStart: {
                // Search start callback
            }
        )
        
        // Create mock completion results
        let mockResults = [
            MockMKLocalSearchCompletion(title: "San Francisco", subtitle: "CA, United States"),
            MockMKLocalSearchCompletion(title: "Golden Gate Bridge", subtitle: "San Francisco, CA")
        ]
        
        // Simulate the delegate receiving results
        delegate.simulateResults(mockResults)
        
        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertEqual(receivedResults.count, 2)
            XCTAssertEqual(receivedResults[0].title, "San Francisco")
            XCTAssertEqual(receivedResults[0].subtitle, "CA, United States")
            XCTAssertEqual(receivedResults[1].title, "Golden Gate Bridge")
            XCTAssertEqual(receivedResults[1].subtitle, "San Francisco, CA")
        }
    }
    
    func testSearchCompleterDelegateErrorHandling() {
        let expectation = expectation(description: "Should receive error")
        var receivedError: Error?
        
        let delegate = SearchCompleterDelegate(
            onResults: { _ in
                XCTFail("Should not receive results")
            },
            onError: { error in
                receivedError = error
                expectation.fulfill()
            },
            onSearchStart: {
                // Search start callback
            }
        )
        
        // Simulate an error
        let mockError = NSError(domain: "TestDomain", code: 123, userInfo: nil)
        delegate.simulateError(mockError)
        
        waitForExpectations(timeout: 1.0) { _ in
            XCTAssertNotNil(receivedError)
            XCTAssertEqual((receivedError as NSError?)?.code, 123)
        }
    }
    
    // MARK: - Integration Tests
    
    func testLocationAutocompleteFieldInitialization() {
        let text = Binding<String>(get: { "Test" }, set: { _ in })
        let selectedLocation = Binding<LocationResult?>(get: { nil }, set: { _ in })
        
        let field = LocationAutocompleteField(
            title: "Test Title",
            placeholder: "Test Placeholder",
            text: text,
            selectedLocation: selectedLocation
        )
        
        // Test that the field can be initialized without crashing
        XCTAssertNotNil(field)
    }
    
    func testLocationAutocompleteFieldTextBinding() {
        var textValue = ""
        let text = Binding<String>(
            get: { textValue },
            set: { textValue = $0 }
        )
        
        let selectedLocation = Binding<LocationResult?>(get: { nil }, set: { _ in })
        
        let field = LocationAutocompleteField(
            title: "Test Title",
            placeholder: "Test Placeholder",
            text: text,
            selectedLocation: selectedLocation
        )
        
        // Update the text binding
        text.wrappedValue = "New York"
        XCTAssertEqual(textValue, "New York")
    }
    
    func testLocationAutocompleteFieldSelectedLocationBinding() {
        let text = Binding<String>(get: { "" }, set: { _ in })
        var selectedLocationValue: LocationResult?
        
        let selectedLocation = Binding<LocationResult?>(
            get: { selectedLocationValue },
            set: { selectedLocationValue = $0 }
        )
        
        let field = LocationAutocompleteField(
            title: "Test Title",
            placeholder: "Test Placeholder",
            text: text,
            selectedLocation: selectedLocation
        )
        
        // Update the selected location binding
        let testLocation = LocationResult(title: "Test Location", subtitle: "Test Subtitle", coordinate: nil)
        selectedLocation.wrappedValue = testLocation
        
        XCTAssertEqual(selectedLocationValue?.title, "Test Location")
        XCTAssertEqual(selectedLocationValue?.subtitle, "Test Subtitle")
    }
    
    // MARK: - Performance Tests
    
    func testLocationResultCreationPerformance() {
        measure {
            for i in 0..<1000 {
                let location = LocationResult(
                    title: "Location \(i)",
                    subtitle: "Subtitle \(i)",
                    coordinate: CLLocationCoordinate2D(latitude: Double(i), longitude: Double(i))
                )
                XCTAssertNotNil(location)
            }
        }
    }
    
    func testSearchResultsProcessingPerformance() {
        let mockResults = (0..<100).map { i in
            MockMKLocalSearchCompletion(title: "Location \(i)", subtitle: "Subtitle \(i)")
        }
        
        measure {
            let delegate = SearchCompleterDelegate(
                onResults: { _ in },
                onError: { _ in },
                onSearchStart: { }
            )
            
            delegate.simulateResults(mockResults)
        }
    }
}

// MARK: - Mock Classes

class MockMKLocalSearchCompleter: MKLocalSearchCompleter {
    var mockResults: [MKLocalSearchCompletion] = []
    var mockError: Error?
    
    override var results: [MKLocalSearchCompletion] {
        return mockResults
    }
    
    func simulateResults(_ results: [MKLocalSearchCompletion]) {
        mockResults = results
        delegate?.completerDidUpdateResults?(self)
    }
    
    func simulateError(_ error: Error) {
        mockError = error
        delegate?.completer?(self, didFailWithError: error)
    }
}

class MockMKLocalSearchCompletion: MKLocalSearchCompletion {
    private let _title: String
    private let _subtitle: String
    
    init(title: String, subtitle: String) {
        self._title = title
        self._subtitle = subtitle
        super.init()
    }
    
    override var title: String {
        return _title
    }
    
    override var subtitle: String {
        return _subtitle
    }
}

// MARK: - Extension for Testing

extension SearchCompleterDelegate {
    func simulateResults(_ results: [MKLocalSearchCompletion]) {
        // Use the actual delegate method to simulate results
        let mockCompleter = MockMKLocalSearchCompleter()
        mockCompleter.mockResults = results
        completerDidUpdateResults(mockCompleter)
    }
    
    func simulateError(_ error: Error) {
        // Use the actual delegate method to simulate error
        let mockCompleter = MockMKLocalSearchCompleter()
        mockCompleter.mockError = error
        completer(mockCompleter, didFailWithError: error)
    }
}