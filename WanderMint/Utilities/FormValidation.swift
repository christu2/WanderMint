import Foundation

/// Form validation utilities
struct FormValidation {
    
    // MARK: - General Validation
    
    /// Validate email format
    static func isValidEmail(_ email: String) -> Bool {
        guard !email.isEmpty else { return false }
        
        // Check for whitespace characters (emails shouldn't contain spaces)
        guard !email.contains(" ") && !email.contains("\t") && !email.contains("\n") else { return false }
        
        let emailComponents = email.components(separatedBy: "@")
        guard emailComponents.count == 2 else { return false }
        let local = emailComponents[0]
        let domain = emailComponents[1]
        
        // Check local part
        guard !local.isEmpty else { return false }
        guard !local.contains("..") else { return false }
        
        // Check domain part
        guard !domain.isEmpty else { return false }
        guard !domain.hasPrefix(".") && !domain.hasSuffix(".") else { return false }
        guard !domain.contains("..") else { return false }
        
        let domainComponents = domain.components(separatedBy: ".")
        return domainComponents.count >= 2 && domainComponents.allSatisfy { !$0.isEmpty }
    }
    
    /// Validate password strength (minimum 8 characters with complexity requirements)
    static func isValidPassword(_ password: String) -> Bool {
        guard password.count >= 8 else { return false }
        
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasDigit = password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecialChar = password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
        
        return hasUppercase && hasLowercase && hasDigit && hasSpecialChar
    }
    
    /// Validate name format
    static func isValidName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        
        let nameRegex = #"^[a-zA-ZÀ-ÿ\s\-']+$"#
        return NSPredicate(format: "SELF MATCHES %@", nameRegex).evaluate(with: trimmed)
    }
    
    /// Validate date range
    static func isValidDateRange(start: Date, end: Date) -> Bool {
        return start < end
    }
    
    /// Validate trip title
    static func isValidTripTitle(_ title: String) -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2
    }
    
    /// Validate destination
    static func isValidDestination(_ destination: String) -> Bool {
        let trimmed = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 2
    }
    
    /// Validate points amount
    static func isValidPointsAmount(_ amount: Int) -> Bool {
        return amount >= 0
    }
    
    /// Validate provider name
    static func isValidProviderName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty
    }
    
    /// Trim whitespace from string
    static func trimWhitespace(_ input: String) -> String {
        return input.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Sanitize input by removing potentially harmful characters
    static func sanitizeInput(_ input: String) -> String {
        return input
            // Remove HTML/script tags first
            .replacingOccurrences(of: #"<[^>]*>"#, with: "", options: .regularExpression)
            // Then remove remaining problematic characters
            .replacingOccurrences(of: "&", with: "")
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "script", with: "", options: .caseInsensitive)
    }
    
    // MARK: - Trip Validation
    struct Trip {
        
        /// Validate destinations array
        static func validateDestinations(_ destinations: [String]) -> FormValidationResult {
            let nonEmptyDestinations = destinations.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            
            if nonEmptyDestinations.isEmpty {
                return .invalid("Please enter at least one destination")
            }
            
            if nonEmptyDestinations.count > 10 {
                return .invalid("Maximum 10 destinations allowed")
            }
            
            // Check for duplicate destinations
            let uniqueDestinations = Set(nonEmptyDestinations.map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) })
            if uniqueDestinations.count != nonEmptyDestinations.count {
                return .invalid("Please remove duplicate destinations")
            }
            
            return .valid
        }
        
        /// Validate departure location
        static func validateDepartureLocation(_ location: String) -> FormValidationResult {
            let trimmed = location.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                return .invalid("Please enter your departure location")
            }
            if trimmed.count < 2 {
                return .invalid("Departure location must be at least 2 characters")
            }
            return .valid
        }
        
        /// Validate trip dates
        static func validateDates(start: Date, end: Date) -> FormValidationResult {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let startDay = calendar.startOfDay(for: start)
            let endDay = calendar.startOfDay(for: end)
            
            // Check if start date is in the past
            if startDay < today {
                return .invalid("Start date cannot be in the past")
            }
            
            // Check if end date is after start date
            if endDay <= startDay {
                return .invalid("End date must be after start date")
            }
            
            // Check for reasonable trip length (max 1 year)
            let oneYearFromStart = calendar.date(byAdding: .year, value: 1, to: start) ?? start
            if end > oneYearFromStart {
                return .invalid("Trip cannot be longer than one year")
            }
            
            // Check for minimum trip length (at least 1 day)
            let daysBetween = calendar.dateComponents([.day], from: startDay, to: endDay).day ?? 0
            if daysBetween < 1 {
                return .invalid("Trip must be at least one day long")
            }
            
            return .valid
        }
        
        /// Validate group size
        static func validateGroupSize(_ size: Int) -> FormValidationResult {
            if size < 1 {
                return .invalid("Group size must be at least 1 person")
            }
            if size > 20 {
                return .invalid("Maximum group size is 20 people")
            }
            return .valid
        }
        
        /// Validate budget string
        static func validateBudget(_ budget: String) -> FormValidationResult {
            let trimmed = budget.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Budget is optional, so empty is valid
            if trimmed.isEmpty {
                return .valid
            }
            
            // Check if it's a valid number
            if let budgetValue = Double(trimmed.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) {
                if budgetValue < 0 {
                    return .invalid("Budget cannot be negative")
                }
                if budgetValue > 1_000_000 {
                    return .invalid("Budget seems unreasonably high")
                }
                return .valid
            }
            
            return .invalid("Please enter a valid budget amount")
        }
        
        /// Validate flexible dates configuration
        static func validateFlexibleDates(earliest: Date, latest: Date, duration: Int) -> FormValidationResult {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let earliestDay = calendar.startOfDay(for: earliest)
            let latestDay = calendar.startOfDay(for: latest)
            
            if earliestDay < today {
                return .invalid("Earliest start date cannot be in the past")
            }
            
            if latestDay <= earliestDay {
                return .invalid("Latest start date must be after earliest start date")
            }
            
            if duration < 1 {
                return .invalid("Trip duration must be at least 1 day")
            }
            
            if duration > 365 {
                return .invalid("Trip duration cannot exceed 365 days")
            }
            
            return .valid
        }
    }
}

