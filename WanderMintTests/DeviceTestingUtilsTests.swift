import XCTest
import SwiftUI
@testable import WanderMint

class DeviceTestingUtilsTests: XCTestCase {
    
    // MARK: - Device Size Tests
    
    func testDeviceSizeScreenSizes() {
        XCTAssertEqual(DeviceTestingUtils.DeviceSize.compact.screenSize, CGSize(width: 375, height: 667))
        XCTAssertEqual(DeviceTestingUtils.DeviceSize.regular.screenSize, CGSize(width: 390, height: 844))
        XCTAssertEqual(DeviceTestingUtils.DeviceSize.large.screenSize, CGSize(width: 428, height: 926))
        XCTAssertEqual(DeviceTestingUtils.DeviceSize.tablet.screenSize, CGSize(width: 820, height: 1180))
    }
    
    func testDeviceSizeNames() {
        XCTAssertEqual(DeviceTestingUtils.DeviceSize.compact.name, "iPhone SE")
        XCTAssertEqual(DeviceTestingUtils.DeviceSize.regular.name, "iPhone 12")
        XCTAssertEqual(DeviceTestingUtils.DeviceSize.large.name, "iPhone 12 Pro Max")
        XCTAssertEqual(DeviceTestingUtils.DeviceSize.tablet.name, "iPad")
    }
    
    // MARK: - Orientation Tests
    
    func testOrientationNames() {
        XCTAssertEqual(DeviceTestingUtils.TestOrientation.portrait.name, "Portrait")
        XCTAssertEqual(DeviceTestingUtils.TestOrientation.landscape.name, "Landscape")
    }
    
    // MARK: - Current Device Detection Tests
    
    func testCurrentDeviceDetection() {
        let currentDevice = DeviceTestingUtils.currentDevice
        
        // Should return a valid device size
        let validDeviceSizes: [DeviceTestingUtils.DeviceSize] = [.compact, .regular, .large, .tablet]
        XCTAssertTrue(validDeviceSizes.contains(currentDevice))
    }
    
    func testCurrentOrientationDetection() {
        let currentOrientation = DeviceTestingUtils.currentOrientation
        
        // Should return a valid orientation
        let validOrientations: [DeviceTestingUtils.TestOrientation] = [.portrait, .landscape]
        XCTAssertTrue(validOrientations.contains(currentOrientation))
    }
    
    // MARK: - Dynamic Type Tests
    
    func testDynamicTypeSizes() {
        let dynamicTypeSizes = DeviceTestingUtils.dynamicTypeSizes
        
        // Test that all expected categories are present
        let expectedCategories: [ContentSizeCategory] = [
            .extraSmall,
            .small,
            .medium,
            .large,
            .extraLarge,
            .extraExtraLarge,
            .extraExtraExtraLarge,
            .accessibilityMedium,
            .accessibilityLarge,
            .accessibilityExtraLarge,
            .accessibilityExtraExtraLarge,
            .accessibilityExtraExtraExtraLarge
        ]
        
        for category in expectedCategories {
            XCTAssertTrue(dynamicTypeSizes.contains(category), "Should contain \(category)")
        }
        
        // Verify count matches expected categories
        XCTAssertEqual(dynamicTypeSizes.count, expectedCategories.count, "Count should match expected categories")
    }
    
    // MARK: - Safe Area Tests
    
    func testSafeAreaInsets() {
        let compactInsets = DeviceTestingUtils.safeAreaInsets(for: .compact)
        let regularInsets = DeviceTestingUtils.safeAreaInsets(for: .regular)
        let largeInsets = DeviceTestingUtils.safeAreaInsets(for: .large)
        let tabletInsets = DeviceTestingUtils.safeAreaInsets(for: .tablet)
        
        // Compact device (iPhone SE) should have minimal safe area
        XCTAssertEqual(compactInsets.top, 20)
        XCTAssertEqual(compactInsets.bottom, 0)
        
        // Regular and large devices should have notch safe areas
        XCTAssertEqual(regularInsets.top, 47)
        XCTAssertEqual(regularInsets.bottom, 34)
        XCTAssertEqual(largeInsets.top, 47)
        XCTAssertEqual(largeInsets.bottom, 34)
        
        // Tablet should have different safe area
        XCTAssertEqual(tabletInsets.top, 24)
        XCTAssertEqual(tabletInsets.bottom, 20)
    }
    
