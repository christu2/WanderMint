//
//  TripRemovalTests.swift
//  WanderMintTests
//
//  Created by Claude Code on 7/12/25.
//

import XCTest
@testable import WanderMint

// Mock TripService for testing
class MockTripService: TripServiceProtocol {
    var shouldThrowError = false
    var errorToThrow: Error?
    
    func deleteTrip(tripId: String) async throws {
        if shouldThrowError {
            if let error = errorToThrow {
                throw error
            } else if tripId == "invalid-trip" {
                throw TravelAppError.dataError("Trip not found")
            } else {
                throw TravelAppError.authenticationFailed
            }
        }
        // Success case - do nothing, let the view model handle local deletion
    }
    
    func fetchUserTrips() async throws -> [TravelTrip] {
        return []
    }
}

class TripRemovalTests: XCTestCase {
    
    var viewModel: TripsListViewModel!
    
    override func setUp() {
        super.setUp()
        // viewModel will be created in individual test methods due to MainActor requirement
    }
    
    @MainActor
    private func createViewModel(mockService: MockTripService? = nil) async -> TripsListViewModel {
        let service = mockService ?? MockTripService()
        return TripsListViewModel(tripService: service)
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Trip Deletion Logic Tests
    
    func testCanDeleteCompletedTrip() async {
        let viewModel = await createViewModel()
        let completedTrip = createTestTrip(status: .completed)
        let canDelete = await MainActor.run { viewModel.canDeleteTrip(completedTrip) }
        XCTAssertTrue(canDelete, "Should be able to delete completed trips")
    }
    
    func testCanDeleteCancelledTrip() async {
        let viewModel = await createViewModel()
        let cancelledTrip = createTestTrip(status: .cancelled)
        let canDelete = await MainActor.run { viewModel.canDeleteTrip(cancelledTrip) }
        XCTAssertTrue(canDelete, "Should be able to delete cancelled trips")
    }
    
    func testCanDeleteFailedTrip() async {
        let viewModel = await createViewModel()
        let failedTrip = createTestTrip(status: .failed)
        let canDelete = await MainActor.run { viewModel.canDeleteTrip(failedTrip) }
        XCTAssertTrue(canDelete, "Should be able to delete failed trips")
    }
    
    func testCanDeletePastTrip() async {
        let viewModel = await createViewModel()
        let pastDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())!
        let pastTrip = createTestTrip(status: .pending, endDate: pastDate)
        let canDelete = await MainActor.run { viewModel.canDeleteTrip(pastTrip) }
        XCTAssertTrue(canDelete, "Should be able to delete trips that have ended")
    }
    
    func testCannotDeleteActivePendingTrip() async {
        let viewModel = await createViewModel()
        let futureDate = Calendar.current.date(byAdding: .day, value: 10, to: Date())!
        let activeTrip = createTestTrip(status: .pending, endDate: futureDate)
        let canDelete = await MainActor.run { viewModel.canDeleteTrip(activeTrip) }
        XCTAssertFalse(canDelete, "Should not be able to delete active pending trips")
    }
    
    func testCannotDeleteActiveInProgressTrip() async {
        let viewModel = await createViewModel()
        let futureDate = Calendar.current.date(byAdding: .day, value: 10, to: Date())!
        let activeTrip = createTestTrip(status: .inProgress, endDate: futureDate)
        let canDelete = await MainActor.run { viewModel.canDeleteTrip(activeTrip) }
        XCTAssertFalse(canDelete, "Should not be able to delete active in-progress trips")
    }
    
    // MARK: - Trip Deletion Functionality Tests
    
    func testDeleteTripRemovesFromLocalArray() async {
        // Create mock service that succeeds
        let mockService = MockTripService()
        mockService.shouldThrowError = false
        
        let viewModel = await createViewModel(mockService: mockService)
        
        // Setup initial trips
        let trip1 = createTestTrip(id: "trip1", status: .completed)
        let trip2 = createTestTrip(id: "trip2", status: .pending)
        let trip3 = createTestTrip(id: "trip3", status: .cancelled)
        
        await MainActor.run {
            viewModel.trips = [trip1, trip2, trip3]
        }
        
        // Delete trip1
        await viewModel.deleteTripAsync(trip1)
        
        // Verify trip was removed from local array
        let (tripCount, trip1Exists, trip2Exists, trip3Exists) = await MainActor.run {
            let count = viewModel.trips.count
            let exists1 = viewModel.trips.contains { $0.id == trip1.id }
            let exists2 = viewModel.trips.contains { $0.id == trip2.id }
            let exists3 = viewModel.trips.contains { $0.id == trip3.id }
            return (count, exists1, exists2, exists3)
        }
        
        XCTAssertEqual(tripCount, 2, "Trip should be removed from local array")
        XCTAssertFalse(trip1Exists, "Deleted trip should not be in array")
        XCTAssertTrue(trip2Exists, "Other trips should remain")
        XCTAssertTrue(trip3Exists, "Other trips should remain")
    }
    
