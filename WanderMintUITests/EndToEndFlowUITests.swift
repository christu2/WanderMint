import XCTest

/// End-to-end UI flow tests that launch the live WanderMint app and exercise every primary
/// navigation path, sheet, and interactive screen to catch navigation regressions (such as
/// nested NavigationStacks bouncing back to root or broken sheets) before App Store submission.
final class EndToEndFlowUITests: XCTestCase {
    
    private var app: XCUIApplication!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }
    
    /// Signs in if the app launches on the Authentication screen (using env credentials),
    /// or proceeds directly if the simulator already has an authenticated session.
    private func ensureAuthenticated() throws {
        let myTripsTab = app.tabBars.buttons["My Trips"]
        if myTripsTab.waitForExistence(timeout: 6) {
            return
        }
        
        let emailField = app.textFields["Email"]
        guard emailField.waitForExistence(timeout: 8) else {
            XCTFail("Neither My Trips tab nor Sign In screen appeared after launch")
            return
        }
        
        let env = ProcessInfo.processInfo.environment
        guard let email = env["WM_TEST_EMAIL"], !email.isEmpty,
              let password = env["WM_TEST_PASSWORD"], !password.isEmpty else {
            throw XCTSkip("Set WM_TEST_EMAIL and WM_TEST_PASSWORD environment variables (or sign in on Simulator) to run authenticated end-to-end UI tests.")
        }
        
        emailField.tap()
        emailField.typeText(email)
        
        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.exists)
        passwordField.tap()
        passwordField.typeText(password)
        
        let signInButton = app.buttons["Sign In"]
        XCTAssertTrue(signInButton.isEnabled)
        signInButton.tap()
        
        XCTAssertTrue(myTripsTab.waitForExistence(timeout: 15), "Expected My Trips tab after signing in")
    }
    
    func testCompleteCoreUserFlowsEndToEnd() throws {
        try ensureAuthenticated()
        
        // MARK: Flow 1 — My Trips List
        let myTripsTab = app.tabBars.buttons["My Trips"]
        myTripsTab.tap()
        XCTAssertTrue(app.staticTexts["My Trips"].waitForExistence(timeout: 8), "My Trips header should be visible")
        
        // Wait for trips to finish loading and tap the first trip card
        let firstTripButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Trip to '")).firstMatch
        XCTAssertTrue(firstTripButton.waitForExistence(timeout: 12), "Expected at least one trip card in My Trips")
        firstTripButton.tap()
        
        // MARK: Flow 2 — Trip Detail View
        let tripDetailsNav = app.navigationBars["Trip Details"]
        XCTAssertTrue(tripDetailsNav.waitForExistence(timeout: 8), "Trip Details screen should open when tapping a trip")
        
        // MARK: Flow 3 — Request Changes / Trip Conversation (Regression test for bounce-back bug)
        let requestChangesButton = app.buttons["Request Changes"]
        XCTAssertTrue(requestChangesButton.waitForExistence(timeout: 5), "Request Changes toolbar button should exist")
        requestChangesButton.tap()
        
        let conversationNav = app.navigationBars["Request Changes"]
        XCTAssertTrue(conversationNav.waitForExistence(timeout: 6), "Request Changes screen must stay presented and not pop back to My Trips")
        
        // Wait briefly to confirm it does not pop back after async Firestore load
        sleep(2)
        XCTAssertTrue(conversationNav.exists, "Request Changes screen must remain visible after async load")
        XCTAssertFalse(app.staticTexts["Unable to load conversation"].exists, "Conversation should load without error")
        
        // Verify Templates sheet opens & dismisses cleanly
        let templatesButton = conversationNav.buttons["Templates"]
        if templatesButton.waitForExistence(timeout: 4) {
            templatesButton.tap()
            let cancelTemplates = app.buttons["Cancel"]
            if cancelTemplates.waitForExistence(timeout: 4) {
                cancelTemplates.tap()
            } else {
                app.swipeDown()
            }
            XCTAssertTrue(conversationNav.waitForExistence(timeout: 4), "Should return to Request Changes after dismissing Templates")
        }
        
        // Navigate back to Trip Details, then back to My Trips
        let backToTripDetails = conversationNav.buttons.element(boundBy: 0)
        backToTripDetails.tap()
        XCTAssertTrue(tripDetailsNav.waitForExistence(timeout: 5), "Back from Request Changes should return to Trip Details")
        
        let backToMyTrips = tripDetailsNav.buttons.element(boundBy: 0)
        backToMyTrips.tap()
        XCTAssertTrue(app.staticTexts["My Trips"].waitForExistence(timeout: 5), "Back from Trip Details should return to My Trips")
        
        // MARK: Flow 4 — New Trip Tab
        let newTripTab = app.tabBars.buttons["New Trip"]
        newTripTab.tap()
        XCTAssertTrue(app.staticTexts["Plan Your Dream Trip"].waitForExistence(timeout: 6), "New Trip screen should render")
        XCTAssertTrue(app.staticTexts["Where To?"].exists)
        
        // MARK: Flow 5 — Profile Tab & Every Settings Sheet
        let profileTab = app.tabBars.buttons["Profile"]
        profileTab.tap()
        XCTAssertTrue(app.staticTexts["Profile"].waitForExistence(timeout: 6), "Profile header should render")
        
        // 5a. Points & Miles
        let pointsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Points & Miles'")).firstMatch
        XCTAssertTrue(pointsButton.waitForExistence(timeout: 5))
        pointsButton.tap()
        XCTAssertTrue(app.staticTexts["Points & Miles"].waitForExistence(timeout: 5), "Points & Miles sheet should open")
        app.swipeDown()
        
        // 5b. Travel History
        let historyButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Travel History'")).firstMatch
        XCTAssertTrue(historyButton.waitForExistence(timeout: 5))
        historyButton.tap()
        XCTAssertTrue(app.navigationBars["Travel History"].waitForExistence(timeout: 5), "Travel History sheet should open")
        app.buttons["Close"].tap()
        
        // 5c. Notifications
        let notifButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Notifications'")).firstMatch
        if !notifButton.isHittable { app.swipeUp() }
        XCTAssertTrue(notifButton.waitForExistence(timeout: 5))
        notifButton.tap()
        XCTAssertTrue(app.navigationBars["Notifications"].waitForExistence(timeout: 5), "Notifications sheet should open")
        XCTAssertTrue(app.buttons["Manage iOS Notification Settings"].waitForExistence(timeout: 4))
        app.buttons["Close"].tap()
        
        // 5d. Privacy & Security (App Store Guideline 5.1.1(v) Delete Account + Legal links)
        let privacyButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Privacy & Security'")).firstMatch
        if !privacyButton.isHittable { app.swipeUp() }
        XCTAssertTrue(privacyButton.waitForExistence(timeout: 5))
        privacyButton.tap()
        XCTAssertTrue(app.navigationBars["Privacy & Security"].waitForExistence(timeout: 5), "Privacy & Security sheet should open")
        XCTAssertTrue(app.links["View Privacy Policy"].waitForExistence(timeout: 4) || app.buttons["View Privacy Policy"].exists)
        XCTAssertTrue(app.links["Terms of Service"].exists || app.buttons["Terms of Service"].exists)
        if !app.buttons["Delete Account"].isHittable { app.swipeUp() }
        XCTAssertTrue(app.buttons["Delete Account"].exists, "Delete Account button must be present")
        app.buttons["Close"].tap()
        
        // 5e. Help & Support
        let helpButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Help & Support'")).firstMatch
        if !helpButton.isHittable { app.swipeUp() }
        XCTAssertTrue(helpButton.waitForExistence(timeout: 5))
        helpButton.tap()
        XCTAssertTrue(app.navigationBars["Help & Support"].waitForExistence(timeout: 5), "Help & Support sheet should open")
        app.buttons["Close"].tap()
    }
}
