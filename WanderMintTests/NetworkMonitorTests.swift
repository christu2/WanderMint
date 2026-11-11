//
//  NetworkMonitorTests.swift
//  WanderMintTests
//

import XCTest
@testable import WanderMint

final class NetworkMonitorTests: XCTestCase {

    func testNetworkUnavailableError() {
        let error = TravelAppError.networkUnavailable()

        if case .networkError(let message) = error {
            XCTAssertEqual(message, "Network connection unavailable")
        } else {
            XCTFail("Expected .networkError, but got \(error)")
        }
    }

    func testRequestTimeoutError() {
        let error = TravelAppError.requestTimeout()

        if case .networkError(let message) = error {
            XCTAssertEqual(message, "Request timed out")
        } else {
            XCTFail("Expected .networkError, but got \(error)")
        }
    }

    func testInvalidResponseError() {
        let error = TravelAppError.invalidResponse()

        if case .networkError(let message) = error {
            XCTAssertEqual(message, "Invalid response from server")
        } else {
            XCTFail("Expected .networkError, but got \(error)")
        }
    }
}
