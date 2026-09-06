//
//  DateUtilsTests.swift
//  WanderMintTests
//
//  Created by Jules.
//

import XCTest
@testable import WanderMint

final class DateUtilsTests: XCTestCase {

    func testToDateOnlyString() {
        // Given
        var components = DateComponents()
        components.year = 2024
        components.month = 5
        components.day = 15

        let calendar = Calendar.current
        guard let testDate = calendar.date(from: components) else {
            XCTFail("Failed to create test date")
            return
        }

        // When
        let resultString = DateUtils.toDateOnlyString(testDate)

        // Then
        XCTAssertEqual(resultString, "2024-05-15", "toDateOnlyString should correctly format the date to YYYY-MM-DD")
    }

    func testToDateOnlyString_EdgeCaseNewYear() {
        // Given
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 1

        let calendar = Calendar.current
        guard let testDate = calendar.date(from: components) else {
            XCTFail("Failed to create test date")
            return
        }

        // When
        let resultString = DateUtils.toDateOnlyString(testDate)

        // Then
        XCTAssertEqual(resultString, "2025-01-01", "toDateOnlyString should format correctly on new year's day")
    }

    func testFromDateOnlyString() {
        // Given
        let dateString = "2024-05-15"

        // When
        let resultDate = DateUtils.fromDateOnlyString(dateString)

        // Then
        XCTAssertNotNil(resultDate, "fromDateOnlyString should return a valid Date for a correctly formatted string")

        if let resultDate = resultDate {
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .day], from: resultDate)

            XCTAssertEqual(components.year, 2024)
            XCTAssertEqual(components.month, 5)
            XCTAssertEqual(components.day, 15)
        }
    }

    func testFromDateOnlyString_InvalidFormat() {
        // Given
        let invalidDateString1 = "05-15-2024" // Wrong format
        let invalidDateString2 = "2024/05/15" // Wrong separator
        let invalidDateString3 = "not a date" // Random string

        // When & Then
        XCTAssertNil(DateUtils.fromDateOnlyString(invalidDateString1), "Should return nil for incorrect format MM-DD-YYYY")
        XCTAssertNil(DateUtils.fromDateOnlyString(invalidDateString2), "Should return nil for incorrect separator")
        XCTAssertNil(DateUtils.fromDateOnlyString(invalidDateString3), "Should return nil for non-date string")
    }

    func testFromDateOnlyString_InvalidDate() {
        // Given
        let invalidDateString = "2024-13-40" // Month 13, day 40 does not exist

        // When
        let resultDate = DateUtils.fromDateOnlyString(invalidDateString)

        // Then
        XCTAssertNil(resultDate, "Should return nil for an invalid date that cannot exist")
    }

    func testAddDays() {
        // Given
        var components = DateComponents()
        components.year = 2024
        components.month = 5
        components.day = 15

        let calendar = Calendar.current
        guard let testDate = calendar.date(from: components) else {
            XCTFail("Failed to create test date")
            return
        }

        // When adding positive days
        let addedDaysDate = DateUtils.addDays(10, to: testDate)

        // Then
        XCTAssertNotNil(addedDaysDate)
        if let addedDaysDate = addedDaysDate {
            let resultComponents = calendar.dateComponents([.year, .month, .day], from: addedDaysDate)
            XCTAssertEqual(resultComponents.year, 2024)
            XCTAssertEqual(resultComponents.month, 5)
            XCTAssertEqual(resultComponents.day, 25)
        }

        // When adding zero days
        let sameDate = DateUtils.addDays(0, to: testDate)

        // Then
        XCTAssertNotNil(sameDate)
        if let sameDate = sameDate {
            let resultComponents = calendar.dateComponents([.year, .month, .day], from: sameDate)
            XCTAssertEqual(resultComponents.year, 2024)
            XCTAssertEqual(resultComponents.month, 5)
            XCTAssertEqual(resultComponents.day, 15)
        }

        // When subtracting days (adding negative days)
        let subDaysDate = DateUtils.addDays(-5, to: testDate)

        // Then
        XCTAssertNotNil(subDaysDate)
        if let subDaysDate = subDaysDate {
            let resultComponents = calendar.dateComponents([.year, .month, .day], from: subDaysDate)
            XCTAssertEqual(resultComponents.year, 2024)
            XCTAssertEqual(resultComponents.month, 5)
            XCTAssertEqual(resultComponents.day, 10)
        }
    }

    func testAddDays_OverMonthBoundary() {
        // Given
        var components = DateComponents()
        components.year = 2024
        components.month = 5
        components.day = 30

        let calendar = Calendar.current
        guard let testDate = calendar.date(from: components) else {
            XCTFail("Failed to create test date")
            return
        }

        // When
        let addedDaysDate = DateUtils.addDays(3, to: testDate)

        // Then
        XCTAssertNotNil(addedDaysDate)
        if let addedDaysDate = addedDaysDate {
            let resultComponents = calendar.dateComponents([.year, .month, .day], from: addedDaysDate)
            XCTAssertEqual(resultComponents.year, 2024)
            XCTAssertEqual(resultComponents.month, 6)
            XCTAssertEqual(resultComponents.day, 2)
        }
    }

}