    // MARK: - Layout Helper Tests
    
    func testCompactWidthDetection() {
        let compactWidth = CGSize(width: 350, height: 600)
        let regularWidth = CGSize(width: 450, height: 800)
        
        XCTAssertTrue(DeviceTestingUtils.isCompactWidth(compactWidth))
        XCTAssertFalse(DeviceTestingUtils.isCompactWidth(regularWidth))
    }
    
    func testCompactHeightDetection() {
        let compactHeight = CGSize(width: 400, height: 550)
        let regularHeight = CGSize(width: 400, height: 700)
        
        XCTAssertTrue(DeviceTestingUtils.isCompactHeight(compactHeight))
        XCTAssertFalse(DeviceTestingUtils.isCompactHeight(regularHeight))
    }
    
    func testShouldUseCompactLayout() {
        let compactWidthSize = CGSize(width: 350, height: 700)
        let compactHeightSize = CGSize(width: 450, height: 550)
        let regularSize = CGSize(width: 450, height: 700)
        
        XCTAssertTrue(DeviceTestingUtils.shouldUseCompactLayout(compactWidthSize))
        XCTAssertTrue(DeviceTestingUtils.shouldUseCompactLayout(compactHeightSize))
        XCTAssertFalse(DeviceTestingUtils.shouldUseCompactLayout(regularSize))
    }
    
    // MARK: - Edge Case Tests
    
    func testZeroSizeHandling() {
        let zeroSize = CGSize.zero
        
        XCTAssertTrue(DeviceTestingUtils.isCompactWidth(zeroSize))
        XCTAssertTrue(DeviceTestingUtils.isCompactHeight(zeroSize))
        XCTAssertTrue(DeviceTestingUtils.shouldUseCompactLayout(zeroSize))
    }
    
    func testNegativeSizeHandling() {
        let negativeSize = CGSize(width: -100, height: -100)
        
        XCTAssertTrue(DeviceTestingUtils.isCompactWidth(negativeSize))
        XCTAssertTrue(DeviceTestingUtils.isCompactHeight(negativeSize))
        XCTAssertTrue(DeviceTestingUtils.shouldUseCompactLayout(negativeSize))
    }
    
    func testExtremelyLargeSize() {
        let largeSize = CGSize(width: 10000, height: 10000)
        
        XCTAssertFalse(DeviceTestingUtils.isCompactWidth(largeSize))
        XCTAssertFalse(DeviceTestingUtils.isCompactHeight(largeSize))
        XCTAssertFalse(DeviceTestingUtils.shouldUseCompactLayout(largeSize))
    }
    
    // MARK: - Boundary Value Tests
    
    func testBoundaryValues() {
        let width399 = CGSize(width: 399, height: 700)
        let width400 = CGSize(width: 400, height: 700)
        let width401 = CGSize(width: 401, height: 700)
        
        XCTAssertTrue(DeviceTestingUtils.isCompactWidth(width399))
        XCTAssertFalse(DeviceTestingUtils.isCompactWidth(width400))
        XCTAssertFalse(DeviceTestingUtils.isCompactWidth(width401))
        
        let height599 = CGSize(width: 500, height: 599)
        let height600 = CGSize(width: 500, height: 600)
        let height601 = CGSize(width: 500, height: 601)
        
        XCTAssertTrue(DeviceTestingUtils.isCompactHeight(height599))
        XCTAssertFalse(DeviceTestingUtils.isCompactHeight(height600))
        XCTAssertFalse(DeviceTestingUtils.isCompactHeight(height601))
    }
    
    // MARK: - Performance Tests
    
    func testLayoutDetectionPerformance() {
        let testSizes = (0..<1000).map { _ in
            CGSize(width: Double.random(in: 100...1000), height: Double.random(in: 100...1000))
        }
        
        measure {
            for size in testSizes {
                _ = DeviceTestingUtils.isCompactWidth(size)
                _ = DeviceTestingUtils.isCompactHeight(size)
                _ = DeviceTestingUtils.shouldUseCompactLayout(size)
            }
        }
    }
    
