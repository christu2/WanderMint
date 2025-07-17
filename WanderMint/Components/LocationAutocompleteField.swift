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
                                // PRIMARY: Use curated city database first
                                let curatedResults = self.getCuratedCitySuggestions(for: newValue)
                                
                                if curatedResults.count >= 1 {
                                    // If we have ANY curated results, use them as primary
                                    self.searchResults = curatedResults
                                    showingResults = true
                                    
                                    // Don't use MapKit at all - curated results are better
                                    isSearching = false
                                } else {
                                    // Only use MapKit if no curated results found
                                    let immediateFallback = self.getFallbackSuggestions(for: newValue)
                                    self.searchResults = immediateFallback
                                    showingResults = true
                                    
                                    // Try MapKit as fallback
                                    searchCompleter.queryFragment = newValue
                                    isSearching = true
                                    
                                    // Stop searching after 1 second if MapKit doesn't respond
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        if self.isSearching {
                                            self.isSearching = false
                                        }
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
                
                if showingResults && !searchResults.isEmpty {
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
                            
                            // Show "Use what you typed" option only when we have results
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
        searchCompleter.resultTypes = [.address] // Back to address for better city results
        searchCompleter.region = MKCoordinateRegion(.world) // Global search
        
        // Exclude all POIs to focus on places/cities
        if #available(iOS 13.0, *) {
            searchCompleter.pointOfInterestFilter = MKPointOfInterestFilter.excludingAll
        }
    }
    
    private func filterAndRankTravelResults(_ results: [LocationResult]) -> [LocationResult] {
        // Aggressive filtering to remove streets, avenues, and unwanted results
        let destinationResults = results.filter { result in
            let title = result.title.lowercased()
            let subtitle = result.subtitle.lowercased()
            
            // Exclude results with numbers (addresses)
            if title.contains(where: { $0.isNumber }) || subtitle.contains(where: { $0.isNumber }) {
                return false
            }
            
            // Exclude street endings
            let streetEndings = ["st", "ave", "rd", "dr", "ln", "blvd", "street", "avenue", "road", "drive", "lane", "boulevard", "way", "place", "court", "circle"]
            for ending in streetEndings {
                if title.hasSuffix(" \(ending)") || title == ending {
                    return false
                }
            }
            
            // Exclude street keywords anywhere in title
            let streetKeywords = [" st ", " ave ", " street ", " avenue ", " road ", " rd ", " drive ", " dr ", " lane ", " ln ", " boulevard ", " blvd ", " way ", " place ", " court ", " circle "]
            for keyword in streetKeywords {
                if title.contains(keyword) {
                    return false
                }
            }
            
            // Exclude transit and infrastructure
            let transitKeywords = ["airport", "station", "terminal", "depot", "stop", "platform", "rail", "train", "metro", "subway", "bus", "mall", "plaza", "shopping", "center", "centre"]
            for keyword in transitKeywords {
                if title.contains(keyword) || subtitle.contains(keyword) {
                    return false
                }
            }
            
            // Exclude "Nearby" results (POIs)
            if subtitle.contains("nearby") || subtitle.contains("search nearby") {
                return false
            }
            
            // Exclude business/building indicators
            let businessKeywords = ["&", "/", "#", "llc", "inc", "corp", "ltd", "co.", "building", "tower", "complex"]
            for keyword in businessKeywords {
                if title.contains(keyword) || subtitle.contains(keyword) {
                    return false
                }
            }
            
            // Must have proper geographic format (comma or non-empty subtitle)
            let hasProperFormat = result.title.contains(",") || !result.subtitle.isEmpty
            
            // Basic validation
            let validLength = title.count >= 2 && title.count <= 50
            
            return hasProperFormat && validLength
        }
        
        let rankedResults = destinationResults.map { result -> (LocationResult, Int) in
            var score = 0
            let title = result.title.lowercased()
            let subtitle = result.subtitle.lowercased()
            
            // MASSIVE BOOST: Exact major city names
            let majorCities = ["chicago", "new york", "los angeles", "san francisco", "boston", "miami", "seattle", 
                             "paris", "london", "tokyo", "rome", "madrid", "berlin", "sydney", "toronto", 
                             "shanghai", "hong kong", "barcelona", "amsterdam", "vienna", "prague"]
            if majorCities.contains(title) {
                score += 100
            }
            
            // BOOST: Well-known destinations
            if result.isWellKnownDestination(result.title) {
                score += 50
            }
            
            // BOOST: International destinations
            let isInternational = !subtitle.contains("united states") && !subtitle.contains("usa")
            if isInternational {
                score += 30
            }
            
            // BOOST: Proper geographic structure (has commas)
            let commaCount = result.title.filter { $0 == "," }.count + result.subtitle.filter { $0 == "," }.count
            score += commaCount * 10
            
            // PENALTY: Long names (likely not major cities)
            if result.title.count > 20 {
                score -= 10
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
    
    private func getCuratedCitySuggestions(for query: String) -> [LocationResult] {
        let queryLower = query.lowercased()
        
        // Comprehensive database of countries, major cities, and regions worldwide
        let destinationsDatabase = [
            // Countries (highest priority)
            ("United States", "North America"),
            ("Canada", "North America"),
            ("Mexico", "North America"),
            ("United Kingdom", "Europe"),
            ("France", "Europe"),
            ("Italy", "Europe"),
            ("Spain", "Europe"),
            ("Germany", "Europe"),
            ("Greece", "Europe"),
            ("Netherlands", "Europe"),
            ("Switzerland", "Europe"),
            ("Austria", "Europe"),
            ("Portugal", "Europe"),
            ("Ireland", "Europe"),
            ("Sweden", "Europe"),
            ("Norway", "Europe"),
            ("Denmark", "Europe"),
            ("Finland", "Europe"),
            ("Belgium", "Europe"),
            ("Czech Republic", "Europe"),
            ("Hungary", "Europe"),
            ("Poland", "Europe"),
            ("Russia", "Europe/Asia"),
            ("Turkey", "Europe/Asia"),
            ("China", "Asia"),
            ("Japan", "Asia"),
            ("South Korea", "Asia"),
            ("Thailand", "Thailand"),
            ("Singapore", "Asia"),
            ("India", "Asia"),
            ("Indonesia", "Asia"),
            ("Malaysia", "Asia"),
            ("Philippines", "Asia"),
            ("Vietnam", "Asia"),
            ("Australia", "Oceania"),
            ("New Zealand", "Oceania"),
            ("Brazil", "South America"),
            ("Argentina", "South America"),
            ("Chile", "South America"),
            ("Peru", "South America"),
            ("Colombia", "South America"),
            ("Ecuador", "South America"),
            ("Egypt", "Africa"),
            ("South Africa", "Africa"),
            ("Morocco", "Africa"),
            ("Kenya", "Africa"),
            ("Tanzania", "Africa"),
            
            // US States
            ("Alabama", "United States"),
            ("Alaska", "United States"),
            ("Arizona", "United States"),
            ("Arkansas", "United States"),
            ("California", "United States"),
            ("Colorado", "United States"),
            ("Connecticut", "United States"),
            ("Delaware", "United States"),
            ("Florida", "United States"),
            ("Georgia", "United States"),
            ("Hawaii", "United States"),
            ("Idaho", "United States"),
            ("Illinois", "United States"),
            ("Indiana", "United States"),
            ("Iowa", "United States"),
            ("Kansas", "United States"),
            ("Kentucky", "United States"),
            ("Louisiana", "United States"),
            ("Maine", "United States"),
            ("Maryland", "United States"),
            ("Massachusetts", "United States"),
            ("Michigan", "United States"),
            ("Minnesota", "United States"),
            ("Mississippi", "United States"),
            ("Missouri", "United States"),
            ("Montana", "United States"),
            ("Nebraska", "United States"),
            ("Nevada", "United States"),
            ("New Hampshire", "United States"),
            ("New Jersey", "United States"),
            ("New Mexico", "United States"),
            ("New York", "United States"),
            ("North Carolina", "United States"),
            ("North Dakota", "United States"),
            ("Ohio", "United States"),
            ("Oklahoma", "United States"),
            ("Oregon", "United States"),
            ("Pennsylvania", "United States"),
            ("Rhode Island", "United States"),
            ("South Carolina", "United States"),
            ("South Dakota", "United States"),
            ("Tennessee", "United States"),
            ("Texas", "United States"),
            ("Utah", "United States"),
            ("Vermont", "United States"),
            ("Virginia", "United States"),
            ("Washington", "United States"),
            ("West Virginia", "United States"),
            ("Wisconsin", "United States"),
            ("Wyoming", "United States"),
            
            // Canadian Provinces and Territories
            ("Alberta", "Canada"),
            ("British Columbia", "Canada"),
            ("Manitoba", "Canada"),
            ("New Brunswick", "Canada"),
            ("Newfoundland and Labrador", "Canada"),
            ("Northwest Territories", "Canada"),
            ("Nova Scotia", "Canada"),
            ("Nunavut", "Canada"),
            ("Ontario", "Canada"),
            ("Prince Edward Island", "Canada"),
            ("Quebec", "Canada"),
            ("Saskatchewan", "Canada"),
            ("Yukon", "Canada"),
            
            // Major Cities - North America
            ("Chicago", "Illinois, United States"),
            ("New York", "New York, United States"),
            ("Los Angeles", "California, United States"),
            ("San Francisco", "California, United States"),
            ("Boston", "Massachusetts, United States"),
            ("Miami", "Florida, United States"),
            ("Seattle", "Washington, United States"),
            ("Las Vegas", "Nevada, United States"),
            ("Washington", "District of Columbia, United States"),
            ("Toronto", "Ontario, Canada"),
            ("Vancouver", "British Columbia, Canada"),
            ("Montreal", "Quebec, Canada"),
            ("Mexico City", "Mexico"),
            
            // Major Cities - Europe
            ("London", "United Kingdom"),
            ("Paris", "France"),
            ("Rome", "Italy"),
            ("Barcelona", "Spain"),
            ("Madrid", "Spain"),
            ("Amsterdam", "Netherlands"),
            ("Berlin", "Germany"),
            ("Vienna", "Austria"),
            ("Prague", "Czech Republic"),
            ("Budapest", "Hungary"),
            ("Athens", "Greece"),
            ("Florence", "Italy"),
            ("Venice", "Italy"),
            ("Milan", "Italy"),
            ("Naples", "Italy"),
            ("Lisbon", "Portugal"),
            ("Dublin", "Ireland"),
            ("Edinburgh", "Scotland, United Kingdom"),
            ("Stockholm", "Sweden"),
            ("Copenhagen", "Denmark"),
            ("Oslo", "Norway"),
            ("Helsinki", "Finland"),
            ("Zurich", "Switzerland"),
            ("Geneva", "Switzerland"),
            ("Brussels", "Belgium"),
            ("Moscow", "Russia"),
            ("St Petersburg", "Russia"),
            
            // Major Cities - Asia
            ("Tokyo", "Japan"),
            ("Kyoto", "Japan"),
            ("Osaka", "Japan"),
            ("Hong Kong", "Hong Kong"),
            ("Shanghai", "China"),
            ("Beijing", "China"),
            ("Seoul", "South Korea"),
            ("Bangkok", "Thailand"),
            ("Singapore", "Singapore"),
            ("Mumbai", "India"),
            ("Delhi", "India"),
            ("Istanbul", "Turkey"),
            ("Dubai", "United Arab Emirates"),
            ("Kuala Lumpur", "Malaysia"),
            ("Manila", "Philippines"),
            ("Ho Chi Minh City", "Vietnam"),
            ("Hanoi", "Vietnam"),
            
            // Major Cities - Oceania
            ("Sydney", "Australia"),
            ("Melbourne", "Australia"),
            ("Brisbane", "Australia"),
            ("Perth", "Australia"),
            ("Auckland", "New Zealand"),
            ("Wellington", "New Zealand"),
            
            // Major Cities - South America
            ("Buenos Aires", "Argentina"),
            ("Rio de Janeiro", "Brazil"),
            ("São Paulo", "Brazil"),
            ("Lima", "Peru"),
            ("Santiago", "Chile"),
            ("Bogotá", "Colombia"),
            ("Quito", "Ecuador"),
            
            // Major Cities - Africa
            ("Cairo", "Egypt"),
            ("Cape Town", "South Africa"),
            ("Johannesburg", "South Africa"),
            ("Marrakech", "Morocco"),
            ("Casablanca", "Morocco"),
            ("Nairobi", "Kenya"),
            ("Dar es Salaam", "Tanzania")
        ]
        
        // Filter destinations that match the query
        let matchingDestinations = destinationsDatabase.filter { destination in
            destination.0.lowercased().hasPrefix(queryLower) ||
            destination.0.lowercased().contains(queryLower)
        }
        
        // Convert to LocationResult and sort by relevance
        return matchingDestinations
            .sorted { first, second in
                let firstExactMatch = first.0.lowercased().hasPrefix(queryLower)
                let secondExactMatch = second.0.lowercased().hasPrefix(queryLower)
                
                // Prioritize countries and states (they have region-style subtitles)
                let countryRegions = ["Europe", "Asia", "North America", "South America", "Africa", "Oceania", "Europe/Asia"]
                let stateCountries = ["United States", "Canada"]
                
                let firstIsCountryOrState = countryRegions.contains(first.1) || stateCountries.contains(first.1)
                let secondIsCountryOrState = countryRegions.contains(second.1) || stateCountries.contains(second.1)
                
                if firstIsCountryOrState && !secondIsCountryOrState {
                    return true
                } else if !firstIsCountryOrState && secondIsCountryOrState {
                    return false
                } else if firstExactMatch && !secondExactMatch {
                    return true
                } else if !firstExactMatch && secondExactMatch {
                    return false
                } else {
                    // Both are same type - sort by name length (shorter = more important)
                    return first.0.count < second.0.count
                }
            }
            .prefix(6)
            .map { destination in
                LocationResult(
                    title: destination.0,
                    subtitle: destination.1,
                    coordinate: nil
                )
            }
    }
    
    private func getFallbackSuggestions(for query: String) -> [LocationResult] {
        let queryLower = query.lowercased()
        
        // Popular travel destinations that match the query
        // Prioritized with international destinations first
        let popularDestinations = [
            // Major European destinations (international priority)
            ("Paris", "France"),
            ("London", "United Kingdom"),
            ("Rome", "Italy"),
            ("Athens", "Greece"),
            ("Barcelona", "Spain"),
            ("Amsterdam", "Netherlands"),
            ("Berlin", "Germany"),
            ("Vienna", "Austria"),
            ("Prague", "Czech Republic"),
            ("Budapest", "Hungary"),
            ("Florence", "Italy"),
            ("Venice", "Italy"),
            ("Santorini", "Greece"),
            ("Madrid", "Spain"),
            ("Lisbon", "Portugal"),
            ("Dublin", "Ireland"),
            ("Edinburgh", "Scotland, United Kingdom"),
            ("Stockholm", "Sweden"),
            ("Copenhagen", "Denmark"),
            ("Oslo", "Norway"),
            ("Helsinki", "Finland"),
            ("Reykjavik", "Iceland"),
            ("Zurich", "Switzerland"),
            ("Geneva", "Switzerland"),
            ("Brussels", "Belgium"),
            ("Warsaw", "Poland"),
            ("Krakow", "Poland"),
            ("Moscow", "Russia"),
            ("St Petersburg", "Russia"),
            
            // Major Asian destinations (international priority)
            ("Tokyo", "Japan"),
            ("Kyoto", "Japan"),
            ("Bangkok", "Thailand"),
            ("Singapore", "Singapore"),
            ("Hong Kong", "Hong Kong"),
            ("Seoul", "South Korea"),
            ("Beijing", "China"),
            ("Shanghai", "China"),
            ("Mumbai", "India"),
            ("Delhi", "India"),
            ("Istanbul", "Turkey"),
            ("Dubai", "United Arab Emirates"),
            ("Bali", "Indonesia"),
            ("Kuala Lumpur", "Malaysia"),
            ("Manila", "Philippines"),
            ("Ho Chi Minh City", "Vietnam"),
            ("Hanoi", "Vietnam"),
            
            // Major destinations in Americas (international priority)
            ("Mexico City", "Mexico"),
            ("Cancun", "Mexico"),
            ("Lima", "Peru"),
            ("Cusco", "Peru"),
            ("Buenos Aires", "Argentina"),
            ("Rio de Janeiro", "Brazil"),
            ("Santiago", "Chile"),
            ("Bogota", "Colombia"),
            ("Montreal", "Quebec, Canada"),
            ("Toronto", "Ontario, Canada"),
            ("Vancouver", "British Columbia, Canada"),
            
            // Major African destinations (international priority)
            ("Cairo", "Egypt"),
            ("Marrakech", "Morocco"),
            ("Cape Town", "South Africa"),
            ("Nairobi", "Kenya"),
            
            // Major Oceania destinations (international priority)
            ("Sydney", "Australia"),
            ("Melbourne", "Australia"),
            ("Auckland", "New Zealand"),
            
            // US destinations (lower priority)
            ("New York", "New York, USA"),
            ("Los Angeles", "California, USA"),
            ("San Francisco", "California, USA"),
            ("Chicago", "Illinois, USA"),
            ("Miami", "Florida, USA"),
            ("Las Vegas", "Nevada, USA"),
            ("Boston", "Massachusetts, USA"),
            ("Washington", "DC, USA"),
            ("Orlando", "Florida, USA"),
            ("Seattle", "Washington, USA"),
            ("Hawaii", "USA"),
            
            // Countries and regions
            ("Costa Rica", "Costa Rica"),
            ("Iceland", "Iceland"),
            ("Norway", "Norway"),
            ("Switzerland", "Switzerland"),
            ("Ireland", "Ireland"),
            ("Portugal", "Portugal"),
            ("Morocco", "Morocco"),
            ("Egypt", "Egypt"),
            ("Greece", "Greece"),
            ("Italy", "Italy"),
            ("France", "France"),
            ("Spain", "Spain"),
            ("Germany", "Germany"),
            ("Thailand", "Thailand"),
            ("India", "India"),
            ("China", "China"),
            ("Japan", "Japan"),
            ("Australia", "Australia"),
            ("New Zealand", "New Zealand"),
            ("Brazil", "Brazil"),
            ("Argentina", "Argentina"),
            ("Chile", "Chile"),
            ("Peru", "Peru"),
            ("Mexico", "Mexico"),
            ("Canada", "Canada")
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
            // Major European destinations
            "paris", "london", "rome", "barcelona", "amsterdam", "berlin", "vienna", 
            "prague", "budapest", "florence", "venice", "athens", "santorini", "mykonos",
            "madrid", "lisbon", "dublin", "edinburgh", "stockholm", "copenhagen",
            "oslo", "helsinki", "reykjavik", "zurich", "geneva", "brussels", "warsaw",
            "krakow", "moscow", "st petersburg", "dubrovnik", "split", "zagreb",
            
            // Major Asian destinations  
            "tokyo", "kyoto", "osaka", "beijing", "shanghai", "hong kong", "singapore",
            "bangkok", "phuket", "seoul", "busan", "mumbai", "delhi", "goa", "kathmandu",
            "istanbul", "cappadocia", "dubai", "abu dhabi", "doha", "kuwait city",
            "tehran", "bali", "jakarta", "kuala lumpur", "manila", "ho chi minh city",
            "hanoi", "phnom penh", "vientiane", "yangon", "colombo", "male",
            
            // Major destinations in Americas
            "new york", "los angeles", "san francisco", "chicago", "boston", "miami",
            "las vegas", "washington", "orlando", "seattle", "vancouver", "toronto",
            "montreal", "mexico city", "cancun", "cabo", "guadalajara", "lima", "cusco",
            "quito", "buenos aires", "rio de janeiro", "sao paulo", "santiago", "bogota",
            "caracas", "havana",
            
            // Major African destinations
            "cairo", "marrakech", "casablanca", "cape town", "johannesburg", "nairobi", 
            "dar es salaam", "addis ababa", "lagos", "accra", "tunis", "algiers",
            
            // Major Oceania destinations
            "sydney", "melbourne", "perth", "auckland", "wellington", "fiji", "tahiti",
            
            // Countries and regions
            "costa rica", "iceland", "norway", "sweden", "switzerland", "austria", 
            "ireland", "scotland", "portugal", "morocco", "egypt", "south africa", 
            "kenya", "tanzania", "india", "nepal", "tibet", "china", "japan", 
            "south korea", "vietnam", "cambodia", "laos", "myanmar", "philippines", 
            "indonesia", "australia", "new zealand", "brazil", "argentina", "chile", 
            "peru", "colombia", "ecuador", "mexico", "canada", "maldives", "hawaii",
            "greece", "italy", "france", "spain", "germany", "netherlands", "thailand"
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

