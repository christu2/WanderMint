//
//  WanderMintUITests.swift
//  WanderMintUITests
//
//  Created by Claude Code on 7/10/25.
//

import XCTest

final class WanderMintUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        super.setUp()
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        
        // Initialize the application
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
        super.tearDown()
    }
    
    // MARK: - App Launch Tests
    
    func testAppLaunch() throws {
        // Test that the app launches successfully
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
    // MARK: - Authentication UI Tests
    
    func testAuthenticationViewExists() throws {
        // Look for authentication elements
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]
        
        // Wait for elements to appear
        let exists = NSPredicate(format: "exists == true")
        expectation(for: exists, evaluatedWith: emailField, handler: nil)
        expectation(for: exists, evaluatedWith: passwordField, handler: nil)
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertTrue(emailField.exists)
        XCTAssertTrue(passwordField.exists)
    }
    
    func testSignUpToggle() throws {
        // Look for sign up toggle button
        let signUpButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Sign Up'")).firstMatch
        
        if signUpButton.exists {
            signUpButton.tap()
            
            // After tapping, should see name field for sign up
            let nameField = app.textFields["Name"]
            XCTAssertTrue(nameField.waitForExistence(timeout: 2.0))
        }
    }
    
    // MARK: - Navigation Tests
    
    func testTabBarNavigation() throws {
        // Skip if still on authentication screen
        let tabBar = app.tabBars.firstMatch
        
        if tabBar.waitForExistence(timeout: 3.0) {
            // Test tab bar exists and has expected tabs
            XCTAssertTrue(tabBar.exists)
            
            // Look for common tab items (adjust based on actual implementation)
            let homeTab = tabBar.buttons["Home"].firstMatch
            let tripsTab = tabBar.buttons["Trips"].firstMatch
            let pointsTab = tabBar.buttons["Points"].firstMatch
            
            if homeTab.exists {
                homeTab.tap()
                XCTAssertTrue(homeTab.isSelected)
            }
            
            if tripsTab.exists {
                tripsTab.tap()
                XCTAssertTrue(tripsTab.isSelected)
            }
            
            if pointsTab.exists {
                pointsTab.tap()
                XCTAssertTrue(pointsTab.isSelected)
            }
        }
    }
    
    // MARK: - Onboarding Tests
    
    func testOnboardingFlow() throws {
        // Look for onboarding elements
        let continueButton = app.buttons["Continue"]
        let getStartedButton = app.buttons["Get Started"]
        
        if continueButton.waitForExistence(timeout: 3.0) {
            // Test onboarding navigation
            continueButton.tap()
            
            // Check if we progressed in onboarding
            XCTAssertTrue(continueButton.exists || getStartedButton.exists)
        }
    }
    
    // MARK: - Form Interaction Tests
    
    func testFormInputs() throws {
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]
        
        if emailField.waitForExistence(timeout: 3.0) {
            // Test typing in email field
            emailField.tap()
            emailField.typeText("test@example.com")
            
            // Verify text was entered
            XCTAssertEqual(emailField.value as? String, "test@example.com")
        }
        
        if passwordField.exists {
            // Test typing in password field
            passwordField.tap()
            passwordField.typeText("testpassword123")
            
            // Password field should show placeholder or dots, not actual text
            XCTAssertNotEqual(passwordField.value as? String, "testpassword123")
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() throws {
        // Test that important UI elements have accessibility labels
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]
        
        if emailField.waitForExistence(timeout: 3.0) {
            XCTAssertFalse(emailField.accessibilityLabel?.isEmpty ?? true)
        }
        
        if passwordField.exists {
            XCTAssertFalse(passwordField.accessibilityLabel?.isEmpty ?? true)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorMessageDisplay() throws {
        let emailField = app.textFields["Email"]
        let passwordField = app.secureTextFields["Password"]
        let signInButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Sign In'")).firstMatch
        
        if emailField.waitForExistence(timeout: 3.0) && passwordField.exists && signInButton.exists {
            // Enter invalid credentials
            emailField.tap()
            emailField.typeText("invalid-email")
            
            passwordField.tap()
            passwordField.typeText("wrong")
            
            signInButton.tap()
            
            // Look for error message (adjust timeout as needed)
            let errorText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'error' OR label CONTAINS 'invalid'")).firstMatch
            
            // Error message should appear within reasonable time
            XCTAssertTrue(errorText.waitForExistence(timeout: 5.0))
        }
    }
    
    // MARK: - Performance Tests
    
    func testScrollPerformance() throws {
        // Skip if no scrollable content
        let firstScrollView = app.scrollViews.firstMatch
        
        if firstScrollView.waitForExistence(timeout: 3.0) {
            measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric]) {
                firstScrollView.swipeUp()
                firstScrollView.swipeDown()
            }
        }
    }
    
    // MARK: - Memory Tests
    
    func testMemoryPerformance() throws {
        measure(metrics: [XCTMemoryMetric()]) {
            // Perform memory-intensive operations
            for _ in 0..<10 {
                app.swipeUp()
                app.swipeDown()
            }
        }
    }
}