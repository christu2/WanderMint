//
//  WanderMintUITestsLaunchTests.swift
//  WanderMintUITests
//
//  Created by Claude Code on 7/10/25.
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
        
        // Wait for app to fully load
        sleep(2)
        
        // Take screenshot of launch screen
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testLaunchWithDifferentOrientations() throws {
        let app = XCUIApplication()
        
        // Test portrait launch
        XCUIDevice.shared.orientation = .portrait
        app.launch()
        sleep(1)
        
        let portraitScreenshot = XCTAttachment(screenshot: app.screenshot())
        portraitScreenshot.name = "Portrait Launch"
        portraitScreenshot.lifetime = .keepAlways
        add(portraitScreenshot)
        
        // Test landscape launch
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(1)
        
        let landscapeScreenshot = XCTAttachment(screenshot: app.screenshot())
        landscapeScreenshot.name = "Landscape Launch"
        landscapeScreenshot.lifetime = .keepAlways
        add(landscapeScreenshot)
        
        // Reset to portrait
        XCUIDevice.shared.orientation = .portrait
    }
    
    func testLaunchPerformanceMetrics() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // Test launch performance with detailed metrics
            measure(metrics: [
                XCTApplicationLaunchMetric(),
                XCTCPUMetric(),
                XCTMemoryMetric()
            ]) {
                let app = XCUIApplication()
                app.launch()
                app.terminate()
            }
        }
    }
    
    func testLaunchStability() throws {
        // Test that the app launches consistently multiple times
        for i in 1...5 {
            let app = XCUIApplication()
            app.launch()
            
            // Verify app launched successfully
            XCTAssertEqual(app.state, .runningForeground, "App failed to launch on attempt \(i)")
            
            // Take screenshot for each launch
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "Launch Attempt \(i)"
            screenshot.lifetime = .keepAlways
            add(screenshot)
            
            app.terminate()
            sleep(1) // Brief pause between launches
        }
    }
    
    func testLaunchWithBackgroundApp() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Send app to background
        XCUIDevice.shared.press(.home)
        sleep(2)
        
        // Bring app back to foreground
        app.activate()
        sleep(1)
        
        // Verify app is still running properly
        XCTAssertEqual(app.state, .runningForeground)
        
        let resumeScreenshot = XCTAttachment(screenshot: app.screenshot())
        resumeScreenshot.name = "Resume from Background"
        resumeScreenshot.lifetime = .keepAlways
        add(resumeScreenshot)
    }
}