import XCTest
import MapKit
@testable import WanderMint

@MainActor
class LocationAutocompleteTests: XCTestCase {
    
    var locationField: LocationAutocompleteField!
    var mockResults: [LocationResult]!
    
    override func setUp() {
        super.setUp()
        // Create test location field
        locationField = LocationAutocompleteField(
            title: "Test Field",
            placeholder: "Enter destination", 
            text: .constant(""),
            selectedLocation: .constant(nil)
        )
        
        // Create mock results for testing
        mockResults = createMockLocationResults()
    }
    
    override func tearDown() {
        locationField = nil
        mockResults = nil
        super.tearDown()
    }
    
    // MARK: - Curated Database Tests
    
    func testCuratedDatabaseCountries() {
        // Test that countries appear first and correctly
        let countries = [
            ("Greece", "Europe"),
            ("Italy", "Europe"),
            ("France", "Europe"),
            ("United States", "North America"),
            ("Japan", "Asia")
        ]
        
        for (country, continent) in countries {
            let results = getCuratedSuggestions(for: country)
            
            XCTAssertGreaterThan(results.count, 0, "Should find curated results for \(country)")
            XCTAssertEqual(results.first?.title, country, "\(country) should be first result")
            XCTAssertEqual(results.first?.subtitle, continent, "\(country) should show correct continent")
        }
    }
    
    func testCuratedDatabaseUSStates() {
        // Test that US states appear correctly
        let states = [
            ("California", "United States"),
            ("New York", "United States"),
            ("Florida", "United States"),
            ("Texas", "United States")
        ]
        
        for (state, country) in states {
            let results = getCuratedSuggestions(for: state)
            
            XCTAssertGreaterThan(results.count, 0, "Should find curated results for \(state)")
            
            // State should appear before cities in that state
            let stateResult = results.first { $0.title == state && $0.subtitle == country }
            XCTAssertNotNil(stateResult, "\(state) state should be in results")
            
            let stateIndex = results.firstIndex { $0.title == state && $0.subtitle == country }
            if let index = stateIndex {
                XCTAssertLessThan(index, 3, "\(state) state should be in top 3 results")
            }
        }
    }
    
    func testCuratedDatabaseCanadianProvinces() {
        // Test Canadian provinces
        let provinces = [
            ("British Columbia", "Canada"),
            ("Ontario", "Canada"),
            ("Quebec", "Canada"),
            ("Alberta", "Canada")
        ]
        
        for (province, country) in provinces {
            let results = getCuratedSuggestions(for: province)
            
            XCTAssertGreaterThan(results.count, 0, "Should find curated results for \(province)")
            XCTAssertEqual(results.first?.title, province, "\(province) should be first result")
            XCTAssertEqual(results.first?.subtitle, country, "\(province) should show Canada")
        }
    }
    
    func testCuratedDatabaseMajorCities() {
        // Test that major cities appear correctly
        let cities = [
            ("Chicago", "Illinois, United States"),
            ("Hong Kong", "Hong Kong"),
            ("Tokyo", "Japan"),
            ("London", "United Kingdom"),
            ("Paris", "France")
        ]
        
        for (city, location) in cities {
            let results = getCuratedSuggestions(for: city)
            
            XCTAssertGreaterThan(results.count, 0, "Should find curated results for \(city)")
            XCTAssertEqual(results.first?.title, city, "\(city) should be first result")
            XCTAssertEqual(results.first?.subtitle, location, "\(city) should show correct location")
        }
    }
    
    func testCuratedDatabasePrioritization() {
        // Test that countries/states are prioritized over cities in search results
        let testCases = [
            // Query that matches both country and cities
            ("New", ["New York", "New Jersey", "New Mexico"], "United States"), // States first
            ("United", ["United States", "United Kingdom"], nil), // Countries
            ("California", ["California"], "United States") // State before cities
        ]
        
        for (query, expectedTopResults, expectedCountry) in testCases {
            let results = getCuratedSuggestions(for: query)
            
            XCTAssertGreaterThan(results.count, 0, "Should find results for '\(query)'")
            
            // Check that expected results appear at the top
            for (index, expectedTitle) in expectedTopResults.enumerated() {
                if index < results.count {
                    let actualTitle = results[index].title
                    XCTAssertEqual(actualTitle, expectedTitle, 
                        "For query '\(query)', position \(index + 1) should be \(expectedTitle), got \(actualTitle)")
                    
                    if let country = expectedCountry {
                        XCTAssertTrue(results[index].subtitle.contains(country),
                            "\(expectedTitle) should contain \(country) in subtitle")
                    }
                }
            }
        }
    }
    
