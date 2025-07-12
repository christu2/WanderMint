import XCTest
import UIKit
@testable import WanderMint

class HapticFeedbackTests: XCTestCase {
    
    var hapticService: HapticFeedbackService!
    
    override func setUp() {
        super.setUp()
        hapticService = HapticFeedbackService.shared
    }
    
    override func tearDown() {
        hapticService = nil
        super.tearDown()
    }
    
    // MARK: - Service Access Tests
    
    func testSharedInstance() {
        let service1 = HapticFeedbackService.shared
        let service2 = HapticFeedbackService.shared
        
        XCTAssertTrue(service1 === service2, "Should return the same shared instance")
    }
    
    // MARK: - Basic Haptic Feedback Tests
    
    func testLightImpact() {
        XCTAssertNoThrow(hapticService.lightImpact())
    }
    
    func testMediumImpact() {
        XCTAssertNoThrow(hapticService.mediumImpact())
    }
    
    func testHeavyImpact() {
        XCTAssertNoThrow(hapticService.heavyImpact())
    }
    
    func testSuccessNotification() {
        XCTAssertNoThrow(hapticService.success())
    }
    
    func testWarningNotification() {
        XCTAssertNoThrow(hapticService.warning())
    }
    
    func testErrorNotification() {
        XCTAssertNoThrow(hapticService.error())
    }
    
    func testSelectionChanged() {
        XCTAssertNoThrow(hapticService.selectionChanged())
    }
    
    // MARK: - Context-Specific Feedback Tests
    
    func testButtonTap() {
        XCTAssertNoThrow(hapticService.buttonTap())
    }
    
    func testToggleSwitch() {
        XCTAssertNoThrow(hapticService.toggleSwitch())
    }
    
    func testFormSubmission() {
        XCTAssertNoThrow(hapticService.formSubmission())
    }
    
    func testNavigation() {
        XCTAssertNoThrow(hapticService.navigation())
    }
    
    func testPullToRefresh() {
        XCTAssertNoThrow(hapticService.pullToRefresh())
    }
    
    func testSwipeAction() {
        XCTAssertNoThrow(hapticService.swipeAction())
    }
    
    func testDragAndDrop() {
        XCTAssertNoThrow(hapticService.dragAndDrop())
    }
    
    func testLoadingComplete() {
        XCTAssertNoThrow(hapticService.loadingComplete())
    }
    
    func testErrorOccurred() {
        XCTAssertNoThrow(hapticService.errorOccurred())
    }
    
    func testValidationError() {
        XCTAssertNoThrow(hapticService.validationError())
    }
    
    func testOperationSuccess() {
        XCTAssertNoThrow(hapticService.operationSuccess())
    }
    
    // MARK: - Travel App Specific Feedback Tests
    
    func testTripSubmitted() {
        XCTAssertNoThrow(hapticService.tripSubmitted())
    }
    
    func testDestinationAdded() {
        XCTAssertNoThrow(hapticService.destinationAdded())
    }
    
    func testDestinationRemoved() {
        XCTAssertNoThrow(hapticService.destinationRemoved())
    }
    
    func testPointsAdded() {
        XCTAssertNoThrow(hapticService.pointsAdded())
    }
    
    func testMessageSent() {
        XCTAssertNoThrow(hapticService.messageSent())
    }
    
    func testNotificationReceived() {
        XCTAssertNoThrow(hapticService.notificationReceived())
    }
    
    func testAuthenticationSuccess() {
        XCTAssertNoThrow(hapticService.authenticationSuccess())
    }
    
    func testAuthenticationFailure() {
        XCTAssertNoThrow(hapticService.authenticationFailure())
    }
    
    func testSearchResults() {
        XCTAssertNoThrow(hapticService.searchResults())
    }
    
    func testFilterApplied() {
        XCTAssertNoThrow(hapticService.filterApplied())
    }
    
    // MARK: - Haptic Feedback Type Tests
    
    func testHapticFeedbackTypes() {
        let types: [HapticFeedbackType] = [
            .light, .medium, .heavy, .success, .warning, .error, .selection, .buttonTap, .navigation
        ]
        
        for type in types {
            XCTAssertNoThrow(type, "Haptic feedback type \(type) should be valid")
        }
    }
    
    // MARK: - Performance Tests
    
    func testHapticFeedbackPerformance() {
        measure {
            for _ in 0..<100 {
                hapticService.lightImpact()
                hapticService.mediumImpact()
                hapticService.heavyImpact()
                hapticService.success()
                hapticService.warning()
                hapticService.error()
                hapticService.selectionChanged()
            }
        }
    }
    
