import XCTest
@testable import WanderMint

class FormValidationTests: XCTestCase {
    
    // MARK: - Email Validation Tests
    
    func testValidEmails() {
        let validEmails = [
            "user@example.com",
            "test.email@domain.co.uk",
            "user+tag@example.org",
            "firstname.lastname@company.com",
            "user123@test-domain.com"
        ]
        
        for email in validEmails {
            XCTAssertTrue(FormValidation.isValidEmail(email), "Email '\(email)' should be valid")
        }
    }
    
    func testInvalidEmails() {
        let invalidEmails = [
            "",
            "invalid-email",
            "@example.com",
            "user@",
            "user@@example.com",
            "user@.com",
            "user@example.",
            "user@example..com",
            "user name@example.com",
            "user@exam ple.com"
        ]
        
        for email in invalidEmails {
            XCTAssertFalse(FormValidation.isValidEmail(email), "Email '\(email)' should be invalid")
        }
    }
    
    // MARK: - Password Validation Tests
    
    func testValidPasswords() {
        let validPasswords = [
            "password123",
            "MySecurePassword!",
            "12345678",
            "TestPassword2023",
            "A1B2C3D4E5F6G7H8"
        ]
        
        for password in validPasswords {
            XCTAssertTrue(FormValidation.isValidPassword(password), "Password '\(password)' should be valid")
        }
    }
    
    func testInvalidPasswords() {
        let invalidPasswords = [
            "",
            "short",
            "1234567", // Only 7 characters
            "abc123"   // Only 6 characters
        ]
        
        for password in invalidPasswords {
            XCTAssertFalse(FormValidation.isValidPassword(password), "Password '\(password)' should be invalid")
        }
    }
    
    // MARK: - Name Validation Tests
    
    func testValidNames() {
        let validNames = [
            "John Doe",
            "Mary Jane",
            "Jean-Pierre",
            "O'Connor",
            "María García",
            "José",
            "Anne-Marie"
        ]
        
        for name in validNames {
            XCTAssertTrue(FormValidation.isValidName(name), "Name '\(name)' should be valid")
        }
    }
    
    func testInvalidNames() {
        let invalidNames = [
            "",
            "   ",
            "John123",
            "User@Domain",
            "Test#Name",
            "123456",
            "John$Doe"
        ]
        
        for name in invalidNames {
            XCTAssertFalse(FormValidation.isValidName(name), "Name '\(name)' should be invalid")
        }
    }
    
    // MARK: - Date Range Validation Tests
    
    func testValidDateRanges() {
        let now = Date()
        let future = now.addingTimeInterval(3600) // 1 hour later
        
        XCTAssertTrue(FormValidation.isValidDateRange(start: now, end: future))
        
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        XCTAssertTrue(FormValidation.isValidDateRange(start: now, end: tomorrow))
    }
    
    func testInvalidDateRanges() {
        let now = Date()
        let past = now.addingTimeInterval(-3600) // 1 hour earlier
        
        XCTAssertFalse(FormValidation.isValidDateRange(start: now, end: past))
        XCTAssertFalse(FormValidation.isValidDateRange(start: now, end: now))
    }
    
    // MARK: - Trip Title Validation Tests
    
    func testValidTripTitles() {
        let validTitles = [
            "Paris Adventure",
            "Weekend Getaway",
            "Business Trip to Tokyo",
            "Family Vacation 2024",
            "Honeymoon in Italy"
        ]
        
        for title in validTitles {
            XCTAssertTrue(FormValidation.isValidTripTitle(title), "Trip title '\(title)' should be valid")
        }
    }
    
    func testInvalidTripTitles() {
        let invalidTitles = [
            "",
            "   ",
            "A", // Too short
            "B"  // Too short
        ]
        
        for title in invalidTitles {
            XCTAssertFalse(FormValidation.isValidTripTitle(title), "Trip title '\(title)' should be invalid")
        }
    }
    
    // MARK: - Destination Validation Tests
    
    func testValidDestinations() {
        let validDestinations = [
            "Paris",
            "New York City",
            "Tokyo, Japan",
            "London, UK",
            "São Paulo, Brazil"
        ]
        
        for destination in validDestinations {
            XCTAssertTrue(FormValidation.isValidDestination(destination), "Destination '\(destination)' should be valid")
        }
    }
    
    func testInvalidDestinations() {
        let invalidDestinations = [
            "",
            "   ",
            "A", // Too short
            "B"  // Too short
        ]
        
        for destination in invalidDestinations {
            XCTAssertFalse(FormValidation.isValidDestination(destination), "Destination '\(destination)' should be invalid")
        }
    }
    
    // MARK: - Points Amount Validation Tests
    
    func testValidPointsAmounts() {
        let validAmounts = [0, 1, 100, 50000, 999999]
        
        for amount in validAmounts {
            XCTAssertTrue(FormValidation.isValidPointsAmount(amount), "Points amount '\(amount)' should be valid")
        }
    }
    