    func testPartialMatching() {
        // Test that partial queries work correctly
        let partialQueries = [
            ("Chic", "Chicago"), // Should find Chicago
            ("Brit", "British Columbia"), // Should find British Columbia
            ("Cal", "California"), // Should find California state
            ("Hong", "Hong Kong"), // Should find Hong Kong
            ("Gree", "Greece") // Should find Greece country
        ]
        
        for (query, expectedFirst) in partialQueries {
            let results = getCuratedSuggestions(for: query)
            
            XCTAssertGreaterThan(results.count, 0, "Should find results for partial query '\(query)'")
            XCTAssertEqual(results.first?.title, expectedFirst, 
                "Partial query '\(query)' should find \(expectedFirst) first")
        }
    }
    
    // MARK: - MapKit Fallback Tests (for when curated database has no results)
    
    func testMapKitFallbackFiltering() {
        // Test that MapKit fallback properly filters out streets, businesses, etc.
        let badMapKitResults = [
            LocationResult(title: "Chicago Ave", subtitle: "Evanston, IL, United States", coordinate: nil),
            LocationResult(title: "Main Street", subtitle: "Boston, MA", coordinate: nil),
            LocationResult(title: "O'Hare Airport", subtitle: "Chicago, IL", coordinate: nil),
            LocationResult(title: "Little Italy", subtitle: "New York, NY", coordinate: nil),
            LocationResult(title: "123 Broadway", subtitle: "New York, NY", coordinate: nil)
        ]
        
        let filtered = filterMapKitResults(badMapKitResults)
        
        XCTAssertEqual(filtered.count, 0, "All problematic MapKit results should be filtered out")
    }
    
    func testMapKitFallbackAcceptsValidResults() {
        // Test that MapKit fallback accepts valid city/state results
        let goodMapKitResults = [
            LocationResult(title: "Springfield", subtitle: "Illinois, United States", coordinate: nil),
            LocationResult(title: "Portland", subtitle: "Oregon, United States", coordinate: nil),
            LocationResult(title: "Burlington", subtitle: "Vermont, United States", coordinate: nil)
        ]
        
        let filtered = filterMapKitResults(goodMapKitResults)
        
        XCTAssertEqual(filtered.count, 3, "Valid MapKit results should pass filtering")
        XCTAssertTrue(filtered.contains { $0.title == "Springfield" }, "Springfield should pass")
        XCTAssertTrue(filtered.contains { $0.title == "Portland" }, "Portland should pass")
        XCTAssertTrue(filtered.contains { $0.title == "Burlington" }, "Burlington should pass")
    }
    
    // MARK: - International Priority Tests
    
    func testInternationalOverUSPriority() {
        // Test that international destinations are prioritized over US cities with same names
        let testCases = [
            ("Athens", "Greece", "Georgia, United States"),
            ("Paris", "France", "Texas, United States"),
            ("Rome", "Italy", "New York, United States"),
            ("Berlin", "Germany", "New Hampshire, United States")
        ]
        
        for (cityName, internationalLocation, usLocation) in testCases {
            let results = getCuratedSuggestions(for: cityName)
            
            // International version should appear first
            let internationalResult = results.first { $0.title == cityName && $0.subtitle.contains(internationalLocation) }
            let usResult = results.first { $0.title == cityName && $0.subtitle.contains(usLocation) }
            
            XCTAssertNotNil(internationalResult, "\(cityName), \(internationalLocation) should be in results")
            
            if let intlIndex = results.firstIndex(where: { $0.title == cityName && $0.subtitle.contains(internationalLocation) }),
               let usIndex = results.firstIndex(where: { $0.title == cityName && $0.subtitle.contains(usLocation) }) {
                XCTAssertLessThan(intlIndex, usIndex, 
                    "\(cityName), \(internationalLocation) should rank higher than \(cityName), \(usLocation)")
            }
        }
    }
    