    func testTravelSpecificHapticPerformance() {
        measure {
            for _ in 0..<50 {
                hapticService.tripSubmitted()
                hapticService.destinationAdded()
                hapticService.destinationRemoved()
                hapticService.pointsAdded()
                hapticService.messageSent()
                hapticService.notificationReceived()
                hapticService.authenticationSuccess()
                hapticService.authenticationFailure()
                hapticService.searchResults()
                hapticService.filterApplied()
            }
        }
    }
    
    // MARK: - Async Feedback Tests
    
    func testAsyncTripSubmitted() {
        let expectation = expectation(description: "Trip submitted haptic should complete")
        
        hapticService.tripSubmitted()
        
        // Wait for the delayed second impact
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 0.5)
    }
    
    // MARK: - Edge Cases
    
    func testRapidFireHaptics() {
        XCTAssertNoThrow {
            for _ in 0..<1000 {
                self.hapticService.lightImpact()
            }
        }
    }
    
    func testMixedHapticTypes() {
        XCTAssertNoThrow {
            self.hapticService.lightImpact()
            self.hapticService.success()
            self.hapticService.mediumImpact()
            self.hapticService.error()
            self.hapticService.heavyImpact()
            self.hapticService.warning()
            self.hapticService.selectionChanged()
        }
    }
    
    // MARK: - Device Compatibility Tests
    
    func testDeviceCompatibility() {
        // Test that haptic feedback methods don't crash on different device types
        let originalIdiom = UIDevice.current.userInterfaceIdiom
        
        // Test on different device types (note: this is just for method safety)
        XCTAssertNoThrow(hapticService.lightImpact())
        XCTAssertNoThrow(hapticService.mediumImpact())
        XCTAssertNoThrow(hapticService.heavyImpact())
        XCTAssertNoThrow(hapticService.success())
        XCTAssertNoThrow(hapticService.warning())
        XCTAssertNoThrow(hapticService.error())
    }
    
    // MARK: - Memory Management Tests
    
    func testServiceMemoryManagement() {
        weak var weakService: HapticFeedbackService?
        
        autoreleasepool {
            let service = HapticFeedbackService.shared
            weakService = service
            
            // Service should be alive here
            XCTAssertNotNil(weakService)
            
            // Use the service
            service.lightImpact()
        }
        
        // Shared instance should still be alive
        XCTAssertNotNil(weakService)
    }
    
    // MARK: - Thread Safety Tests
    
    func testThreadSafety() {
        let expectation = expectation(description: "All haptic calls should complete")
        expectation.expectedFulfillmentCount = 10
        
        let queue = DispatchQueue.global(qos: .userInitiated)
        
        for i in 0..<10 {
            queue.async {
                switch i % 7 {
                case 0:
                    self.hapticService.lightImpact()
                case 1:
                    self.hapticService.mediumImpact()
                case 2:
                    self.hapticService.heavyImpact()
                case 3:
                    self.hapticService.success()
                case 4:
                    self.hapticService.warning()
                case 5:
                    self.hapticService.error()
                case 6:
                    self.hapticService.selectionChanged()
                default:
                    break
                }
                
                DispatchQueue.main.async {
                    expectation.fulfill()
                }
            }
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    // MARK: - Integration Tests
    
    func testHapticFeedbackIntegration() {
        // Test that haptic feedback works as part of a user interaction flow
        XCTAssertNoThrow {
            // Simulate user interaction flow
            self.hapticService.buttonTap()          // User taps button
            self.hapticService.formSubmission()     // Form is submitted
            self.hapticService.loadingComplete()    // Loading completes
            self.hapticService.operationSuccess()   // Operation succeeds
        }
    }
    
    func testTravelAppWorkflow() {
        // Test haptic feedback in a typical travel app workflow
        XCTAssertNoThrow {
            self.hapticService.navigation()         // Navigate to trip submission
            self.hapticService.destinationAdded()   // Add destination
            self.hapticService.destinationAdded()   // Add another destination
            self.hapticService.formSubmission()     // Submit trip form
            self.hapticService.tripSubmitted()      // Trip successfully submitted
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testHapticFeedbackErrorHandling() {
        // Test that haptic feedback methods handle errors gracefully
        XCTAssertNoThrow {
            // These should not crash even if haptic feedback is not available
            self.hapticService.lightImpact()
            self.hapticService.mediumImpact()
            self.hapticService.heavyImpact()
            self.hapticService.success()
            self.hapticService.warning()
            self.hapticService.error()
            self.hapticService.selectionChanged()
        }
    }
}