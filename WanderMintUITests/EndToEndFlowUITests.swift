import XCTest

/// End-to-end live UI flow tests that launch WanderMint on iPhone or iPad Simulator and exercise
/// every core screen, navigation push, form interaction, checklist toggle, and modal sheet to catch
/// regressions (blank iPad screens, nested NavigationStack bounce-backs, broken sheets) before upload.
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
    
    /// Handles both iPhone bottom TabBar and iPadOS 18 floating top tab pill.
    private func tabButton(_ title: String) -> XCUIElement {
        let tabBarBtn = app.tabBars.buttons[title]
        if tabBarBtn.exists {
            return tabBarBtn
        }
        return app.buttons[title].firstMatch
    }
    
    /// Scrolls upward in the primary ScrollView until an element is hittable (up to maxSwipes).
    private func scrollToElement(_ element: XCUIElement, maxSwipes: Int = 5) {
        var attempts = 0
        while (!element.exists || !element.isHittable) && attempts < maxSwipes {
            app.swipeUp()
            attempts += 1
        }
    }
    
    /// Signs in if launched on AuthenticationView, or continues directly if already authenticated.
    private func ensureAuthenticated() throws {
        // Dismiss system notification permission prompt if it appears on first launch
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowBtn = springboard.buttons["Allow"]
        if allowBtn.waitForExistence(timeout: 2) {
            allowBtn.tap()
        }
        
        let myTripsHeader = app.staticTexts["My Trips"]
        if myTripsHeader.waitForExistence(timeout: 8) {
            return
        }
        
        let emailField = app.textFields["Email"]
        guard emailField.waitForExistence(timeout: 8) else {
            XCTFail("Neither My Trips screen nor Sign In screen appeared after launch")
            return
        }
        
        // Verify Sign in with Apple button renders on Authentication screen
        XCTAssertTrue(
            app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Apple'")).firstMatch.exists,
            "Sign in with Apple button should be visible on the Sign In screen"
        )
        
        let env = ProcessInfo.processInfo.environment
        guard let email = env["WM_TEST_EMAIL"], !email.isEmpty,
              let password = env["WM_TEST_PASSWORD"], !password.isEmpty else {
            throw XCTSkip("Sign in on Simulator or set WM_TEST_EMAIL and WM_TEST_PASSWORD to run authenticated E2E UI flows.")
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
        
        XCTAssertTrue(myTripsHeader.waitForExistence(timeout: 15), "Expected My Trips screen after signing in")
    }
    
    func testCompleteCoreUserFlowsEndToEnd() throws {
        try ensureAuthenticated()
        
        // MARK: Flow 1 — My Trips List
        let myTripsTab = tabButton("My Trips")
        if myTripsTab.exists { myTripsTab.tap() }
        XCTAssertTrue(app.staticTexts["My Trips"].waitForExistence(timeout: 8), "My Trips header should be visible")
        
        let firstTripButton = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Trip to '")).firstMatch
        XCTAssertTrue(firstTripButton.waitForExistence(timeout: 12), "Expected at least one trip card in My Trips")
        firstTripButton.tap()
        
        // MARK: Flow 2 — Trip Detail View Tabs + Feature B Interactive Booking Checklist
        let tripDetailsNav = app.navigationBars["Trip Details"]
        XCTAssertTrue(tripDetailsNav.waitForExistence(timeout: 8), "Trip Details screen should open when tapping a trip")
        
        // Switch across Logistics and Overview tabs
        let logisticsTabBtn = app.buttons["Logistics"]
        if logisticsTabBtn.waitForExistence(timeout: 4) {
            logisticsTabBtn.tap()
        }
        
        let overviewTabBtn = app.buttons["Overview"]
        if overviewTabBtn.waitForExistence(timeout: 5) {
            overviewTabBtn.tap()
            let checklistHeader = app.staticTexts["Booking & Points Checklist"]
            scrollToElement(checklistHeader, maxSwipes: 3)
            XCTAssertTrue(checklistHeader.waitForExistence(timeout: 6), "Booking & Points Checklist should appear on Overview tab")
            
            let stepToggle = app.buttons.matching(NSPredicate(format: "label CONTAINS 'step 1:'")).firstMatch
            if stepToggle.waitForExistence(timeout: 4) {
                stepToggle.tap() // Check off step 1
                stepToggle.tap() // Restore original state cleanly
            }
        }
        
        let destinationsTabBtn = app.buttons["Destinations"]
        if destinationsTabBtn.exists {
            destinationsTabBtn.tap()
        }
        
        // MARK: Flow 3 — Request Changes / Trip Conversation (Regression test for bounce-back bug)
        let requestChangesButton = app.buttons["Request Changes"]
        XCTAssertTrue(requestChangesButton.waitForExistence(timeout: 5), "Request Changes toolbar button should exist")
        requestChangesButton.tap()
        
        let conversationNav = app.navigationBars["Request Changes"]
        XCTAssertTrue(conversationNav.waitForExistence(timeout: 6), "Request Changes screen must stay presented and not pop back to My Trips")
        
        // Confirm it stays presented after async Firestore load
        sleep(2)
        XCTAssertTrue(conversationNav.exists, "Request Changes screen must remain visible after async load")
        XCTAssertFalse(app.staticTexts["Unable to load conversation"].exists, "Conversation should load without error")
        
        // Open & dismiss Templates sheet
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
        conversationNav.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(tripDetailsNav.waitForExistence(timeout: 5), "Back from Request Changes should return to Trip Details")
        
        tripDetailsNav.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["My Trips"].waitForExistence(timeout: 5), "Back from Trip Details should return to My Trips")
        
        // MARK: Flow 4 — New Trip Tab (Interactive Form & Validation Checks)
        tabButton("New Trip").tap()
        XCTAssertTrue(app.staticTexts["Plan Your Dream Trip"].waitForExistence(timeout: 6), "New Trip screen should render")
        XCTAssertTrue(app.staticTexts["Where To?"].exists)
        
        // Add & remove a second destination stop
        let addDestinationButton = app.buttons["Add destination"]
        if addDestinationButton.waitForExistence(timeout: 4) && addDestinationButton.isHittable {
            addDestinationButton.tap()
            let removeStop2 = app.buttons["Remove destination 2"]
            XCTAssertTrue(removeStop2.waitForExistence(timeout: 4), "Second destination stop should be added")
            removeStop2.tap()
        }
        
        // Toggle flexible dates on and back off
        let flexibleToggle = app.switches["Flexible dates"]
        scrollToElement(flexibleToggle, maxSwipes: 2)
        if flexibleToggle.waitForExistence(timeout: 4) {
            flexibleToggle.tap()
            XCTAssertTrue(app.staticTexts["Trip Duration: 7 days"].waitForExistence(timeout: 4), "Flexible dates duration slider should appear")
            flexibleToggle.tap()
        }
        
        // Scroll to Submit button and confirm form validation keeps it disabled when incomplete
        let submitTripButton = app.buttons["Submit trip request"]
        scrollToElement(submitTripButton, maxSwipes: 5)
        XCTAssertTrue(submitTripButton.waitForExistence(timeout: 4), "Submit trip request button should exist")
        XCTAssertFalse(submitTripButton.isEnabled, "Submit button should remain disabled when required fields are empty")
        
        // MARK: Flow 5 — Profile Tab & Every Settings/Action Sheet
        tabButton("Profile").tap()
        XCTAssertTrue(app.staticTexts["Profile"].waitForExistence(timeout: 6), "Profile header should render")
        
        // 5a. Points & Miles (with Close button & segmented picker check)
        let pointsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Points & Miles'")).firstMatch
        XCTAssertTrue(pointsButton.waitForExistence(timeout: 5))
        pointsButton.tap()
        XCTAssertTrue(app.navigationBars["Points & Miles"].waitForExistence(timeout: 5), "Points & Miles sheet should open")
        if app.buttons["Hotels"].waitForExistence(timeout: 3) {
            app.buttons["Hotels"].tap()
            app.buttons["Airlines"].tap()
            app.buttons["Credit Cards"].tap()
        }
        app.buttons["Close"].tap()
        
        // 5b. Travel History
        let historyButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Travel History'")).firstMatch
        XCTAssertTrue(historyButton.waitForExistence(timeout: 5))
        historyButton.tap()
        XCTAssertTrue(app.navigationBars["Travel History"].waitForExistence(timeout: 5), "Travel History sheet should open")
        app.buttons["Close"].tap()
        
        // 5c. Edit Profile
        let editProfileButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Edit Profile'")).firstMatch
        XCTAssertTrue(editProfileButton.waitForExistence(timeout: 5))
        editProfileButton.tap()
        XCTAssertTrue(app.navigationBars["Edit Profile"].waitForExistence(timeout: 5), "Edit Profile sheet should open")
        app.buttons["Cancel"].tap()
        
        // Scroll down to Settings section cleanly above the TabBar
        app.swipeUp()
        
        // 5d. Notifications
        let notifButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Notifications'")).firstMatch
        scrollToElement(notifButton, maxSwipes: 3)
        XCTAssertTrue(notifButton.waitForExistence(timeout: 5))
        notifButton.tap()
        XCTAssertTrue(app.navigationBars["Notifications"].waitForExistence(timeout: 5), "Notifications sheet should open")
        XCTAssertTrue(app.buttons["Manage iOS Notification Settings"].waitForExistence(timeout: 4))
        app.buttons["Close"].tap()
        
        // 5e. Privacy & Security (App Store Guideline 5.1.1(v) Delete Account + Legal links)
        let privacyButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Privacy & Security'")).firstMatch
        scrollToElement(privacyButton, maxSwipes: 3)
        XCTAssertTrue(privacyButton.waitForExistence(timeout: 5))
        privacyButton.tap()
        XCTAssertTrue(app.navigationBars["Privacy & Security"].waitForExistence(timeout: 5), "Privacy & Security sheet should open")
        XCTAssertTrue(app.links["View Privacy Policy"].waitForExistence(timeout: 4) || app.buttons["View Privacy Policy"].exists)
        XCTAssertTrue(app.links["Terms of Service"].exists || app.buttons["Terms of Service"].exists)
        let deleteAccountButton = app.buttons["Delete Account"]
        scrollToElement(deleteAccountButton, maxSwipes: 3)
        XCTAssertTrue(deleteAccountButton.exists, "Delete Account button must be present")
        app.buttons["Close"].tap()
        
        // 5f. Help & Support
        let helpButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Help & Support'")).firstMatch
        scrollToElement(helpButton, maxSwipes: 3)
        XCTAssertTrue(helpButton.waitForExistence(timeout: 5))
        helpButton.tap()
        XCTAssertTrue(app.navigationBars["Help & Support"].waitForExistence(timeout: 5), "Help & Support sheet should open")
        let faqButton = app.buttons["How do I submit a trip request?"]
        if faqButton.waitForExistence(timeout: 3) {
            faqButton.tap()
        }
        XCTAssertTrue(app.buttons["Email Support"].waitForExistence(timeout: 4))
        app.buttons["Close"].tap()
    }
    
    func testAppLaunchAndBackgroundResume() throws {
        XCTAssertEqual(app.state, .runningForeground, "App should launch cleanly into foreground")
        
        // Background app and return to foreground to verify lifecycle stability
        XCUIDevice.shared.press(.home)
        sleep(1)
        app.activate()
        
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5), "App should resume cleanly from background")
        let hasMainOrAuthUI = app.staticTexts["My Trips"].waitForExistence(timeout: 8)
            || app.textFields["Email"].waitForExistence(timeout: 4)
        XCTAssertTrue(hasMainOrAuthUI, "App should display either My Trips or Sign In UI after resuming")
    }
}
