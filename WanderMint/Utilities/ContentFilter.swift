import Foundation

/// Content filtering service for user-generated content
class ContentFilter {
    static let shared = ContentFilter()
    
    private init() {}
    
    // MARK: - Inappropriate Content Detection
    
    private let inappropriateWords = [
        // Basic profanity
        "fuck", "fucking", "shit", "damn", "hell", "bitch", "asshole", "bastard", "stupid",
        // Common variants and related words
        "idiot", "idiots", "suck", "sucks",
        // Stronger profanity (partial list for production safety)
        "motherfucker", "cocksucker", "prick", "cunt", "whore", "slut",
        // Hate speech indicators
        "nazi", "terrorist", "kill", "murder", "suicide", "bomb",
        // Spam indicators
        "free money", "get rich quick", "click here", "buy now",
        // Sexual content
        "porn", "xxx", "sex", "nude", "naked", "erotic"
    ]
    
    private let suspiciousPatterns = [
        // Email patterns
        #"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"#,
        // Phone patterns
        #"\b\d{3}[-.]?\d{3}[-.]?\d{4}\b"#,
        // URL patterns
        #"https?://[^\s]+"#,
        // Credit card patterns (basic)
        #"\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b"#,
        // XSS patterns
        #"<script[^>]*>.*?</script>"#,
        #"javascript:"#,
        #"<[^>]*on\w+\s*="#,
        // SQL injection patterns
        #"'.*--"#,
        #";\s*drop\s+table"#,
        #"union\s+select"#,
        #"1'\s*or\s*'1'\s*=\s*'1"#
    ]
    
    // MARK: - Public Methods
    
    /// Check if content contains inappropriate material
    public func isContentAppropriate(_ text: String) -> Bool {
        let cleanText = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check for empty content
        if cleanText.isEmpty {
            return false
        }
        
        // Check for inappropriate words
        for word in inappropriateWords {
            if cleanText.contains(word) {
                return false
            }
        }
        
        // Check for obfuscated inappropriate words (e.g., f*ck, sh*t)
        if containsObfuscatedProfanity(cleanText) {
            return false
        }
        
        // Check for suspicious patterns
        for pattern in suspiciousPatterns {
            if cleanText.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil {
                return false
            }
        }
        
        // Check for excessive repetition (spam indicator)
        if hasExcessiveRepetition(cleanText) {
            return false
        }
        
        // Check for all caps (shouting)
        if isExcessivelyCapitalized(text) {
            return false
        }
        
        return true
    }
    