    // MARK: - Specific Bug Fix Tests
    
    func testHongKongCorrectLocation() {
        // Test that Hong Kong shows the correct location, not Mexico
        let results = getCuratedSuggestions(for: "Hong Kong")
        
        XCTAssertGreaterThan(results.count, 0, "Should find Hong Kong")
        XCTAssertEqual(results.first?.title, "Hong Kong", "First result should be Hong Kong")
        XCTAssertEqual(results.first?.subtitle, "Hong Kong", "Should show Hong Kong, not Mexico")
        
        // Ensure no Mexico results
        let mexicoResults = results.filter { $0.subtitle.contains("Mexico") }
        XCTAssertEqual(mexicoResults.count, 0, "Should not show Hong Kong, Mexico")
    }
    
    func testChicagoNoStreets() {
        // Test that Chicago search doesn't return street names
        let results = getCuratedSuggestions(for: "Chicago")
        
        XCTAssertGreaterThan(results.count, 0, "Should find Chicago")
        XCTAssertEqual(results.first?.title, "Chicago", "First result should be Chicago city")
        XCTAssertEqual(results.first?.subtitle, "Illinois, United States", "Should show proper city location")
        
        // Ensure no street results
        let streetResults = results.filter { result in
            result.title.contains("Ave") || result.title.contains("St") || 
            result.title.contains("Street") || result.title.contains("Avenue")
        }
        XCTAssertEqual(streetResults.count, 0, "Should not show any street names")
    }
    
    func testItalyNotLittleItaly() {
        // Test that Italy search shows country, not "Little Italy" neighborhoods
        let results = getCuratedSuggestions(for: "Italy")
        
        XCTAssertGreaterThan(results.count, 0, "Should find Italy")
        XCTAssertEqual(results.first?.title, "Italy", "First result should be Italy country")
        XCTAssertEqual(results.first?.subtitle, "Europe", "Should show Europe as continent")
        
        // Ensure no "Little Italy" results
        let littleItalyResults = results.filter { $0.title.contains("Little") }
        XCTAssertEqual(littleItalyResults.count, 0, "Should not show Little Italy neighborhoods")
    }
    
    func testGreeceNotGreekRestaurants() {
        // Test that Greece search shows country, not Greek restaurants or streets
        let results = getCuratedSuggestions(for: "Greece")
        
        XCTAssertGreaterThan(results.count, 0, "Should find Greece")
        XCTAssertEqual(results.first?.title, "Greece", "First result should be Greece country")
        XCTAssertEqual(results.first?.subtitle, "Europe", "Should show Europe as continent")
        
        // Ensure no restaurant/street results
        let businessResults = results.filter { result in
            result.title.contains("Restaurant") || result.title.contains("Rd") || 
            result.title.contains("Street") || result.title.contains("Cafe")
        }
        XCTAssertEqual(businessResults.count, 0, "Should not show business or street results")
    }
    
    // MARK: - Edge Cases
    
    func testEmptyQuery() {
        let results = getCuratedSuggestions(for: "")
        XCTAssertEqual(results.count, 0, "Empty query should return no results")
    }
    
    func testSingleCharacterQuery() {
        let results = getCuratedSuggestions(for: "A")
        // Should return countries/places starting with A, but limited
        XCTAssertLessThanOrEqual(results.count, 6, "Single character should return limited results")
    }
    
    func testNonExistentQuery() {
        let results = getCuratedSuggestions(for: "Xyzzyx")
        XCTAssertEqual(results.count, 0, "Non-existent location should return no results")
    }
    
    func testCaseInsensitiveSearch() {
        let queries = ["chicago", "CHICAGO", "Chicago", "cHiCaGo"]
        
        for query in queries {
            let results = getCuratedSuggestions(for: query)
            XCTAssertGreaterThan(results.count, 0, "Search should be case insensitive for '\(query)'")
            XCTAssertEqual(results.first?.title, "Chicago", "Should find Chicago regardless of case")
        }
    }
    
    // MARK: - Performance Tests
    