    func testInvalidPointsAmounts() {
        let invalidAmounts = [-1, -100, -999]
        
        for amount in invalidAmounts {
            XCTAssertFalse(FormValidation.isValidPointsAmount(amount), "Points amount '\(amount)' should be invalid")
        }
    }
    
    // MARK: - Provider Name Validation Tests
    
    func testValidProviderNames() {
        let validNames = [
            "American Airlines",
            "Marriott",
            "Chase",
            "United Airlines",
            "Hilton Hotels"
        ]
        
        for name in validNames {
            XCTAssertTrue(FormValidation.isValidProviderName(name), "Provider name '\(name)' should be valid")
        }
    }
    
    func testInvalidProviderNames() {
        let invalidNames = [
            "",
            "   ",
            "\t\n"
        ]
        
        for name in invalidNames {
            XCTAssertFalse(FormValidation.isValidProviderName(name), "Provider name '\(name)' should be invalid")
        }
    }
    
    // MARK: - Input Sanitization Tests
    
    func testTrimWhitespace() {
        let inputs = [
            ("  hello  ", "hello"),
            ("\t\ntest\t\n", "test"),
            ("   spaced   text   ", "spaced   text"),
            ("no-spaces", "no-spaces"),
            ("", "")
        ]
        
        for (input, expected) in inputs {
            XCTAssertEqual(FormValidation.trimWhitespace(input), expected)
        }
    }
    
    func testSanitizeInput() {
        let inputs = [
            ("<script>alert('xss')</script>", "alert('xss')"),
            ("Hello & World", "Hello  World"),
            ("Test > input", "Test  input"),
            ("Script tag test", " tag test"),
            ("Clean input", "Clean input")
        ]
        
        for (input, expected) in inputs {
            XCTAssertEqual(FormValidation.sanitizeInput(input), expected)
        }
    }
    
    // MARK: - Trip Validation Tests
    
    func testValidateDestinations() {
        // Valid destinations
        let validDestinations = ["Paris", "London", "Tokyo"]
        let result = FormValidation.Trip.validateDestinations(validDestinations)
        XCTAssertEqual(result, .valid)
        
        // Empty destinations
        let emptyDestinations: [String] = []
        let emptyResult = FormValidation.Trip.validateDestinations(emptyDestinations)
        XCTAssertEqual(emptyResult, .invalid("Please enter at least one destination"))
        
        // Destinations with empty strings
        let mixedDestinations = ["Paris", "", "London", "   "]
        let mixedResult = FormValidation.Trip.validateDestinations(mixedDestinations)
        XCTAssertEqual(mixedResult, .valid)
        
        // Duplicate destinations
        let duplicateDestinations = ["Paris", "paris", "London"]
        let duplicateResult = FormValidation.Trip.validateDestinations(duplicateDestinations)
        XCTAssertEqual(duplicateResult, .invalid("Please remove duplicate destinations"))
    }
    
    func testValidateDepartureLocation() {
        // Valid departure
        let validResult = FormValidation.Trip.validateDepartureLocation("New York")
        XCTAssertEqual(validResult, .valid)
        
        // Empty departure
        let emptyResult = FormValidation.Trip.validateDepartureLocation("")
        XCTAssertEqual(emptyResult, .invalid("Please enter your departure location"))
        
        // Too short departure
        let shortResult = FormValidation.Trip.validateDepartureLocation("A")
        XCTAssertEqual(shortResult, .invalid("Departure location must be at least 2 characters"))
    }
    
    func testValidateTripDates() {
        let calendar = Calendar.current
        let today = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: today)!
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoYearsFromNow = calendar.date(byAdding: .year, value: 2, to: today)!
        
        // Valid dates
        let validResult = FormValidation.Trip.validateDates(start: tomorrow, end: dayAfterTomorrow)
        XCTAssertEqual(validResult, .valid)
        
        // Start date in the past
        let pastResult = FormValidation.Trip.validateDates(start: yesterday, end: tomorrow)
        XCTAssertEqual(pastResult, .invalid("Start date cannot be in the past"))
        
        // End date before start date
        let invalidOrderResult = FormValidation.Trip.validateDates(start: tomorrow, end: today)
        XCTAssertEqual(invalidOrderResult, .invalid("End date must be after start date"))
        