// MARK: - Form Validation Result
enum FormValidationResult: Equatable {
    case valid
    case invalid(String)
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .invalid(let message):
            return message
        }
    }
}

// MARK: - Validation Result for Enhanced Validation
struct ValidationResult {
    let isValid: Bool
    let value: String?
    let errorMessage: String?
    
    init(isValid: Bool, value: String? = nil, errorMessage: String? = nil) {
        self.isValid = isValid
        self.value = value
        self.errorMessage = errorMessage
    }
    
    static func valid(value: String) -> ValidationResult {
        return ValidationResult(isValid: true, value: value, errorMessage: nil)
    }
    
    static func invalid(message: String) -> ValidationResult {
        return ValidationResult(isValid: false, value: nil, errorMessage: message)
    }
}

// MARK: - Enhanced Validation with Content Filtering
extension FormValidation {
    
    /// Enhanced destination validation with content filtering
    static func validateDestinationEnhanced(_ destination: String) -> ValidationResult {
        // Basic validation first
        guard isValidDestination(destination) else {
            return ValidationResult.invalid(message: "Destination must be at least 2 characters")
        }
        
        // Use ContentFilter for enhanced validation
        let contentFilter = ContentFilter.shared
        let contentResult = contentFilter.validateDestination(destination)
        
        // Convert ContentFilterResult to ValidationResult
        switch contentResult {
        case .valid(let value):
            return ValidationResult.valid(value: value)
        case .invalid(let message):
            return ValidationResult.invalid(message: message)
        }
    }
    
    /// Enhanced message validation with content filtering
    static func validateMessageEnhanced(_ message: String) -> ValidationResult {
        let trimmed = trimWhitespace(message)
        guard !trimmed.isEmpty else {
            return ValidationResult.invalid(message: "Message cannot be empty")
        }
        
        guard trimmed.count <= 1000 else {
            return ValidationResult.invalid(message: "Message too long (max 1000 characters)")
        }
        
        return ValidationResult.valid(value: sanitizeInput(trimmed))
    }
    
    /// Enhanced name validation with content filtering
    static func validateNameEnhanced(_ name: String) -> ValidationResult {
        guard isValidName(name) else {
            return ValidationResult.invalid(message: "Please enter a valid name")
        }
        
        return ValidationResult.valid(value: trimWhitespace(name))
    }
    
    /// Enhanced budget validation with content filtering
    static func validateBudgetEnhanced(_ budget: String) -> ValidationResult {
        let trimmed = trimWhitespace(budget)
        
        // Empty budget is valid (optional field)
        if trimmed.isEmpty {
            return ValidationResult.valid(value: "")
        }
        
        // Check if it's a valid number
        if let budgetValue = Double(trimmed.replacingOccurrences(of: "$", with: "").replacingOccurrences(of: ",", with: "")) {
            if budgetValue < 0 {
                return ValidationResult.invalid(message: "Budget cannot be negative")
            }
            if budgetValue > 1_000_000 {
                return ValidationResult.invalid(message: "Budget seems unreasonably high")
            }
            return ValidationResult.valid(value: trimmed)
        }
        
        return ValidationResult.invalid(message: "Please enter a valid budget amount")
    }
}

// MARK: - Validation State
struct ValidationState {
    var destinations: FormValidationResult = .valid
    var departureLocation: FormValidationResult = .valid
    var dates: FormValidationResult = .valid
    var groupSize: FormValidationResult = .valid
    var budget: FormValidationResult = .valid
    var flexibleDates: FormValidationResult = .valid
    
    var isFormValid: Bool {
        return destinations.isValid &&
               departureLocation.isValid &&
               dates.isValid &&
               groupSize.isValid &&
               budget.isValid &&
               flexibleDates.isValid
    }
    
    var firstError: String? {
        return destinations.errorMessage ??
               departureLocation.errorMessage ??
               dates.errorMessage ??
               groupSize.errorMessage ??
               budget.errorMessage ??
               flexibleDates.errorMessage
    }
}