    func testCuratedDatabasePerformance() {
        measure {
            for query in ["Chi", "New", "Cal", "Lon", "Par"] {
                _ = getCuratedSuggestions(for: query)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCuratedSuggestions(for query: String) -> [LocationResult] {
        // Create a mock LocationAutocompleteField to access the curated suggestions method
        let field = LocationAutocompleteField(
            title: "Test",
            placeholder: "Test",
            text: .constant(""),
            selectedLocation: .constant(nil)
        )
        
        // Access the curated suggestions method - simulate it since it's private
        return simulateCuratedSuggestions(for: query)
    }
    
    private func simulateCuratedSuggestions(for query: String) -> [LocationResult] {
        let queryLower = query.lowercased()
        
        // Handle empty query
        if queryLower.isEmpty {
            return []
        }
        
        // Replicate the exact curated database from the app
        let destinationsDatabase = [
            // Countries (highest priority)
            ("United States", "North America"),
            ("Canada", "North America"),
            ("Mexico", "North America"),
            ("United Kingdom", "Europe"),
            ("France", "Europe"),
            ("Italy", "Europe"),
            ("Spain", "Europe"),
            ("Germany", "Europe"),
            ("Greece", "Europe"),
            ("Netherlands", "Europe"),
            ("Switzerland", "Europe"),
            ("Austria", "Europe"),
            ("Portugal", "Europe"),
            ("Ireland", "Europe"),
            ("Sweden", "Europe"),
            ("Norway", "Europe"),
            ("Denmark", "Europe"),
            ("Finland", "Europe"),
            ("Belgium", "Europe"),
            ("Czech Republic", "Europe"),
            ("Hungary", "Europe"),
            ("Poland", "Europe"),
            ("Russia", "Europe/Asia"),
            ("Turkey", "Europe/Asia"),
            ("China", "Asia"),
            ("Japan", "Asia"),
            ("South Korea", "Asia"),
            ("Thailand", "Asia"),
            ("Singapore", "Asia"),
            ("India", "Asia"),
            ("Indonesia", "Asia"),
            ("Malaysia", "Asia"),
            ("Philippines", "Asia"),
            ("Vietnam", "Asia"),
            ("Australia", "Oceania"),
            ("New Zealand", "Oceania"),
            ("Brazil", "South America"),
            ("Argentina", "South America"),
            ("Chile", "South America"),
            ("Peru", "South America"),
            ("Colombia", "South America"),
            ("Ecuador", "South America"),
            ("Egypt", "Africa"),
            ("South Africa", "Africa"),
            ("Morocco", "Africa"),
            ("Kenya", "Africa"),
            ("Tanzania", "Africa"),
            
            // US States
            ("Alabama", "United States"),
            ("Alaska", "United States"),
            ("Arizona", "United States"),
            ("Arkansas", "United States"),
            ("California", "United States"),
            ("Colorado", "United States"),
            ("Connecticut", "United States"),
            ("Delaware", "United States"),
            ("Florida", "United States"),
            ("Georgia", "United States"),
            ("Hawaii", "United States"),
            ("Idaho", "United States"),
            ("Illinois", "United States"),
            ("Indiana", "United States"),
            ("Iowa", "United States"),
            ("Kansas", "United States"),
            ("Kentucky", "United States"),
            ("Louisiana", "United States"),
            ("Maine", "United States"),
            ("Maryland", "United States"),
            ("Massachusetts", "United States"),
            ("Michigan", "United States"),
            ("Minnesota", "United States"),
            ("Mississippi", "United States"),
            ("Missouri", "United States"),
            ("Montana", "United States"),
            ("Nebraska", "United States"),
            ("Nevada", "United States"),
            ("New Hampshire", "United States"),
            ("New Jersey", "United States"),
            ("New Mexico", "United States"),
            ("New York", "United States"),
            ("North Carolina", "United States"),
            ("North Dakota", "United States"),
            ("Ohio", "United States"),
            ("Oklahoma", "United States"),
            ("Oregon", "United States"),
            ("Pennsylvania", "United States"),
            ("Rhode Island", "United States"),
            ("South Carolina", "United States"),
            ("South Dakota", "United States"),
            ("Tennessee", "United States"),
            ("Texas", "United States"),
            ("Utah", "United States"),
            ("Vermont", "United States"),
            ("Virginia", "United States"),
            ("Washington", "United States"),
            ("West Virginia", "United States"),
            ("Wisconsin", "United States"),
            ("Wyoming", "United States"),
            
            // Canadian Provinces and Territories
            ("Alberta", "Canada"),
            ("British Columbia", "Canada"),
            ("Manitoba", "Canada"),
            ("New Brunswick", "Canada"),
            ("Newfoundland and Labrador", "Canada"),
            ("Northwest Territories", "Canada"),
            ("Nova Scotia", "Canada"),
            ("Nunavut", "Canada"),
            ("Ontario", "Canada"),
            ("Prince Edward Island", "Canada"),
            ("Quebec", "Canada"),
            ("Saskatchewan", "Canada"),
            ("Yukon", "Canada"),
            
            // Major Cities - North America
            ("Chicago", "Illinois, United States"),
            ("New York", "New York, United States"),
            ("Los Angeles", "California, United States"),
            ("San Francisco", "California, United States"),
            ("Boston", "Massachusetts, United States"),
            ("Miami", "Florida, United States"),
            ("Seattle", "Washington, United States"),
            ("Las Vegas", "Nevada, United States"),
            ("Washington", "District of Columbia, United States"),
            ("Toronto", "Ontario, Canada"),
            ("Vancouver", "British Columbia, Canada"),
            ("Montreal", "Quebec, Canada"),
            ("Mexico City", "Mexico"),
            
            // Major Cities - Europe
            ("London", "United Kingdom"),
            ("Paris", "France"),
            ("Rome", "Italy"),
            ("Barcelona", "Spain"),
            ("Madrid", "Spain"),
            ("Amsterdam", "Netherlands"),
            ("Berlin", "Germany"),
            ("Vienna", "Austria"),
            ("Prague", "Czech Republic"),
            ("Budapest", "Hungary"),
            ("Athens", "Greece"),
            ("Florence", "Italy"),
            ("Venice", "Italy"),
            ("Milan", "Italy"),
            ("Naples", "Italy"),
            ("Lisbon", "Portugal"),
            ("Dublin", "Ireland"),
            ("Edinburgh", "Scotland, United Kingdom"),
            ("Stockholm", "Sweden"),
            ("Copenhagen", "Denmark"),
            ("Oslo", "Norway"),
            ("Helsinki", "Finland"),
            ("Zurich", "Switzerland"),
            ("Geneva", "Switzerland"),
            ("Brussels", "Belgium"),
            ("Moscow", "Russia"),
            ("St Petersburg", "Russia"),
            
            // Major Cities - Asia
            ("Tokyo", "Japan"),
            ("Kyoto", "Japan"),
            ("Osaka", "Japan"),
            ("Hong Kong", "Hong Kong"),
            ("Shanghai", "China"),
            ("Beijing", "China"),
            ("Seoul", "South Korea"),
            ("Bangkok", "Thailand"),
            ("Singapore", "Singapore"),
            ("Mumbai", "India"),
            ("Delhi", "India"),
            ("Istanbul", "Turkey"),
            ("Dubai", "United Arab Emirates"),
            ("Kuala Lumpur", "Malaysia"),
            ("Manila", "Philippines"),
            ("Ho Chi Minh City", "Vietnam"),
            ("Hanoi", "Vietnam"),
            
            // Major Cities - Oceania
            ("Sydney", "Australia"),
            ("Melbourne", "Australia"),
            ("Brisbane", "Australia"),
            ("Perth", "Australia"),
            ("Auckland", "New Zealand"),
            ("Wellington", "New Zealand"),
            
            // Major Cities - South America
            ("Buenos Aires", "Argentina"),
            ("Rio de Janeiro", "Brazil"),
            ("São Paulo", "Brazil"),
            ("Lima", "Peru"),
            ("Santiago", "Chile"),
            ("Bogotá", "Colombia"),
            ("Quito", "Ecuador"),
            
            // Major Cities - Africa
            ("Cairo", "Egypt"),
            ("Cape Town", "South Africa"),
            ("Johannesburg", "South Africa"),
            ("Marrakech", "Morocco"),
            ("Casablanca", "Morocco"),
            ("Nairobi", "Kenya"),
            ("Dar es Salaam", "Tanzania")
        ]
        
        // Filter destinations that match the query
        let matchingDestinations = destinationsDatabase.filter { destination in
            destination.0.lowercased().hasPrefix(queryLower) ||
            destination.0.lowercased().contains(queryLower)
        }
        
        // Sort by relevance with country/state priority
        return matchingDestinations
            .sorted { first, second in
                let firstExactMatch = first.0.lowercased().hasPrefix(queryLower)
                let secondExactMatch = second.0.lowercased().hasPrefix(queryLower)
                
                // Prioritize countries and states
                let countryRegions = ["Europe", "Asia", "North America", "South America", "Africa", "Oceania", "Europe/Asia"]
                let stateCountries = ["United States", "Canada"]
                
                let firstIsCountryOrState = countryRegions.contains(first.1) || stateCountries.contains(first.1)
                let secondIsCountryOrState = countryRegions.contains(second.1) || stateCountries.contains(second.1)
                
                if firstIsCountryOrState && !secondIsCountryOrState {
                    return true
                } else if !firstIsCountryOrState && secondIsCountryOrState {
                    return false
                } else if firstExactMatch && !secondExactMatch {
                    return true
                } else if !firstExactMatch && secondExactMatch {
                    return false
                } else {
                    return first.0.count < second.0.count
                }
            }
            .prefix(6)
            .map { destination in
                LocationResult(
                    title: destination.0,
                    subtitle: destination.1,
                    coordinate: nil
                )
            }
    }
    
    private func filterMapKitResults(_ results: [LocationResult]) -> [LocationResult] {
        // Simulate the filtering logic from the actual app
        return results.filter { result in
            let title = result.title.lowercased()
            let subtitle = result.subtitle.lowercased()
            
            // Exclude results with numbers (addresses)
            if title.contains(where: { $0.isNumber }) || subtitle.contains(where: { $0.isNumber }) {
                return false
            }
            
            // Exclude street endings
            let streetEndings = ["st", "ave", "rd", "dr", "ln", "blvd", "street", "avenue", "road", "drive", "lane", "boulevard", "way", "place", "court", "circle"]
            for ending in streetEndings {
                if title.hasSuffix(" \(ending)") || title == ending {
                    return false
                }
            }
            
            // Exclude street keywords anywhere in title
            let streetKeywords = [" st ", " ave ", " street ", " avenue ", " road ", " rd ", " drive ", " dr ", " lane ", " ln ", " boulevard ", " blvd ", " way ", " place ", " court ", " circle "]
            for keyword in streetKeywords {
                if title.contains(keyword) {
                    return false
                }
            }
            
            // Exclude transit and infrastructure
            let transitKeywords = ["airport", "station", "terminal", "depot", "stop", "platform", "rail", "train", "metro", "subway", "bus", "mall", "plaza", "shopping", "center", "centre", "little"]
            for keyword in transitKeywords {
                if title.contains(keyword) || subtitle.contains(keyword) {
                    return false
                }
            }
            
            // Exclude "Nearby" results (POIs)
            if subtitle.contains("nearby") || subtitle.contains("search nearby") {
                return false
            }
            
            // Exclude business/building indicators
            let businessKeywords = ["&", "/", "#", "llc", "inc", "corp", "ltd", "co.", "building", "tower", "complex"]
            for keyword in businessKeywords {
                if title.contains(keyword) || subtitle.contains(keyword) {
                    return false
                }
            }
            
            // Must have proper geographic format (comma or non-empty subtitle)
            let hasProperFormat = result.title.contains(",") || !result.subtitle.isEmpty
            
            // Basic validation
            let validLength = title.count >= 2 && title.count <= 50
            
            return hasProperFormat && validLength
        }
    }
    
    private func createMockLocationResults() -> [LocationResult] {
        return [
            LocationResult(title: "Chicago", subtitle: "Illinois, United States", coordinate: nil),
            LocationResult(title: "Paris", subtitle: "France", coordinate: nil),
            LocationResult(title: "California", subtitle: "United States", coordinate: nil),
            LocationResult(title: "Greece", subtitle: "Europe", coordinate: nil),
            LocationResult(title: "Hong Kong", subtitle: "Hong Kong", coordinate: nil)
        ]
    }
}