        // Trip too long
        let tooLongResult = FormValidation.Trip.validateDates(start: tomorrow, end: twoYearsFromNow)
        XCTAssertEqual(tooLongResult, .invalid("Trip cannot be longer than one year"))
    }
    
    func testValidateGroupSize() {
        // Valid group sizes
        let validResult = FormValidation.Trip.validateGroupSize(4)
        XCTAssertEqual(validResult, .valid)
        
        // Invalid group size (too small)
        let tooSmallResult = FormValidation.Trip.validateGroupSize(0)
        XCTAssertEqual(tooSmallResult, .invalid("Group size must be at least 1 person"))
        
        // Invalid group size (too large)
        let tooLargeResult = FormValidation.Trip.validateGroupSize(50)
        XCTAssertEqual(tooLargeResult, .invalid("Maximum group size is 20 people"))
    }
    
    func testValidateBudget() {
        // Valid budgets
        let validBudgets = ["", "1000", "$2500", "5,000", "$10,000.50"]
        for budget in validBudgets {
            let result = FormValidation.Trip.validateBudget(budget)
            XCTAssertEqual(result, .valid, "Budget '\(budget)' should be valid")
        }
        
        // Invalid budgets
        let negativeBudget = FormValidation.Trip.validateBudget("-500")
        XCTAssertEqual(negativeBudget, .invalid("Budget cannot be negative"))
        
        let unreasonableBudget = FormValidation.Trip.validateBudget("2000000")
        XCTAssertEqual(unreasonableBudget, .invalid("Budget seems unreasonably high"))
        
        let invalidFormat = FormValidation.Trip.validateBudget("not a number")
        XCTAssertEqual(invalidFormat, .invalid("Please enter a valid budget amount"))
    }
    
    func testValidateFlexibleDates() {
        let calendar = Calendar.current
        let today = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: today)!
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        // Valid flexible dates
        let validResult = FormValidation.Trip.validateFlexibleDates(
            earliest: tomorrow,
            latest: dayAfterTomorrow,
            duration: 7
        )
        XCTAssertEqual(validResult, .valid)
        
        // Earliest date in the past
        let pastResult = FormValidation.Trip.validateFlexibleDates(
            earliest: yesterday,
            latest: tomorrow,
            duration: 7
        )
        XCTAssertEqual(pastResult, .invalid("Earliest start date cannot be in the past"))
        
        // Latest date before earliest
        let invalidOrderResult = FormValidation.Trip.validateFlexibleDates(
            earliest: dayAfterTomorrow,
            latest: tomorrow,
            duration: 7
        )
        XCTAssertEqual(invalidOrderResult, .invalid("Latest start date must be after earliest start date"))
        
        // Invalid duration
        let invalidDurationResult = FormValidation.Trip.validateFlexibleDates(
            earliest: tomorrow,
            latest: dayAfterTomorrow,
            duration: 0
        )
        XCTAssertEqual(invalidDurationResult, .invalid("Trip duration must be at least 1 day"))
        
        let tooLongDurationResult = FormValidation.Trip.validateFlexibleDates(
            earliest: tomorrow,
            latest: dayAfterTomorrow,
            duration: 400
        )
        XCTAssertEqual(tooLongDurationResult, .invalid("Trip duration cannot exceed 365 days"))
    }
    
    // MARK: - Validation State Tests
    
    func testValidationState() {
        var state = ValidationState()
        XCTAssertTrue(state.isFormValid)
        XCTAssertNil(state.firstError)
        
        state.destinations = .invalid("Invalid destinations")
        XCTAssertFalse(state.isFormValid)
        XCTAssertEqual(state.firstError, "Invalid destinations")
        
        state.departureLocation = .invalid("Invalid departure")
        XCTAssertFalse(state.isFormValid)
        XCTAssertEqual(state.firstError, "Invalid destinations") // Should return first error
        
        state.destinations = .valid
        XCTAssertFalse(state.isFormValid)
        XCTAssertEqual(state.firstError, "Invalid departure")
    }
    
    // MARK: - Enhanced Validation Tests
    
    func testEnhancedValidation() {
        // Test enhanced destination validation
        let destination = "Paris"
        let result = FormValidation.validateDestinationEnhanced(destination)
        XCTAssertTrue(result.isValid)
        
        // Test enhanced message validation
        let message = "I would like to visit Paris"
        let messageResult = FormValidation.validateMessageEnhanced(message)
        XCTAssertTrue(messageResult.isValid)
        
        // Test enhanced name validation
        let name = "John Doe"
        let nameResult = FormValidation.validateNameEnhanced(name)
        XCTAssertTrue(nameResult.isValid)
        
        // Test enhanced budget validation
        let budget = "1000"
        let budgetResult = FormValidation.validateBudgetEnhanced(budget)
        XCTAssertTrue(budgetResult.isValid)
    }
    
    // MARK: - Performance Tests
    
    func testValidationPerformance() {
        let testData = Array(1...1000).map { "test-email-\($0)@example.com" }
        
        measure {
            for email in testData {
                _ = FormValidation.isValidEmail(email)
            }
        }
    }
    
    func testComplexValidationPerformance() {
        let destinations = Array(1...100).map { "Destination \($0)" }
        
        measure {
            _ = FormValidation.Trip.validateDestinations(destinations)
        }
    }
}
