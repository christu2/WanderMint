import SwiftUI
import MapKit

struct LocationAutocompleteField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @Binding var selectedLocation: LocationResult?
    
    @State private var searchResults: [LocationResult] = []
    @State private var showingResults = false
    @State private var searchCompleter = MKLocalSearchCompleter()
    @State private var searchDelegate: SearchCompleterDelegate?
    @State private var isSearching = false
    @State private var isSettingTextProgrammatically = false
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            Text(title)
                .font(AppTheme.Typography.bodySmall)
                .foregroundColor(AppTheme.Colors.textSecondary)
            
            VStack(spacing: 0) {
                HStack {
                    TextField(placeholder, text: $text)
                        .textInputAutocapitalization(.words)
                        .focused($isTextFieldFocused)
                        .onChange(of: text) { newValue in
                            // Don't trigger search if we're setting text programmatically
                            guard !isSettingTextProgrammatically else {
                                return
                            }
                            
                            if !newValue.isEmpty && newValue.count >= 2 {
                                // Show immediate fallback suggestions
                                let immediateFallback = self.getFallbackSuggestions(for: newValue)
                                self.searchResults = immediateFallback
                                showingResults = true
                                
                                // Also try MapKit in parallel
                                searchCompleter.queryFragment = newValue
                                isSearching = true
                                
                                // Stop searching after 1 second if MapKit doesn't respond
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    if self.isSearching {
                                        self.isSearching = false
                                    }
                                }
                            } else {
                                showingResults = false
                                searchResults = []
                                isSearching = false
                            }
                        }
                        .onSubmit {
                            if let firstResult = searchResults.first {
                                selectLocation(firstResult)
                            } else {
                                // Allow user to keep what they typed even without autocomplete
                                acceptTypedText()
                            }
                        }
                    
                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
                .padding(AppTheme.Spacing.md)
                .background(Color.white)
                .cornerRadius(AppTheme.CornerRadius.md)
                .applyShadow(Shadow(color: AppTheme.Shadows.light, radius: 2, x: 0, y: 1))
                
                if showingResults && (!searchResults.isEmpty || !text.isEmpty) {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            // Show search results first
                            ForEach(searchResults.prefix(6), id: \.id) { result in
                                LocationSuggestionRow(result: result) {
                                    selectLocation(result)
                                }
                                
                                Divider()
                                    .padding(.horizontal, AppTheme.Spacing.md)
                            }
                            
                            // Always show "Use what you typed" option
                            if !text.isEmpty {
                                UseTypedTextRow(text: text, action: acceptTypedText)
                            }
                        }
                    }
                    .frame(maxHeight: 320)
                    .background(Color.white)
                    .cornerRadius(AppTheme.CornerRadius.md)
                    .applyShadow(Shadow(color: AppTheme.Shadows.light, radius: 2, x: 0, y: 1))
                } else if showingResults && searchResults.isEmpty && !isSearching && !text.isEmpty {
                    // Show option to keep typed text when no results found
                    VStack(spacing: AppTheme.Spacing.xs) {
                        Button(action: acceptTypedText) {
                            HStack(spacing: AppTheme.Spacing.sm) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppTheme.Colors.textSecondary)
                                    .frame(width: 20)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Use \"\(text)\"")
                                        .font(AppTheme.Typography.body)
                                        .foregroundColor(AppTheme.Colors.textPrimary)
                                        .lineLimit(1)
                                    
                                    Text("Tap to use this destination")
                                        .font(AppTheme.Typography.bodySmall)
                                        .foregroundColor(AppTheme.Colors.textSecondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "arrow.up.left")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppTheme.Colors.textTertiary)
                            }
                            .padding(.horizontal, AppTheme.Spacing.md)
                            .padding(.vertical, AppTheme.Spacing.sm)
                            .background(Color.white)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .background(Color.white)
                    .cornerRadius(AppTheme.CornerRadius.md)
                    .applyShadow(Shadow(color: AppTheme.Shadows.light, radius: 2, x: 0, y: 1))
                }
            }
        }
        .onAppear {
            setupSearchCompleter()
        }
        .onChange(of: isTextFieldFocused) { focused in
            if !focused {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showingResults = false
                }
            }
        }
    }
    
    private func setupSearchCompleter() {
        // Create and retain the delegate
        searchDelegate = SearchCompleterDelegate(
            onResults: { results in
                DispatchQueue.main.async {
                    if !results.isEmpty {
                        // Filter and prioritize travel-related results
                        let travelResults = self.filterAndRankTravelResults(results)
                        self.searchResults = travelResults
                    }
                    self.isSearching = false
                }
            },
            onError: { error in
                DispatchQueue.main.async {
                    self.isSearching = false
                }
            },
            onSearchStart: {
                // MapKit search started - no action needed
            }
        )
        
        // Create a new instance and set the retained delegate
        searchCompleter = MKLocalSearchCompleter()
        searchCompleter.delegate = searchDelegate
        
        // Configure for travel destinations only
        searchCompleter.filterType = .locationsOnly
        searchCompleter.resultTypes = [.address] // Focus on places, not businesses
    }
    
    private func filterAndRankTravelResults(_ results: [LocationResult]) -> [LocationResult] {
        // Filter to only high-level destinations
        let destinationResults = results.filter { result in
            let title = result.title.lowercased()
            let subtitle = result.subtitle.lowercased()
            let fullText = "\(title) \(subtitle)"
            
            // EXCLUDE: Streets, neighborhoods, specific locations within cities
            let excludeKeywords = [
                "street", "st", "avenue", "ave", "road", "rd", "boulevard", "blvd", "drive", "dr",
                "lane", "ln", "way", "place", "pl", "court", "ct", "circle", "cir",
                "loop", "river", "creek", "bridge", "highway", "freeway", "expressway",
                "neighborhood", "district", "quarter", "area", "center", "centre",
                "mall", "plaza", "square", "park", "airport", "station", "terminal",
                "north", "south", "east", "west", "upper", "lower", "downtown", "midtown",
                "little", "old", "new", "greater", "metro", "village", "heights", "hills",
                "chinatown", "koreatown", "japantown", "germantown", "french quarter",
                "lake", "mountain", "capitol", "building", "museum", "university", "college"
            ]
            
            // Exclude if title contains street/location indicators
            for keyword in excludeKeywords {
                if title.contains(keyword) {
                    return false
                }
            }
            
            // Exclude if title contains numbers (likely addresses or specific locations)
            if title.contains(where: { $0.isNumber }) {
                return false
            }
            
            // Exclude neighborhood patterns - if subtitle contains multiple cities/locations
            // (like "Little Italy, Chicago, IL" - the subtitle has a city name)
            let subtitleParts = subtitle.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            if subtitleParts.count >= 2 {
                // If the first part of subtitle is a city name, this is likely a neighborhood
                let potentialCityName = subtitleParts[0].lowercased()
                if potentialCityName.count > 3 && !potentialCityName.contains("county") && !potentialCityName.contains("province") {
                    // Check if this looks like a major city (has multiple words or is well-known)
                    let cityWords = potentialCityName.components(separatedBy: " ")
                    if cityWords.count <= 3 && potentialCityName.count <= 20 {
                        return false
                    }
                }
            }
            
            // INCLUDE: Only results that are clearly destinations
            
            // Priority 1: Well-known destinations (countries, major cities)
            let isWellKnownPlace = result.isWellKnownDestination(result.title)
            
            // Priority 2: Simple state/country names (like "Kentucky" or "California")
            let isSimpleStateName = subtitle.isEmpty || 
                                   (subtitle.contains("united states") && !subtitle.contains(",")) ||
                                   (subtitle.contains("usa") && !subtitle.contains(","))
            
            // Priority 3: Clean city, state format (like "Louisville, Kentucky" not "Kentucky St, Louisville")
            let hasCleanCityStateFormat = subtitle.contains(",") && 
                                         !title.contains(" ") && // Single word cities only for now
                                         title.count <= 20 &&
                                         subtitle.count < 50
            
            // Must be a clean place name (no special characters, reasonable length)
            let isCleanPlaceName = title.count <= 30 && 
                                  !title.contains("&") && 
                                  !title.contains("/") &&
                                  !title.contains("#") &&
                                  title.components(separatedBy: " ").count <= 2 // Max 2 words
            
            return (isWellKnownPlace || isSimpleStateName || hasCleanCityStateFormat) && isCleanPlaceName
        }
        
        // Keywords that boost city/region ranking
        let destinationKeywords = [
            "city", "capital", "state", "province", "country", "region", "territory", "county"
        ]
        
        let rankedResults = destinationResults.map { result -> (LocationResult, Int) in
            var score = 0
            let fullText = "\(result.title) \(result.subtitle)".lowercased()
            
            // Boost well-known destinations highest
            if result.isWellKnownDestination(result.title) {
                score += 20
            }
            
            // Boost results with proper geographic structure
            let commaCount = result.subtitle.filter { $0 == "," }.count
            if commaCount >= 1 {
                score += 15 // City, State or City, Country format
            }
            if commaCount >= 2 {
                score += 5  // City, State, Country format
            }
            
            // Boost results containing destination keywords
            for keyword in destinationKeywords {
                if fullText.contains(keyword) {
                    score += 10
                    break
                }
            }
            
            // Boost shorter, cleaner names (likely cities vs. neighborhoods)
            if result.title.count <= 15 {
                score += 5
            }
            
            // Slightly boost results with "state" or "province" in subtitle
            if result.subtitle.contains("state") || result.subtitle.contains("province") {
                score += 3
            }
            
            return (result, score)
        }
        
        // Sort by score (highest first) and return top results
        let finalResults = rankedResults
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
            .prefix(6) // Limit to top 6 since we're being more selective
            .compactMap { $0 }
        
        return Array(finalResults)
    }
    
    private func selectLocation(_ location: LocationResult) {
        isSettingTextProgrammatically = true
        text = location.displayName
        selectedLocation = location
        showingResults = false
        isSearching = false
        isTextFieldFocused = false
        
        // Reset the flag after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isSettingTextProgrammatically = false
        }
        
        // Dismiss keyboard
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
    
    private func acceptTypedText() {
        // Create a manual LocationResult from the typed text
        selectedLocation = LocationResult(
            title: text,
            subtitle: "",
            coordinate: nil
        )
        showingResults = false
        isSearching = false
        isTextFieldFocused = false
        
        // Dismiss keyboard
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
    
    private func getFallbackSuggestions(for query: String) -> [LocationResult] {
        let queryLower = query.lowercased()
        
        // Popular travel destinations that match the query
        let popularDestinations = [
            ("Paris", "France"),
            ("London", "United Kingdom"),
            ("Tokyo", "Japan"),
            ("New York", "New York, USA"),
            ("Rome", "Italy"),
            ("Barcelona", "Spain"),
            ("Amsterdam", "Netherlands"),
            ("Sydney", "Australia"),
            ("Dubai", "United Arab Emirates"),
            ("Singapore", "Singapore"),
            ("Bangkok", "Thailand"),
            ("Istanbul", "Turkey"),
            ("Berlin", "Germany"),
            ("Vienna", "Austria"),
            ("Prague", "Czech Republic"),
            ("Budapest", "Hungary"),
            ("Florence", "Italy"),
            ("Venice", "Italy"),
            ("Santorini", "Greece"),
            ("Bali", "Indonesia"),
            ("Hawaii", "USA"),
            ("Miami", "Florida, USA"),
            ("Las Vegas", "Nevada, USA"),
            ("San Francisco", "California, USA"),
            ("Los Angeles", "California, USA"),
            ("Chicago", "Illinois, USA"),
            ("Boston", "Massachusetts, USA"),
            ("Washington", "DC, USA"),
            ("Orlando", "Florida, USA"),
            ("Cancun", "Mexico"),
            ("Costa Rica", "Costa Rica"),
            ("Iceland", "Iceland"),
            ("Norway", "Norway"),
            ("Switzerland", "Switzerland"),
            ("Ireland", "Ireland"),
            ("Scotland", "United Kingdom"),
            ("Portugal", "Portugal"),
            ("Morocco", "Morocco"),
            ("Egypt", "Egypt"),
            ("India", "India"),
            ("China", "China"),
            ("Australia", "Australia"),
            ("New Zealand", "New Zealand"),
            ("Brazil", "Brazil"),
            ("Argentina", "Argentina"),
            ("Chile", "Chile"),
            ("Peru", "Peru"),
            ("Canada", "Canada"),
            ("Montana", "USA"),
            ("Montana", "Montana, USA"),
            ("Montreal", "Quebec, Canada"),
            ("Monaco", "Monaco"),
            ("Morocco", "Morocco"),
            ("Moscow", "Russia"),
            ("Monterey", "California, USA")
        ]
        
        let matchingDestinations = popularDestinations.filter { destination in
            destination.0.lowercased().hasPrefix(queryLower) ||
            destination.0.lowercased().contains(queryLower)
        }
        
        return matchingDestinations.prefix(5).map { destination in
            LocationResult(
                title: destination.0,
                subtitle: destination.1,
                coordinate: nil
            )
        }
    }
}