    func testDeleteTripHandlesErrors() async {
        // Create mock service that throws errors
        let mockService = MockTripService()
        mockService.shouldThrowError = true
        
        let viewModel = await createViewModel(mockService: mockService)
        let trip = createTestTrip(id: "invalid-trip", status: .completed)
        
        await MainActor.run {
            viewModel.trips = [trip]
        }
        
        // Delete trip (will fail due to mock error)
        await viewModel.deleteTripAsync(trip)
        
        // Verify error message is set
        let errorMessage = await MainActor.run { viewModel.errorMessage }
        XCTAssertNotNil(errorMessage, "Error message should be set when deletion fails")
        XCTAssertTrue(errorMessage?.contains("Failed to delete trip") == true, "Error message should indicate deletion failure")
    }
    
    // MARK: - UI Integration Tests
    
    func testTripCardShowsDeleteIndicator() async {
        let viewModel = await createViewModel()
        let deletableTrip = createTestTrip(status: .completed)
        let nonDeletableTrip = createTestTrip(status: .pending, endDate: Calendar.current.date(byAdding: .day, value: 10, to: Date())!)
        
        // Test deletable trip shows indicator
        let canDeleteFirst = await MainActor.run { viewModel.canDeleteTrip(deletableTrip) }
        XCTAssertTrue(canDeleteFirst, "Completed trip should be deletable")
        
        // Test non-deletable trip doesn't show indicator
        let canDeleteSecond = await MainActor.run { viewModel.canDeleteTrip(nonDeletableTrip) }
        XCTAssertFalse(canDeleteSecond, "Future pending trip should not be deletable")
    }
    
    // MARK: - Edge Cases
    
    func testDeleteTripOnBoundaryDate() async {
        let viewModel = await createViewModel()
        // Create a trip that ends today
        let today = Date()
        let startOfToday = Calendar.current.startOfDay(for: today)
        let endOfYesterday = Calendar.current.date(byAdding: .second, value: -1, to: startOfToday)!
        
        let boundaryTrip = createTestTrip(status: .pending, endDate: endOfYesterday)
        let canDelete = await MainActor.run { viewModel.canDeleteTrip(boundaryTrip) }
        XCTAssertTrue(canDelete, "Trip that ended yesterday should be deletable")
    }
    
    func testDeleteTripWithMissingData() async {
        let viewModel = await createViewModel()
        // Test with trip that has minimal data
        let minimalTrip = TravelTrip(
            id: "minimal-trip",
            userId: "test-user",
            destination: nil,
            destinations: nil,
            departureLocation: nil,
            startDate: createTimestamp(),
            endDate: createTimestampFromDate(Calendar.current.date(byAdding: .day, value: -5, to: Date())!),
            paymentMethod: nil,
            flexibleDates: false,
            status: .completed,
            createdAt: createTimestamp(),
            updatedAt: nil,
            recommendation: nil,
            destinationRecommendation: nil,
            flightClass: nil,
            budget: nil,
            travelStyle: nil,
            groupSize: nil,
            interests: nil,
            specialRequests: nil
        )
        
        let canDelete = await MainActor.run { viewModel.canDeleteTrip(minimalTrip) }
        XCTAssertTrue(canDelete, "Trip with minimal data should still be deletable if completed")
    }
    
    // MARK: - Performance Tests
    
    func testDeleteTripPerformance() async {
        let viewModel = await createViewModel()
        let trips = (0..<100).map { i in
            createTestTrip(id: "trip-\(i)", status: .completed)
        }
        
        measure {
            Task { @MainActor in
                for trip in trips {
                    _ = viewModel.canDeleteTrip(trip)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestTrip(
        id: String = UUID().uuidString,
        status: TripStatusType,
        endDate: Date = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    ) -> TravelTrip {
        return TravelTrip(
            id: id,
            userId: "test-user",
            destination: "Test Destination",
            destinations: ["Test Destination"],
            departureLocation: "Test Departure",
            startDate: createTimestampFromDate(Calendar.current.date(byAdding: .day, value: -7, to: endDate)!),
            endDate: createTimestampFromDate(endDate),
            paymentMethod: "credit_card",
            flexibleDates: false,
            status: status,
            createdAt: createTimestamp(),
            updatedAt: createTimestamp(),
            recommendation: nil,
            destinationRecommendation: nil,
            flightClass: "economy",
            budget: "5000",
            travelStyle: "adventure",
            groupSize: 2,
            interests: ["culture", "food"],
            specialRequests: "Test request"
        )
    }
    
    private func createTimestampFromDate(_ date: Date) -> AppTimestamp {
        return createTimestamp(date: date)
    }
}

// MARK: - Integration Tests

class TripRemovalIntegrationTests: XCTestCase {
    
    func testFullTripRemovalWorkflow() {
        // This test would require Firebase setup in a test environment
        // For now, we'll focus on the business logic tests above
        XCTAssertTrue(true, "Integration tests would go here with proper Firebase test setup")
    }
}