import XCTest
@testable import WanderMint

class ContentFilterTests: XCTestCase {
    
    var contentFilter: ContentFilter!
    
    override func setUp() {
        super.setUp()
        contentFilter = ContentFilter.shared
    }
    
    override func tearDown() {
        contentFilter = nil
        super.tearDown()
    }
    
    // MARK: - Destination Validation Tests
    
    func testValidDestinations() {
        let validDestinations = [
            "Paris",
            "New York City",
            "Tokyo",
            "London, UK",
            "San Francisco, CA",
            "Barcelona, Spain",
            "Sydney, Australia"
        ]
        
        for destination in validDestinations {
            let result = contentFilter.validateDestination(destination)
            XCTAssertTrue(result.isValid, "Destination '\(destination)' should be valid")
            XCTAssertEqual(result.value, destination, "Destination value should match input")
        }
    }
    
    func testInvalidDestinations() {
        let invalidDestinations = [
            "f*ck this place",
            "damn city", 
            "sh*t town",
            "hell hole",
            "stupid place"
        ]
        
        for destination in invalidDestinations {
            let result = contentFilter.validateDestination(destination)
            XCTAssertFalse(result.isValid, "Destination '\(destination)' should be invalid")
        }
    }
    
    func testEmptyDestination() {
        let result = contentFilter.validateDestination("")
        XCTAssertFalse(result.isValid, "Empty destination should be invalid")
    }
    
    func testWhitespaceOnlyDestination() {
        let result = contentFilter.validateDestination("   ")
        XCTAssertFalse(result.isValid, "Whitespace-only destination should be invalid")
    }
    
    func testDestinationWithSpecialCharacters() {
        let validSpecialChars = [
            "São Paulo",
            "México City",
            "Zürich",
            "Saint-Tropez",
            "O'Hare Airport"
        ]
        
        for destination in validSpecialChars {
            let result = contentFilter.validateDestination(destination)
            XCTAssertTrue(result.isValid, "Destination '\(destination)' with special characters should be valid")
        }
    }
    
    // MARK: - User Message Validation Tests
    
    func testValidUserMessages() {
        let validMessages = [
            "I would like to visit Paris next month",
            "Looking for a romantic getaway with my partner",
            "Planning a family vacation with kids",
            "Need help with business travel arrangements",
            "Interested in adventure travel and hiking"
        ]
        
        for message in validMessages {
            let result = contentFilter.validateUserMessage(message)
            XCTAssertTrue(result.isValid, "Message '\(message)' should be valid")
        }
    }
    
    func testInvalidUserMessages() {
        let invalidMessages = [
            "This f*cking service sucks",
            "You're all idiots",
            "Damn this is terrible",
            "What the hell is wrong with you",
            "This is bullsh*t"
        ]
        
        for message in invalidMessages {
            let result = contentFilter.validateUserMessage(message)
            XCTAssertFalse(result.isValid, "Message '\(message)' should be invalid")
        }
    }
    
    func testMessageLength() {
        let tooLongMessage = String(repeating: "a", count: 1001)
        let result = contentFilter.validateUserMessage(tooLongMessage)
        XCTAssertFalse(result.isValid, "Message over 1000 characters should be invalid")
    }
    
    func testEmptyMessage() {
        let result = contentFilter.validateUserMessage("")
        XCTAssertFalse(result.isValid, "Empty message should be invalid")
    }
    
    // MARK: - Name Validation Tests
    
    func testValidNames() {
        let validNames = [
            "John Smith",
            "María González",
            "Jean-Pierre Dubois",
            "O'Connor",
            "李小明",
            "Sarah Jane"
        ]
        
        for name in validNames {
            let result = contentFilter.validateName(name)
            XCTAssertTrue(result.isValid, "Name '\(name)' should be valid")
        }
    }
    
    func testInvalidNames() {
        let invalidNames = [
            "John123",
            "Test@User",
            "User!Name",
            "123456",
            "user@domain.com"
        ]
        
        for name in invalidNames {
            let result = contentFilter.validateName(name)
            XCTAssertFalse(result.isValid, "Name '\(name)' should be invalid")
        }
    }
    