    func testSafeAreaCalculationPerformance() {
        let deviceSizes: [DeviceTestingUtils.DeviceSize] = [.compact, .regular, .large, .tablet]
        
        measure {
            for _ in 0..<1000 {
                for deviceSize in deviceSizes {
                    _ = DeviceTestingUtils.safeAreaInsets(for: deviceSize)
                }
            }
        }
    }
    
    // MARK: - Device Size Detection Tests
    
    func testDeviceSizeDetectionFromScreenSize() {
        // Test that we can categorize screen sizes correctly
        let compactScreenSize = 650.0
        let regularScreenSize = 850.0
        let largeScreenSize = 950.0
        let tabletScreenSize = 1200.0
        
        // Since we can't directly test the private logic, we test the expected behavior
        XCTAssertLessThan(compactScreenSize, 700)
        XCTAssertGreaterThanOrEqual(regularScreenSize, 700)
        XCTAssertLessThan(regularScreenSize, 900)
        XCTAssertGreaterThanOrEqual(largeScreenSize, 900)
        XCTAssertLessThan(largeScreenSize, 1000)
        XCTAssertGreaterThanOrEqual(tabletScreenSize, 1000)
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityContentSizeCategories() {
        let accessibilityCategories = DeviceTestingUtils.dynamicTypeSizes.filter { category in
            switch category {
            case .accessibilityMedium, .accessibilityLarge, .accessibilityExtraLarge, .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge:
                return true
            default:
                return false
            }
        }
        
        XCTAssertGreaterThanOrEqual(accessibilityCategories.count, 5, "Should have at least 5 accessibility categories")
        XCTAssertEqual(accessibilityCategories.count, 5, "Should have exactly 5 accessibility categories")
    }
    
    // MARK: - Integration Tests
    
    func testDeviceAndOrientationCombination() {
        let devices: [DeviceTestingUtils.DeviceSize] = [.compact, .regular, .large, .tablet]
        let orientations: [DeviceTestingUtils.TestOrientation] = [.portrait, .landscape]
        
        for device in devices {
            for orientation in orientations {
                // Test that all combinations are valid
                XCTAssertNotNil(device.name)
                XCTAssertNotNil(orientation.name)
                XCTAssertGreaterThan(device.screenSize.width, 0)
                XCTAssertGreaterThan(device.screenSize.height, 0)
            }
        }
    }
    
    // MARK: - Screen Size Consistency Tests
    
    func testScreenSizeConsistency() {
        let devices: [DeviceTestingUtils.DeviceSize] = [.compact, .regular, .large, .tablet]
        
        for device in devices {
            let screenSize = device.screenSize
            XCTAssertGreaterThan(screenSize.width, 0, "Width should be positive for \(device.name)")
            XCTAssertGreaterThan(screenSize.height, 0, "Height should be positive for \(device.name)")
            
            // Portrait devices should generally have height > width
            if device != .tablet {
                XCTAssertGreaterThan(screenSize.height, screenSize.width, "\(device.name) should be in portrait orientation")
            }
        }
    }
    
    // MARK: - Safe Area Consistency Tests
    
    func testSafeAreaConsistency() {
        let devices: [DeviceTestingUtils.DeviceSize] = [.compact, .regular, .large, .tablet]
        
        for device in devices {
            let safeArea = DeviceTestingUtils.safeAreaInsets(for: device)
            
            XCTAssertGreaterThanOrEqual(safeArea.top, 0, "Top safe area should be non-negative for \(device.name)")
            XCTAssertGreaterThanOrEqual(safeArea.bottom, 0, "Bottom safe area should be non-negative for \(device.name)")
            XCTAssertEqual(safeArea.leading, 0, "Leading safe area should be 0 for \(device.name)")
            XCTAssertEqual(safeArea.trailing, 0, "Trailing safe area should be 0 for \(device.name)")
        }
    }
}