// MARK: - Use Typed Text Row
struct UseTypedTextRow: View {
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: "text.cursor")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.Colors.textSecondary)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Use \"\(text)\"")
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(1)
                    
                    Text("Use this as your destination")
                        .font(AppTheme.Typography.bodySmall)
                        .foregroundColor(AppTheme.Colors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.left")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(AppTheme.Colors.backgroundSecondary.opacity(0.5))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Location Suggestion Row
struct LocationSuggestionRow: View {
    let result: LocationResult
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.Spacing.sm) {
                Image(systemName: result.iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(result.iconColor)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.title)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(AppTheme.Colors.textPrimary)
                        .lineLimit(1)
                    
                    if !result.subtitle.isEmpty {
                        Text(result.subtitle)
                            .font(AppTheme.Typography.bodySmall)
                            .foregroundColor(AppTheme.Colors.textSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.left")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.Colors.textTertiary)
            }
            .padding(.horizontal, AppTheme.Spacing.md)
            .padding(.vertical, AppTheme.Spacing.sm)
            .background(Color.white)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            action()
        }
    }
}

// MARK: - Location Result Model
struct LocationResult: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D?
    
    var displayName: String {
        if subtitle.isEmpty {
            return title
        }
        return "\(title), \(subtitle)"
    }
    
    var isCity: Bool {
        // Enhanced heuristic for cities
        let titleLower = title.lowercased()
        let subtitleLower = subtitle.lowercased()
        
        // Known city indicators
        let cityIndicators = ["city", "town", "village", "capital"]
        let hasIndicator = cityIndicators.contains { titleLower.contains($0) || subtitleLower.contains($0) }
        
        // Geographic structure (City, State/Province, Country)
        let hasGeoStructure = subtitle.contains(",") && subtitle.count > 5
        
        // Major cities often have shorter, cleaner names
        let isShortCleanName = title.count < 25 && !title.contains(where: { $0.isNumber })
        
        return hasIndicator || (hasGeoStructure && isShortCleanName)
    }
    
    var isMajorDestination: Bool {
        let titleLower = title.lowercased()
        let subtitleLower = subtitle.lowercased()
        let fullText = "\(titleLower) \(subtitleLower)"
        
        // Major destination indicators
        let majorDestinationKeywords = [
            "international", "national", "airport", "beach", "mountain",
            "island", "park", "museum", "historic", "famous", "popular",
            "tourist", "attraction", "landmark", "world heritage", "coast",
            "valley", "canyon", "desert", "capital", "metropolitan"
        ]
        
        return majorDestinationKeywords.contains { fullText.contains($0) } ||
               isWellKnownDestination(title)
    }
    
    func isWellKnownDestination(_ destination: String) -> Bool {
        // List of well-known travel destinations
        let majorDestinations = [
            "paris", "london", "tokyo", "new york", "rome", "barcelona", "amsterdam",
            "sydney", "dubai", "singapore", "hong kong", "bangkok", "istanbul",
            "berlin", "vienna", "prague", "budapest", "florence", "venice",
            "santorini", "mykonos", "bali", "maldives", "hawaii", "miami",
            "las vegas", "san francisco", "los angeles", "chicago", "boston",
            "washington", "orlando", "cancun", "cabo", "costa rica", "iceland",
            "norway", "sweden", "switzerland", "austria", "ireland", "scotland",
            "portugal", "morocco", "egypt", "south africa", "kenya", "tanzania",
            "india", "nepal", "tibet", "china", "japan", "south korea",
            "vietnam", "cambodia", "laos", "myanmar", "philippines", "indonesia",
            "australia", "new zealand", "fiji", "tahiti", "brazil", "argentina",
            "chile", "peru", "colombia", "ecuador", "mexico", "canada"
        ]
        
        let destinationLower = destination.lowercased()
        return majorDestinations.contains { destinationLower.contains($0) }
    }
    
    var iconName: String {
        let fullText = "\(title) \(subtitle)".lowercased()
        
        if fullText.contains("airport") {
            return "airplane"
        } else if fullText.contains("beach") || fullText.contains("island") || fullText.contains("coast") {
            return "sun.max.fill"
        } else if fullText.contains("mountain") || fullText.contains("ski") || fullText.contains("valley") {
            return "mountain.2.fill"
        } else if fullText.contains("museum") || fullText.contains("historic") {
            return "building.columns.fill"
        } else if fullText.contains("park") || fullText.contains("national") {
            return "leaf.fill"
        } else if fullText.contains("desert") {
            return "sun.dust.fill"
        } else if fullText.contains("lake") || fullText.contains("river") {
            return "drop.fill"
        } else if isCity || isMajorDestination {
            return "building.2.fill"
        } else {
            return "location.fill"
        }
    }
    
    var iconColor: Color {
        let fullText = "\(title) \(subtitle)".lowercased()
        
        if fullText.contains("airport") {
            return AppTheme.Colors.info
        } else if fullText.contains("beach") || fullText.contains("island") || fullText.contains("coast") {
            return AppTheme.Colors.secondary
        } else if fullText.contains("mountain") || fullText.contains("valley") {
            return Color.gray
        } else if fullText.contains("museum") || fullText.contains("historic") {
            return Color.brown
        } else if fullText.contains("park") || fullText.contains("national") {
            return Color.green
        } else if fullText.contains("desert") {
            return Color.orange
        } else if fullText.contains("lake") || fullText.contains("river") {
            return Color.blue
        } else if isMajorDestination {
            return AppTheme.Colors.primary
        } else {
            return AppTheme.Colors.textSecondary
        }
    }
    
    static func == (lhs: LocationResult, rhs: LocationResult) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Search Completer Delegate
class SearchCompleterDelegate: NSObject, MKLocalSearchCompleterDelegate {
    private let onResults: ([LocationResult]) -> Void
    private let onError: (Error) -> Void
    private let onSearchStart: () -> Void
    
    init(
        onResults: @escaping ([LocationResult]) -> Void,
        onError: @escaping (Error) -> Void,
        onSearchStart: @escaping () -> Void
    ) {
        self.onResults = onResults
        self.onError = onError
        self.onSearchStart = onSearchStart
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results.map { completion in
            LocationResult(
                title: completion.title,
                subtitle: completion.subtitle,
                coordinate: nil // We could geocode this if needed
            )
        }
        onResults(results)
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        onError(error)
    }
}

