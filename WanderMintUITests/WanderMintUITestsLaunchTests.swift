//
//  WanderMintUITestsLaunchTests.swift
//  WanderMintUITests
//
//  Created by Nick Christus on 7/10/25.
//

import XCTest

final class WanderMintUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after the app launch but before taking a screenshot
        // for example, logging into a test account or navigating to a specific screen

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}