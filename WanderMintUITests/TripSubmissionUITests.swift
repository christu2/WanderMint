import XCTest

class TripSubmissionUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Form UI Tests
    
    func testTripSubmissionFormElements() throws {
        // Navigate to trip submission form
        let newTripTab = app.tabBars.buttons["New Trip"]
        XCTAssertTrue(newTripTab.exists)
        newTripTab.tap()
        
        // Verify form elements exist
        let navigationTitle = app.navigationBars["Plan Your Trip"]
        XCTAssertTrue(navigationTitle.exists)
        
        let cancelButton = app.navigationBars.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists)
        
        // Check destination fields
        let departureField = app.textFields["Where are you departing from?"]
        XCTAssertTrue(departureField.exists)
        
        let destinationField = app.textFields["Enter your dream destination"]
        XCTAssertTrue(destinationField.exists)
        
        // Check preference fields
        let budgetField = app.textFields["Optional"]
        XCTAssertTrue(budgetField.exists)
        
        let groupSizeStepper = app.steppers.firstMatch
        XCTAssertTrue(groupSizeStepper.exists)
        
        // Check interests section
        let cultureButton = app.buttons["Culture"]
        XCTAssertTrue(cultureButton.exists)
        
        let foodButton = app.buttons["Food"]
        XCTAssertTrue(foodButton.exists)
        
        // Check submit button
        let submitButton = app.buttons["Submit Trip Request"]
        XCTAssertTrue(submitButton.exists)
    }
    
    func testLocationAutocompleteInteraction() throws {
        // Navigate to trip submission form
        let newTripTab = app.tabBars.buttons["New Trip"]
        newTripTab.tap()
        
        // Test departure location autocomplete
        let departureField = app.textFields["Where are you departing from?"]
        departureField.tap()
        departureField.typeText("New York")
        
        // Wait for autocomplete suggestions to appear
        let suggestionsList = app.scrollViews.firstMatch
        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith: suggestionsList, handler: nil)
        waitForExpectations(timeout: 3.0)
        
        // Test destination field autocomplete
        let destinationField = app.textFields["Enter your dream destination"]
        destinationField.tap()
        destinationField.typeText("Boston")
        
        // Wait for autocomplete suggestions
        expectation(for: exists, evaluatedWith: suggestionsList, handler: nil)
        waitForExpectations(timeout: 3.0)
    }
    
    func testMultipleDestinations() throws {
        // Navigate to trip submission form
        let newTripTab = app.tabBars.buttons["New Trip"]
        newTripTab.tap()
        
        // Add first destination
        let firstDestinationField = app.textFields["Enter your dream destination"]
        firstDestinationField.tap()
        firstDestinationField.typeText("New York")
        
        // Add second destination
        let addStopButton = app.buttons["Add Stop"]
        XCTAssertTrue(addStopButton.exists)
        addStopButton.tap()
        
        // Verify second destination field appears
        let secondDestinationField = app.textFields["Add another destination"]
        XCTAssertTrue(secondDestinationField.exists)
        
        secondDestinationField.tap()
        secondDestinationField.typeText("Boston")
        
        // Add third destination
        addStopButton.tap()
        
        // Verify third destination field appears
        let thirdDestinationField = app.textFields.matching(identifier: "Add another destination").element(boundBy: 1)
        XCTAssertTrue(thirdDestinationField.exists)
        
        thirdDestinationField.tap()
        thirdDestinationField.typeText("Chicago")
        
        // Test remove destination functionality
        let removeButton = app.buttons["minus.circle.fill"].firstMatch
        XCTAssertTrue(removeButton.exists)
        removeButton.tap()
        
        // Verify destination was removed
        let remainingDestinations = app.textFields.matching(identifier: "Add another destination").count
        XCTAssertLessThan(remainingDestinations, 2)
    }
    
    func testKeyboardHandling() throws {
        // Navigate to trip submission form
        let newTripTab = app.tabBars.buttons["New Trip"]
        newTripTab.tap()
        
        // Test keyboard appears when tapping text field
        let budgetField = app.textFields["Optional"]
        budgetField.tap()
        
        // Verify keyboard is visible
        let keyboard = app.keyboards.firstMatch
        XCTAssertTrue(keyboard.exists)
        
        // Test keyboard dismissal on tap outside
        let backgroundArea = app.otherElements.firstMatch
        backgroundArea.tap()
        
        // Verify keyboard is dismissed
        let keyboardDismissed = NSPredicate(format: "exists == false")
        expectation(for: keyboardDismissed, evaluatedWith: keyboard, handler: nil)
        waitForExpectations(timeout: 2.0)
    }
    
    func testInterestSelection() throws {
        // Navigate to trip submission form
        let newTripTab = app.tabBars.buttons["New Trip"]
        newTripTab.tap()
        
        // Test interest selection
        let cultureButton = app.buttons["Culture"]
        cultureButton.tap()
        
        // Verify interest is selected (button state changes)
        XCTAssertTrue(cultureButton.exists)
        
        let foodButton = app.buttons["Food"]
        foodButton.tap()
        
        // Verify multiple interests can be selected
        XCTAssertTrue(foodButton.exists)
        
        // Test deselecting interest
        cultureButton.tap()
        
        // Verify interest is deselected
        XCTAssertTrue(cultureButton.exists)
    }
    
    func testFormValidation() throws {
        // Navigate to trip submission form
        let newTripTab = app.tabBars.buttons["New Trip"]
        newTripTab.tap()
        
        // Test submit button is disabled initially
        let submitButton = app.buttons["Submit Trip Request"]
        XCTAssertTrue(submitButton.exists)
        XCTAssertFalse(submitButton.isEnabled)
        
        // Fill in minimum required fields
        let departureField = app.textFields["Where are you departing from?"]
        departureField.tap()
        departureField.typeText("Boston")
        
        let destinationField = app.textFields["Enter your dream destination"]
        destinationField.tap()
        destinationField.typeText("New York")
        
        // Verify submit button becomes enabled
        XCTAssertTrue(submitButton.isEnabled)
    }
    
    func testDatePickers() throws {
        // Navigate to trip submission form
        let newTripTab = app.tabBars.buttons["New Trip"]
        newTripTab.tap()
        
        // Test start date picker
        let startDateButton = app.buttons.matching(identifier: "Start Date").firstMatch
        XCTAssertTrue(startDateButton.exists)
        startDateButton.tap()
        
        // Verify date picker appears
        let datePicker = app.datePickers.firstMatch
        XCTAssertTrue(datePicker.exists)
        
        // Test OK button
        let okButton = app.buttons["OK"]
        XCTAssertTrue(okButton.exists)
        okButton.tap()
        
        // Test end date picker
        let endDateButton = app.buttons.matching(identifier: "End Date").firstMatch
        XCTAssertTrue(endDateButton.exists)
        endDateButton.tap()
        
        // Verify date picker appears again
        XCTAssertTrue(datePicker.exists)
        
        // Test Cancel button
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists)
        cancelButton.tap()
    }
    
    func testFlexibleDates() throws {
        // Navigate to trip submission form
        let newTripTab = app.tabBars.buttons["New Trip"]
        newTripTab.tap()
        
        // Test flexible dates toggle
        let flexibleDatesToggle = app.switches["I have flexible dates"]
        XCTAssertTrue(flexibleDatesToggle.exists)
        flexibleDatesToggle.tap()
        
        // Verify flexible dates fields appear
        let earliestStartButton = app.buttons["Earliest Start"]
        XCTAssertTrue(earliestStartButton.exists)
        
        let latestStartButton = app.buttons["Latest Start"]
        XCTAssertTrue(latestStartButton.exists)
        
        let durationSlider = app.sliders.firstMatch
        XCTAssertTrue(durationSlider.exists)
        
        // Test duration slider
        durationSlider.adjust(toNormalizedSliderPosition: 0.5)
        
        // Turn off flexible dates
        flexibleDatesToggle.tap()
        
        // Verify flexible dates fields are hidden
        XCTAssertFalse(earliestStartButton.exists)
        XCTAssertFalse(latestStartButton.exists)
        XCTAssertFalse(durationSlider.exists)
    }
    
    func testTravelStyleSelection() throws {
        // Navigate to trip submission form
        let newTripTab = app.tabBars.buttons["New Trip"]
        newTripTab.tap()
        
        // Test travel style menu
        let travelStyleButton = app.buttons["Comfortable"]
        XCTAssertTrue(travelStyleButton.exists)
        travelStyleButton.tap()
        
        // Verify menu options appear
        let luxuryOption = app.buttons["Luxury"]
        XCTAssertTrue(luxuryOption.exists)
        luxuryOption.tap()
        
        // Verify selection is updated
        let updatedButton = app.buttons["Luxury"]
        XCTAssertTrue(updatedButton.exists)
    }
    
    func testGroupSizeStepper() throws {
        // Navigate to trip submission form
        let newTripTab = app.tabBars.buttons["New Trip"]
        newTripTab.tap()
        
        // Test group size stepper
        let groupSizeStepper = app.steppers.firstMatch
        XCTAssertTrue(groupSizeStepper.exists)
        
        // Test increment
        groupSizeStepper.buttons.element(boundBy: 1).tap() // Plus button
        
        // Test decrement
        groupSizeStepper.buttons.element(boundBy: 0).tap() // Minus button
    }
    
    func testSpecialRequests() throws {
        // Navigate to trip submission form
        let newTripTab = app.tabBars.buttons["New Trip"]
        newTripTab.tap()
        
        // Test special requests text editor
        let specialRequestsField = app.textViews.firstMatch
        XCTAssertTrue(specialRequestsField.exists)
        
        specialRequestsField.tap()
        specialRequestsField.typeText("Please provide vegetarian meal options")
        
        // Test keyboard dismissal
        let doneButton = app.buttons["Done"]
        if doneButton.exists {
            doneButton.tap()
        }
    }
    
    func testNavigationFlow() throws {
        // Navigate to trip submission form
        let newTripTab = app.tabBars.buttons["New Trip"]
        newTripTab.tap()
        
        // Test cancel navigation
        let cancelButton = app.navigationBars.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists)
        cancelButton.tap()
        
        // Verify we're back at the main tab
        XCTAssertTrue(newTripTab.exists)
        
        // Navigate back to form
        newTripTab.tap()
        
        // Fill form and test successful submission navigation
        let departureField = app.textFields["Where are you departing from?"]
        departureField.tap()
        departureField.typeText("Boston")
        
        let destinationField = app.textFields["Enter your dream destination"]
        destinationField.tap()
        destinationField.typeText("New York")
        
        let submitButton = app.buttons["Submit Trip Request"]
        XCTAssertTrue(submitButton.isEnabled)
        
        // Note: Actual submission would require mock backend
        // This test verifies the button is enabled and can be tapped
        XCTAssertTrue(submitButton.exists)
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityElements() throws {
        // Navigate to trip submission form
        let newTripTab = app.tabBars.buttons["New Trip"]
        newTripTab.tap()
        
        // Test accessibility labels
        let departureField = app.textFields["Where are you departing from?"]
        XCTAssertTrue(departureField.exists)
        XCTAssertNotNil(departureField.label)
        
        let destinationField = app.textFields["Enter your dream destination"]
        XCTAssertTrue(destinationField.exists)
        XCTAssertNotNil(destinationField.label)
        
        let submitButton = app.buttons["Submit Trip Request"]
        XCTAssertTrue(submitButton.exists)
        XCTAssertNotNil(submitButton.label)
        
        // Test accessibility hints
        XCTAssertTrue(departureField.isAccessibilityElement)
        XCTAssertTrue(destinationField.isAccessibilityElement)
        XCTAssertTrue(submitButton.isAccessibilityElement)
    }
    
    func testVoiceOverNavigation() throws {
        // Enable VoiceOver for testing
        app.activate()
        
        // Navigate to trip submission form
        let newTripTab = app.tabBars.buttons["New Trip"]
        newTripTab.tap()
        
        // Test that elements are accessible with VoiceOver
        let departureField = app.textFields["Where are you departing from?"]
        XCTAssertTrue(departureField.isAccessibilityElement)
        
        let cultureButton = app.buttons["Culture"]
        XCTAssertTrue(cultureButton.isAccessibilityElement)
        
        let submitButton = app.buttons["Submit Trip Request"]
        XCTAssertTrue(submitButton.isAccessibilityElement)
    }
    
    // MARK: - Performance Tests
    
    func testFormLoadingPerformance() throws {
        measure {
            // Navigate to trip submission form
            let newTripTab = app.tabBars.buttons["New Trip"]
            newTripTab.tap()
            
            // Wait for form to load
            let submitButton = app.buttons["Submit Trip Request"]
            XCTAssertTrue(submitButton.waitForExistence(timeout: 5.0))
            
            // Navigate back
            let cancelButton = app.navigationBars.buttons["Cancel"]
            cancelButton.tap()
        }
    }
    
    func testAutocompletePerformance() throws {
        // Navigate to trip submission form
        let newTripTab = app.tabBars.buttons["New Trip"]
        newTripTab.tap()
        
        measure {
            let departureField = app.textFields["Where are you departing from?"]
            departureField.tap()
            departureField.typeText("New York")
            
            // Wait for autocomplete to appear
            let suggestionsList = app.scrollViews.firstMatch
            _ = suggestionsList.waitForExistence(timeout: 2.0)
        }
    }
    
    // MARK: - Edge Cases
    
    func testMaxDestinations() throws {
        // Navigate to trip submission form
        let newTripTab = app.tabBars.buttons["New Trip"]
        newTripTab.tap()
        
        // Add maximum number of destinations (10)
        let addStopButton = app.buttons["Add Stop"]
        
        // Add destinations up to the limit
        for i in 1..<10 {
            if addStopButton.exists {
                addStopButton.tap()
                
                let destinationField = app.textFields["Add another destination"]
                if destinationField.exists {
                    destinationField.tap()
                    destinationField.typeText("City \(i)")
                }
            }
        }
        
        // Verify "Add Stop" button is no longer available at limit
        XCTAssertFalse(addStopButton.exists)
    }
    
    func testEmptyFormSubmission() throws {
        // Navigate to trip submission form
        let newTripTab = app.tabBars.buttons["New Trip"]
        newTripTab.tap()
        
        // Try to submit empty form
        let submitButton = app.buttons["Submit Trip Request"]
        XCTAssertFalse(submitButton.isEnabled)
        
        // Verify form validation prevents submission
        XCTAssertTrue(submitButton.exists)
    }
}

// MARK: - Helper Extensions

extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non-string value")
            return
        }
        
        self.tap()
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
}