    /// Sanitize user input for safe storage and display
    public func sanitizeText(_ text: String) -> String {
        var sanitized = text
        
        // Remove excessive whitespace
        sanitized = sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
        sanitized = sanitized.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        
        // Remove potential HTML/script tags
        sanitized = sanitized.replacingOccurrences(of: #"<[^>]*>"#, with: "", options: .regularExpression)
        
        // Remove control characters
        sanitized = sanitized.components(separatedBy: .controlCharacters).joined()
        
        // Limit length
        if sanitized.count > 1000 {
            sanitized = String(sanitized.prefix(1000))
        }
        
        return sanitized
    }
    
    /// Validate trip destination input
    func validateDestination(_ destination: String) -> ContentFilterResult {
        // Check for inappropriate content BEFORE sanitization
        if !isContentAppropriate(destination) {
            return .invalid("Please enter a valid destination")
        }
        
        let sanitized = sanitizeText(destination)
        
        // Check minimum length
        if sanitized.count < 2 {
            return .invalid("Destination must be at least 2 characters")
        }
        
        // Check maximum length
        if sanitized.count > 100 {
            return .invalid("Destination must be less than 100 characters")
        }
        
        // Check for valid characters (Unicode letters, emojis, spaces, hyphens, apostrophes, commas)
        let validPattern = #"^[\p{L}\p{Emoji}\p{Mn}\s\-',\.]+$"#
        if sanitized.range(of: validPattern, options: .regularExpression) == nil {
            return .invalid("Destination contains invalid characters")
        }
        
        return .valid(sanitized)
    }
    
    /// Validate special requests/comments
    func validateUserMessage(_ message: String) -> ContentFilterResult {
        // Check for inappropriate content BEFORE sanitization
        if !isContentAppropriate(message) {
            return .invalid("Please keep your message appropriate and professional")
        }
        
        let sanitized = sanitizeText(message)
        
        // Empty messages are invalid
        if sanitized.isEmpty {
            return .invalid("Message cannot be empty")
        }
        
        // Check minimum length for non-empty messages
        if sanitized.count < 3 {
            return .invalid("Message must be at least 3 characters")
        }
        
        // Check maximum length
        if sanitized.count > 500 {
            return .invalid("Message must be less than 500 characters")
        }
        
        return .valid(sanitized)
    }
    
    /// Validate budget input
    func validateBudget(_ budget: String) -> ContentFilterResult {
        let sanitized = budget.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Allow empty budget
        if sanitized.isEmpty {
            return .valid("")
        }
        
        // Remove currency symbols and commas
        let numericString = sanitized.replacingOccurrences(of: #"[$,]"#, with: "", options: .regularExpression)
        
        // Check if it's a valid number
        guard let budgetValue = Double(numericString), budgetValue >= 0 else {
            return .invalid("Please enter a valid budget amount")
        }
        
        // Check reasonable budget limits
        if budgetValue > 1000000 {
            return .invalid("Budget amount seems too high")
        }
        
        return .valid(String(format: "%.0f", budgetValue))
    }
    
    /// Validate name input
    func validateName(_ name: String) -> ContentFilterResult {
        let sanitized = sanitizeText(name)
        
        // Check minimum length
        if sanitized.count < 1 {
            return .invalid("Name is required")
        }
        
        // Check maximum length
        if sanitized.count > 50 {
            return .invalid("Name must be less than 50 characters")
        }
        
        // Check for valid name characters (Unicode letters, spaces, hyphens, apostrophes, periods)
        let validPattern = #"^[\p{L}\s\-'\.]+$"#
        if sanitized.range(of: validPattern, options: .regularExpression) == nil {
            return .invalid("Name contains invalid characters")
        }
        
        // Check for inappropriate content
        if !isContentAppropriate(sanitized) {
            return .invalid("Please enter a valid name")
        }
        
        return .valid(sanitized)
    }
    
    // MARK: - Private Helper Methods
    
    private func hasExcessiveRepetition(_ text: String) -> Bool {
        // Check for repeated characters (more than 4 in a row)
        let repeatedCharsPattern = #"(.)\1{4,}"#
        if text.range(of: repeatedCharsPattern, options: .regularExpression) != nil {
            return true
        }
        
        // Check for repeated words
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        var wordCounts: [String: Int] = [:]
        
        for word in words {
            let cleanWord = word.lowercased()
            wordCounts[cleanWord, default: 0] += 1
            
            // If any word appears more than 5 times, it's spam
            if wordCounts[cleanWord]! > 5 {
                return true
            }
        }
        
        return false
    }
    
    private func isExcessivelyCapitalized(_ text: String) -> Bool {
        let letters = text.filter { $0.isLetter }
        let uppercaseLetters = text.filter { $0.isUppercase }
        
        // If more than 70% of letters are uppercase and text is longer than 10 chars
        if letters.count > 10 && Double(uppercaseLetters.count) / Double(letters.count) > 0.7 {
            return true
        }
        
        return false
    }
    
    private func containsObfuscatedProfanity(_ text: String) -> Bool {
        // Common obfuscation patterns for profanity
        let obfuscatedPatterns = [
            "f\\*ck", "f\\*cking", "sh\\*t", "d\\*mn", "b\\*tch", "\\*sshole",
            "f.ck", "f.cking", "sh.t", "d.mn", "b.tch", ".sshole",
            "f-ck", "f-cking", "sh-t", "d-mn", "b-tch", "-sshole"
        ]
        
        for pattern in obfuscatedPatterns {
            if text.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil {
                return true
            }
        }
        
        return false
    }
}

// MARK: - Validation Result

enum ContentFilterResult {
    case valid(String)
    case invalid(String)
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
    
    var value: String? {
        switch self {
        case .valid(let value):
            return value
        case .invalid:
            return nil
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

// MARK: - Content Filter Extensions

extension ContentFilter {
    /// Quick validation for form fields
    func validateField(_ text: String, type: FieldType) -> ContentFilterResult {
        switch type {
        case .destination:
            return validateDestination(text)
        case .message:
            return validateUserMessage(text)
        case .budget:
            return validateBudget(text)
        case .name:
            return validateName(text)
        }
    }
    
    enum FieldType {
        case destination
        case message
        case budget
        case name
    }
}