    func testNameWithProfanity() {
        let profaneNames = [
            "F*ck Face",
            "Damn User",
            "Sh*t Head"
        ]
        
        for name in profaneNames {
            let result = contentFilter.validateName(name)
            XCTAssertFalse(result.isValid, "Name '\(name)' with profanity should be invalid")
        }
    }
    
    // MARK: - Budget Validation Tests
    
    func testValidBudgets() {
        let validBudgets = [
            "1000",
            "$2500",
            "5,000",
            "$10,000",
            "500.50",
            "$1,500.00"
        ]
        
        for budget in validBudgets {
            let result = contentFilter.validateBudget(budget)
            XCTAssertTrue(result.isValid, "Budget '\(budget)' should be valid")
        }
    }
    
    func testInvalidBudgets() {
        let invalidBudgets = [
            "not a number",
            "free",
            "cheap",
            "expensive",
            "a lot"
        ]
        
        for budget in invalidBudgets {
            let result = contentFilter.validateBudget(budget)
            XCTAssertFalse(result.isValid, "Budget '\(budget)' should be invalid")
        }
    }
    
    func testEmptyBudget() {
        let result = contentFilter.validateBudget("")
        XCTAssertTrue(result.isValid, "Empty budget should be valid (optional field)")
    }
    
    // MARK: - Security Tests
    
    func testXSSAttempts() {
        let xssAttempts = [
            "<script>alert('xss')</script>",
            "javascript:alert('xss')",
            "<img src=x onerror=alert('xss')>",
            "';DROP TABLE users;--"
        ]
        
        for attempt in xssAttempts {
            let result = contentFilter.validateUserMessage(attempt)
            XCTAssertFalse(result.isValid, "XSS attempt '\(attempt)' should be blocked")
        }
    }
    
    func testSQLInjectionAttempts() {
        let sqlInjections = [
            "'; DROP TABLE destinations; --",
            "1' OR '1'='1",
            "UNION SELECT * FROM users",
            "admin'--"
        ]
        
        for injection in sqlInjections {
            let result = contentFilter.validateDestination(injection)
            XCTAssertFalse(result.isValid, "SQL injection '\(injection)' should be blocked")
        }
    }
    
    // MARK: - Performance Tests
    
    func testPerformanceWithManyMessages() {
        let messages = Array(1...1000).map { "This is test message number \($0)" }
        
        measure {
            for message in messages {
                _ = contentFilter.validateUserMessage(message)
            }
        }
    }
    
    func testPerformanceWithLongMessages() {
        let longMessages = Array(1...100).map { _ in String(repeating: "test ", count: 100) }
        
        measure {
            for message in longMessages {
                _ = contentFilter.validateUserMessage(message)
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testUnicodeCharacters() {
        let unicodeStrings = [
            "🏖️ Beach vacation",
            "🗼 Tokyo Tower",
            "🏔️ Mountain hiking",
            "🏛️ Ancient ruins",
            "🌊 Ocean cruise"
        ]
        
        for string in unicodeStrings {
            let result = contentFilter.validateDestination(string)
            XCTAssertTrue(result.isValid, "Unicode string '\(string)' should be valid")
        }
    }
    
    func testMixedLanguages() {
        let mixedLanguageStrings = [
            "Tokyo 東京",
            "Paris França",
            "London Inglaterra",
            "Berlin Deutschland"
        ]
        
        for string in mixedLanguageStrings {
            let result = contentFilter.validateDestination(string)
            XCTAssertTrue(result.isValid, "Mixed language string '\(string)' should be valid")
        }
    }
    
    func testCaseSensitivity() {
        let variations = [
            "PARIS",
            "paris",
            "Paris",
            "pArIs"
        ]
        
        for variation in variations {
            let result = contentFilter.validateDestination(variation)
            XCTAssertTrue(result.isValid, "Case variation '\(variation)' should be valid")
        }
    }
}