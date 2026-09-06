//
//  FirebaseCompatTests.swift
//  WanderMintTests
//

import XCTest
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif
@testable import WanderMint

final class FirebaseCompatTests: XCTestCase {

    func testCreateTimestampCurrent() {
        let before = Date()
        let timestamp = createTimestamp()
        let after = Date()

        #if canImport(FirebaseFirestore)
        // Timestamp from Firebase has dateValue() method
        let timestampDate = timestamp.dateValue()
        #else
        // AppTimestamp fallback has dateValue property
        let timestampDate = timestamp.dateValue
        #endif

        // Check that the timestamp is between before and after (allowing a small delta for precision)
        XCTAssertTrue(timestampDate.timeIntervalSince1970 >= before.timeIntervalSince1970 - 0.001)
        XCTAssertTrue(timestampDate.timeIntervalSince1970 <= after.timeIntervalSince1970 + 0.001)
    }

    func testCreateTimestampWithDate() {
        let specificDate = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
        let timestamp = createTimestamp(date: specificDate)

        #if canImport(FirebaseFirestore)
        // Timestamp from Firebase has dateValue() method
        let timestampDate = timestamp.dateValue()
        #else
        // AppTimestamp fallback has dateValue property
        let timestampDate = timestamp.dateValue
        #endif

        XCTAssertEqual(timestampDate.timeIntervalSince1970, specificDate.timeIntervalSince1970, accuracy: 0.001)
    }

    // Add tests for the fallback struct methods just in case we are running without Firebase
    func testAppTimestampFallback() {
        #if !canImport(FirebaseFirestore)
        let now = Date()
        let timestamp = AppTimestamp(date: now)
        XCTAssertEqual(timestamp.seconds, Int64(now.timeIntervalSince1970))
        let timestampDate = timestamp.dateValue
        XCTAssertEqual(timestampDate.timeIntervalSince1970, now.timeIntervalSince1970, accuracy: 0.001)
        #endif
    }
}
