import XCTest
import SwiftUI
import Combine
@testable import WanderMint

class KeyboardHandlerTests: XCTestCase {
    
    var keyboardHandler: KeyboardHandler!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        keyboardHandler = KeyboardHandler()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        keyboardHandler = nil
        super.tearDown()
    }
    
    // MARK: - Keyboard Handler Tests
    
    func testInitialState() {
        XCTAssertEqual(keyboardHandler.keyboardHeight, 0)
        XCTAssertFalse(keyboardHandler.isKeyboardVisible)
    }
    
    func testKeyboardWillShow() {
        let expectation = expectation(description: "Keyboard height should update")
        
        keyboardHandler.$keyboardHeight
            .dropFirst()
            .sink { height in
                XCTAssertGreaterThan(height, 0)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Simulate keyboard will show notification
        let userInfo: [AnyHashable: Any] = [
            UIResponder.keyboardFrameEndUserInfoKey: CGRect(x: 0, y: 0, width: 320, height: 216)
        ]
        
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillShowNotification,
            object: nil,
            userInfo: userInfo
        )
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testKeyboardWillHide() {
        // First show the keyboard
        keyboardHandler.keyboardHeight = 216
        keyboardHandler.isKeyboardVisible = true
        
        let expectation = expectation(description: "Keyboard should hide")
        
        keyboardHandler.$keyboardHeight
            .dropFirst()
            .sink { height in
                XCTAssertEqual(height, 0)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Simulate keyboard will hide notification
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillHideNotification,
            object: nil,
            userInfo: nil
        )
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testKeyboardVisibilityState() {
        let showExpectation = expectation(description: "Keyboard should be visible")
        let hideExpectation = expectation(description: "Keyboard should be hidden")
        
        var expectations = [showExpectation, hideExpectation]
        
        keyboardHandler.$isKeyboardVisible
            .dropFirst()
            .sink { isVisible in
                if isVisible {
                    expectations.removeFirst().fulfill()
                } else if !expectations.isEmpty {
                    expectations.removeFirst().fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Show keyboard
        let showUserInfo: [AnyHashable: Any] = [
            UIResponder.keyboardFrameEndUserInfoKey: CGRect(x: 0, y: 0, width: 320, height: 216)
        ]
        
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillShowNotification,
            object: nil,
            userInfo: showUserInfo
        )
        
        // Hide keyboard
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(
                name: UIResponder.keyboardWillHideNotification,
                object: nil,
                userInfo: nil
            )
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testDismissKeyboard() {
        // This test verifies that the dismiss method exists and can be called
        // The actual dismissal would require a UI test
        XCTAssertNoThrow(keyboardHandler.dismissKeyboard())
    }
    
    // MARK: - Focus Field Tests
    
    func testFocusFieldNext() {
        XCTAssertEqual(FocusField.departureLocation.next, .destination(0))
        XCTAssertEqual(FocusField.destination(0).next, .budget)
        XCTAssertEqual(FocusField.budget.next, .specialRequests)
        XCTAssertEqual(FocusField.groupSize.next, .specialRequests)
        XCTAssertNil(FocusField.specialRequests.next)
    }
    
    func testFocusFieldAllCases() {
        let allCases = FocusField.allCases
        XCTAssertEqual(allCases.count, 5)
        XCTAssertTrue(allCases.contains(.departureLocation))
        XCTAssertTrue(allCases.contains(.destination(0)))
        XCTAssertTrue(allCases.contains(.budget))
        XCTAssertTrue(allCases.contains(.groupSize))
        XCTAssertTrue(allCases.contains(.specialRequests))
    }
    
    func testFocusCoordinator() {
        let coordinator = FocusCoordinator()
        
        XCTAssertNil(coordinator.currentFocus)
        
        coordinator.focus(.departureLocation)
        XCTAssertEqual(coordinator.currentFocus, .departureLocation)
        
        coordinator.nextField(.departureLocation)
        XCTAssertEqual(coordinator.currentFocus, .destination(0))
        
        coordinator.clearFocus()
        XCTAssertNil(coordinator.currentFocus)
    }
    
    func testFocusCoordinatorNextField() {
        let coordinator = FocusCoordinator()
        
        coordinator.focus(.departureLocation)
        coordinator.nextField(.departureLocation)
        XCTAssertEqual(coordinator.currentFocus, .destination(0))
        
        coordinator.nextField(.destination(0))
        XCTAssertEqual(coordinator.currentFocus, .budget)
        
        coordinator.nextField(.budget)
        XCTAssertEqual(coordinator.currentFocus, .specialRequests)
        
        coordinator.nextField(.specialRequests)
        XCTAssertNil(coordinator.currentFocus)
    }
    
    // MARK: - Performance Tests
    
    func testKeyboardObserverPerformance() {
        measure {
            let handler = KeyboardHandler()
            
            // Simulate multiple keyboard notifications
            for _ in 0..<100 {
                let userInfo: [AnyHashable: Any] = [
                    UIResponder.keyboardFrameEndUserInfoKey: CGRect(x: 0, y: 0, width: 320, height: 216)
                ]
                
                NotificationCenter.default.post(
                    name: UIResponder.keyboardWillShowNotification,
                    object: nil,
                    userInfo: userInfo
                )
                
                NotificationCenter.default.post(
                    name: UIResponder.keyboardWillHideNotification,
                    object: nil,
                    userInfo: nil
                )
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testKeyboardNotificationWithoutFrameInfo() {
        let expectation = expectation(description: "Should handle notification without frame info")
        expectation.isInverted = true
        
        keyboardHandler.$keyboardHeight
            .dropFirst()
            .sink { height in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Post notification without frame info
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillShowNotification,
            object: nil,
            userInfo: [:]
        )
        
        waitForExpectations(timeout: 0.5)
    }
    
    func testKeyboardNotificationWithInvalidFrameInfo() {
        let expectation = expectation(description: "Should handle notification with invalid frame info")
        expectation.isInverted = true
        
        keyboardHandler.$keyboardHeight
            .dropFirst()
            .sink { height in
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Post notification with invalid frame info
        let userInfo: [AnyHashable: Any] = [
            UIResponder.keyboardFrameEndUserInfoKey: "invalid"
        ]
        
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillShowNotification,
            object: nil,
            userInfo: userInfo
        )
        
        waitForExpectations(timeout: 0.5)
    }
    
    func testMultipleKeyboardHandlers() {
        let handler1 = KeyboardHandler()
        let handler2 = KeyboardHandler()
        
        let expectation1 = expectation(description: "Handler 1 should receive notification")
        let expectation2 = expectation(description: "Handler 2 should receive notification")
        
        handler1.$keyboardHeight
            .dropFirst()
            .sink { height in
                XCTAssertGreaterThan(height, 0)
                expectation1.fulfill()
            }
            .store(in: &cancellables)
        
        handler2.$keyboardHeight
            .dropFirst()
            .sink { height in
                XCTAssertGreaterThan(height, 0)
                expectation2.fulfill()
            }
            .store(in: &cancellables)
        
        // Post keyboard notification
        let userInfo: [AnyHashable: Any] = [
            UIResponder.keyboardFrameEndUserInfoKey: CGRect(x: 0, y: 0, width: 320, height: 216)
        ]
        
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillShowNotification,
            object: nil,
            userInfo: userInfo
        )
        
        waitForExpectations(timeout: 1.0)
    }
    
    // MARK: - Memory Management Tests
    
    func testKeyboardHandlerDeallocation() {
        weak var weakHandler: KeyboardHandler?
        
        autoreleasepool {
            let handler = KeyboardHandler()
            weakHandler = handler
            
            // Handler should be alive here
            XCTAssertNotNil(weakHandler)
        }
        
        // Handler should be deallocated after autoreleasepool
        XCTAssertNil(weakHandler)
    }
    
    func testNotificationObserverCleanup() {
        var handler: KeyboardHandler? = KeyboardHandler()
        weak var weakHandler = handler
        
        // Create expectations for keyboard notifications
        let expectation = expectation(description: "Should receive keyboard notification")
        
        handler?.$keyboardHeight
            .dropFirst()
            .sink { height in
                XCTAssertGreaterThan(height, 0)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Post notification while handler is alive
        let userInfo: [AnyHashable: Any] = [
            UIResponder.keyboardFrameEndUserInfoKey: CGRect(x: 0, y: 0, width: 320, height: 216)
        ]
        
        NotificationCenter.default.post(
            name: UIResponder.keyboardWillShowNotification,
            object: nil,
            userInfo: userInfo
        )
        
        waitForExpectations(timeout: 1.0)
        
        // Release handler
        handler = nil
        
        // Verify handler is deallocated
        XCTAssertNil(weakHandler)
        
        // Post another notification - should not crash
        XCTAssertNoThrow {
            NotificationCenter.default.post(
                name: UIResponder.keyboardWillShowNotification,
                object: nil,
                userInfo: userInfo
            )
        }
    }
}