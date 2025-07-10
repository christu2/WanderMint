import SwiftUI

struct AdminLogisticsDetailView: View {
    let logistics: AdminLogistics
    let tripId: String
    let onBookingUpdate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Transport Segments
            if !logistics.transportSegments.isEmpty {
                AdminTransportSectionView(
                    transportSegments: logistics.transportSegments,
                    tripId: tripId,
                    onBookingUpdate: onBookingUpdate
                )
            }
            
            // Booking Deadlines
            if !logistics.bookingDeadlines.isEmpty {
                AdminBookingDeadlinesSectionView(deadlines: logistics.bookingDeadlines)
            }
            
            // General Instructions
            if !logistics.generalInstructions.isEmpty {
                AdminGeneralInstructionsView(instructions: logistics.generalInstructions)
            }
        }
    }
}

struct AdminTransportSectionView: View {
    let transportSegments: [AdminTransportSegment]
    let tripId: String
    let onBookingUpdate: () -> Void
    
    @State private var viewMode: TransportViewMode = .sequential
    
    enum TransportViewMode: String, CaseIterable {
        case sequential = "Sequential"
        case grouped = "By Booking"
        
        var icon: String {
            switch self {
            case .sequential: return "list.bullet"
            case .grouped: return "rectangle.3.group"
            }
        }
        
        var description: String {
            switch self {
            case .sequential: return "Show all segments in travel order"
            case .grouped: return "Group segments that should be booked together"
            }
        }
    }
    
    private var sortedSegments: [AdminTransportSegment] {
        transportSegments.sorted { segment1, segment2 in
            // Sort by display sequence if available, otherwise by date
            if let seq1 = segment1.displaySequence, let seq2 = segment2.displaySequence {
                return seq1 < seq2
            }
            return segment1.date < segment2.date
        }
    }
    
    private var groupedSegments: [String: [AdminTransportSegment]] {
        Dictionary(grouping: sortedSegments) { segment in
            // Only group segments that have the same bookingGroupId
            // Individual segments (no bookingGroupId) get their own group
            segment.bookingGroupId ?? "individual_\(segment.id)"
        }
    }
    
    // Separate round-trip groups from individual segments
    private var roundTripGroups: [String: [AdminTransportSegment]] {
        groupedSegments.filter { key, segments in
            !key.hasPrefix("individual_") && segments.count > 1
        }
    }
    
    private var individualSegments: [AdminTransportSegment] {
        groupedSegments.compactMap { key, segments in
            key.hasPrefix("individual_") ? segments.first : nil
        }.sorted { $0.displaySequence ?? 0 < $1.displaySequence ?? 0 }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Transportation")
                    .font(.headline)
                
                Spacer()
                
                // View mode toggle
                if transportSegments.count > 1 {
                    Picker("View Mode", selection: $viewMode) {
                        ForEach(TransportViewMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue)
                                .tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 200)
                }
            }
            
            switch viewMode {
            case .sequential:
                AdminSequentialTransportView(
                    segments: sortedSegments,
                    tripId: tripId,
                    onBookingUpdate: onBookingUpdate
                )
                
            case .grouped:
                AdminGroupedTransportView(
                    roundTripGroups: roundTripGroups,
                    individualSegments: individualSegments,
                    tripId: tripId,
                    onBookingUpdate: onBookingUpdate
                )
            }
        }
    }
}

struct AdminSequentialTransportView: View {
    let segments: [AdminTransportSegment]
    let tripId: String
    let onBookingUpdate: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                VStack(spacing: 8) {
                    // Travel flow indicator
                    if index > 0 {
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            
                            Image(systemName: "arrow.down")
                                .foregroundColor(.gray)
                                .font(.caption)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.horizontal, 40)
                    }
                    
                    AdminTransportSegmentView(
                        segment: segment,
                        tripId: tripId,
                        onBookingUpdate: onBookingUpdate
                    )
                }
            }
            
            // Trip summary
            if segments.count > 1 {
                AdminTravelSummaryView(segments: segments)
            }
        }
    }
}

struct AdminGroupedTransportView: View {
    let roundTripGroups: [String: [AdminTransportSegment]]
    let individualSegments: [AdminTransportSegment]
    let tripId: String
    let onBookingUpdate: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Show round-trip groups first
            ForEach(Array(roundTripGroups.keys.sorted()), id: \.self) { groupId in
                let segments = roundTripGroups[groupId] ?? []
                AdminBookingGroupView(
                    segments: segments,
                    groupId: groupId,
                    tripId: tripId,
                    onBookingUpdate: onBookingUpdate
                )
            }
            
            // Then show individual segments
            if !individualSegments.isEmpty {
                VStack(spacing: 16) {
                    // Section header for individual segments
                    if !roundTripGroups.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "airplane")
                                    .foregroundColor(.blue)
                                Text("Individual Segments")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                Spacer()
                                Text("Book separately")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Each segment can be booked independently")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    ForEach(individualSegments) { segment in
                        AdminTransportSegmentView(
                            segment: segment,
                            tripId: tripId,
                            onBookingUpdate: onBookingUpdate
                        )
                    }
                }
            }
        }
    }
}

struct AdminBookingGroupView: View {
    let segments: [AdminTransportSegment]
    let groupId: String
    let tripId: String
    let onBookingUpdate: () -> Void
    
    private var isRoundTrip: Bool {
        segments.contains { segment in
            segment.transportOptions.contains { $0.isRoundTrip == true }
        }
    }
    
    private var groupTitle: String {
        if isRoundTrip {
            return "Round Trip Booking"
        } else {
            return "Multi-Segment Booking"
        }
    }
    
    private var groupSubtitle: String {
        if isRoundTrip {
            return "Book outbound and return flights together for best rates"
        } else {
            return "Book these \(segments.count) segments together for best rates"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Group header
            HStack {
                Image(systemName: isRoundTrip ? "arrow.left.arrow.right.circle.fill" : "link.circle.fill")
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(groupTitle)
                        .font(.subheadline)
                        .bold()
                    
                    Text(groupSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Booking group indicator
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.caption)
                        Text("BOOK TOGETHER")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.purple)
                    
                    Text("Group ID: \(groupId)")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(8)
            
            // Segments in this booking group
            ForEach(segments.sorted(by: { $0.displaySequence ?? 0 < $1.displaySequence ?? 0 })) { segment in
                AdminTransportSegmentView(
                    segment: segment,
                    tripId: tripId,
                    onBookingUpdate: onBookingUpdate
                )
            }
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
}

struct AdminTravelSummaryView: View {
    let segments: [AdminTransportSegment]
    
    private var totalSegments: Int {
        segments.count
    }
    
    private var roundTripSegments: Int {
        segments.filter { segment in
            segment.transportOptions.contains { $0.isRoundTrip == true }
        }.count
    }
    
    private var estimatedTotalCost: Double {
        segments.compactMap { segment in
            // Use user selected option if available, otherwise fall back to highest priority
            let localSelection = UserDefaults.standard.string(forKey: "selected_transport_option_\(segment.id)")
            let selectedId = localSelection ?? segment.selectedOptionId
            
            if let id = selectedId {
                return segment.transportOptions.first { $0.id == id }?.cost.cashAmount
            } else {
                return segment.transportOptions.min(by: { $0.priority < $1.priority })?.cost.cashAmount
            }
        }.reduce(0, +)
    }
    
    private var estimatedTotalPoints: Int {
        segments.compactMap { segment in
            // Use user selected option if available, otherwise fall back to highest priority
            let localSelection = UserDefaults.standard.string(forKey: "selected_transport_option_\(segment.id)")
            let selectedId = localSelection ?? segment.selectedOptionId
            
            if let id = selectedId {
                return segment.transportOptions.first { $0.id == id }?.cost.pointsAmount
            } else {
                return segment.transportOptions.min(by: { $0.priority < $1.priority })?.cost.pointsAmount
            }
        }.reduce(0, +)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Travel Summary")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(totalSegments) flight segment\(totalSegments == 1 ? "" : "s")")
                        .font(.subheadline)
                    
                    if roundTripSegments > 0 {
                        Text("\(roundTripSegments) round-trip booking\(roundTripSegments == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.purple)
                    }
                }
                
                Spacer()
                
                if estimatedTotalCost > 0 || estimatedTotalPoints > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Estimated Total")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if estimatedTotalCost > 0 {
                            Text("$\(Int(estimatedTotalCost))")
                                .font(.headline)
                                .bold()
                        }
                        
                        if estimatedTotalPoints > 0 {
                            Text("\(estimatedTotalPoints) pts")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
    }
}

struct AdminTransportSegmentView: View {
    let segment: AdminTransportSegment
    let tripId: String
    let onBookingUpdate: () -> Void
    
    @State private var showAllOptions: Bool = true
    
    private var selectedOptionId: String? {
        // Check UserDefaults first, then fall back to data model
        UserDefaults.standard.string(forKey: "selected_transport_option_\(segment.id)") ?? segment.selectedOptionId
    }
    
    private var sortedOptions: [AdminTransportOption] {
        segment.transportOptions.sorted { option1, option2 in
            // Recommended selections first, then by priority
            if let rec1 = option1.recommendedSelection, let rec2 = option2.recommendedSelection {
                return rec1 && !rec2
            }
            if option1.recommendedSelection == true { return true }
            if option2.recommendedSelection == true { return false }
            return option1.priority < option2.priority
        }
    }
    
    private var displayedOptions: [AdminTransportOption] {
        if showAllOptions || selectedOptionId == nil {
            return sortedOptions
        } else {
            return sortedOptions.filter { $0.id == selectedOptionId }
        }
    }
    
    private var segmentTypeIcon: String {
        switch segment.segmentType?.lowercased() {
        case "outbound": return "airplane.departure"
        case "inbound": return "airplane.arrival"
        case "domestic": return "airplane"
        case "connecting": return "arrow.triangle.2.circlepath"
        default: return "airplane"
        }
    }
    
    private var segmentTypeColor: Color {
        switch segment.segmentType?.lowercased() {
        case "outbound": return .green
        case "inbound": return .orange
        case "domestic": return .blue
        case "connecting": return .purple
        default: return .blue
        }
    }
    
    private func transportModeIcon(for mode: String) -> String {
        switch mode.lowercased() {
        case "flight": return "airplane"
        case "train": return "tram"
        case "bus": return "bus"
        case "car": return "car"
        case "ferry": return "ferry"
        default: return "location"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Generic transport segment header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(segment.route)
                            .font(.headline)
                            .bold()
                        
                        if let segmentType = segment.segmentType {
                            Text(segmentType.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(segmentTypeColor.opacity(0.1))
                                .foregroundColor(segmentTypeColor)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(segment.date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Round-trip indicator
                    if segment.transportOptions.contains(where: { $0.isRoundTrip == true }) {
                        Image(systemName: "arrow.left.arrow.right")
                            .foregroundColor(.purple)
                            .font(.caption)
                    }
                    
                    // Transport modes available
                    let uniqueModes = Array(Set(segment.transportOptions.map { $0.transportType }))
                    ForEach(uniqueModes, id: \.self) { mode in
                        Image(systemName: transportModeIcon(for: mode))
                            .foregroundColor(segmentTypeColor)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding()
            .background(segmentTypeColor.opacity(0.1))
            .cornerRadius(8)
            
            // Options count
            if !segment.transportOptions.isEmpty {
                HStack {
                    Text("\(segment.transportOptions.count) option\(segment.transportOptions.count == 1 ? "" : "s") available")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            // Selection status
            if selectedOptionId != nil && !showAllOptions {
                HStack {
                    Text("1 option selected")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Button("Show All Options") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showAllOptions = true
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
            
            // Transport options
            if !segment.transportOptions.isEmpty {
                VStack(spacing: 8) {
                    ForEach(displayedOptions) { option in
                        AdminTransportOptionView(
                            option: option,
                            segment: segment,
                            isSelected: option.id == (selectedOptionId ?? segment.selectedOptionId),
                            isRecommended: option.recommendedSelection == true,
                            showSelection: segment.transportOptions.count > 1,
                            tripId: tripId,
                            onSelection: { optionId in
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    // Save selection to UserDefaults for persistence
                                    UserDefaults.standard.set(optionId, forKey: "selected_transport_option_\(segment.id)")
                                    showAllOptions = false
                                }
                                onBookingUpdate()
                            },
                            onBookingUpdate: onBookingUpdate
                        )
                    }
                }
            } else {
                Text("Transport options will be added soon")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .italic()
                    .padding()
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
        .onAppear {
            // Show all options initially if no selection has been made
            if selectedOptionId == nil {
                showAllOptions = true
            } else {
                // If we have a selection, hide other options
                showAllOptions = false
            }
        }
    }
}

struct AdminTransportOptionView: View {
    let option: AdminTransportOption
    let segment: AdminTransportSegment
    let isSelected: Bool
    let isRecommended: Bool
    let showSelection: Bool
    let tripId: String
    let onSelection: (String) -> Void
    let onBookingUpdate: () -> Void
    
    @State private var showingFlightDetails = false
    
    private var borderColor: Color {
        if isSelected { return .green }
        if isRecommended { return .blue }
        return .gray.opacity(0.3)
    }
    
    private var backgroundColor: Color {
        if isSelected { return .green.opacity(0.1) }
        if isRecommended { return .blue.opacity(0.05) }
        return .white
    }
    
    private func transportModeIcon(for mode: String) -> String {
        switch mode.lowercased() {
        case "flight": return "airplane"
        case "train": return "tram"
        case "bus": return "bus"
        case "car": return "car"
        case "ferry": return "ferry"
        default: return "location"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Transport option header with selection
            HStack {
                if showSelection {
                    Button(action: {
                        onSelection(option.id)
                    }) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? .green : .gray)
                            .font(.system(size: 20))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: transportModeIcon(for: option.transportType))
                            .foregroundColor(.blue)
                            .font(.system(size: 16))
                        
                        Text(option.transportType.capitalized)
                            .font(.subheadline)
                            .bold()
                        
                        if isRecommended && !isSelected {
                            Text("Recommended")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                        
                        if isSelected {
                            Text("Selected")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        }
                        
                        if option.isRoundTrip == true {
                            Text("Round Trip")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.purple.opacity(0.2))
                                .foregroundColor(.purple)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(option.duration)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if option.cost.cashAmount > 0 {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("$\(Int(option.cost.cashAmount))")
                                .font(.headline)
                                .bold()
                                .foregroundColor(isSelected ? .green : .primary)
                            
                            if option.isRoundTrip == true {
                                Text("total round-trip")
                                    .font(.caption2)
                                    .foregroundColor(.purple)
                                    .italic()
                            }
                        }
                    } else if option.cost.cashAmount == 0 {
                        // Check if this might be a return segment of a round-trip
                        let isLikelyReturnSegment = segment.transportOptions.contains { otherOption in
                            otherOption.isRoundTrip == true && otherOption.cost.cashAmount > 0
                        }
                        
                        if isLikelyReturnSegment {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("$0")
                                    .font(.headline)
                                    .bold()
                                    .foregroundColor(.secondary)
                                Text("included in outbound")
                                    .font(.caption2)
                                    .foregroundColor(.purple)
                                    .italic()
                            }
                        } else {
                            Text("$0")
                                .font(.headline)
                                .bold()
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let points = option.cost.pointsAmount, points > 0,
                       let program = option.cost.pointsProgram {
                        Text("\(points) \(program) pts")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    Text("Priority \(option.priority)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Flight/transport details
            if option.transportType == "flight" {
                VStack(alignment: .leading, spacing: 8) {
                    AdminFlightDetailsView(flightDetails: option.details)
                    
                    // Separated tap indicator
                    HStack {
                        Spacer()
                        Button(action: {
                            showingFlightDetails = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 14))
                                Text("View Flight Details")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            // Notes section
            if !option.notes.isEmpty {
                Text(option.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            // Action buttons
            HStack {
                if !option.bookingUrl.isEmpty {
                    Link(destination: URL(string: option.bookingUrl)!) {
                        HStack {
                            Image(systemName: "globe")
                            Text(option.isRoundTrip == true ? "Book Round Trip" : "Book Flight")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                }
                
                Spacer()
                
                if showSelection && !isSelected {
                    Button("Select This Option") {
                        onSelection(option.id)
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: isSelected ? 2 : 1)
        )
        .sheet(isPresented: $showingFlightDetails) {
            if option.transportType == "flight" {
                FlightDetailModal(
                    flightDetails: option.details,
                    option: option
                )
            }
        }
    }
}

struct AdminBookingDeadlinesSectionView: View {
    let deadlines: [AdminBookingDeadline]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Booking Deadlines")
                .font(.headline)
            
            ForEach(deadlines) { deadline in
                AdminBookingDeadlineView(deadline: deadline)
            }
        }
    }
}

struct AdminBookingDeadlineView: View {
    let deadline: AdminBookingDeadline
    
    private var priorityColor: Color {
        switch deadline.priority.lowercased() {
        case "high": return .red
        case "medium": return .orange
        case "low": return .green
        default: return .gray
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(deadline.item)
                    .font(.subheadline)
                    .bold()
                
                Text(deadline.deadline)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(deadline.priority.capitalized)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(priorityColor.opacity(0.2))
                .foregroundColor(priorityColor)
                .cornerRadius(6)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
}

struct AdminGeneralInstructionsView: View {
    let instructions: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("General Instructions")
                .font(.headline)
            
            Text(instructions)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(12)
    }
}

struct AdminFlightDetailsView: View {
    let flightDetails: AdminFlightDetails
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Flight info header
            HStack {
                Text("\(flightDetails.airline) \(flightDetails.flightNumber)")
                    .font(.subheadline)
                    .bold()
                
                Spacer()
                
                Text(flightDetails.flightClass.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
            
            // Route and times
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(flightDetails.departureAirportName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(flightDetails.details.departure.time)")
                        .font(.subheadline)
                        .bold()
                    
                    Text(flightDetails.details.departure.airportCode)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.gray)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(flightDetails.arrivalAirportName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(flightDetails.details.arrival.time)")
                        .font(.subheadline)
                        .bold()
                    
                    Text(flightDetails.details.arrival.airportCode)
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // Aircraft info
            if !flightDetails.aircraft.isEmpty {
                Text("Aircraft: \(flightDetails.aircraft)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Flight Detail Modal
struct FlightDetailModal: View {
    let flightDetails: AdminFlightDetails
    let option: AdminTransportOption
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Flight Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "airplane")
                                .font(.system(size: 40))
                                .foregroundColor(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(flightDetails.airline) \(flightDetails.flightNumber)")
                                    .font(.title2)
                                    .bold()
                                
                                Text(flightDetails.aircraft)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(flightDetails.flightClass)
                                    .font(.headline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                                
                                Text(option.duration)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Route Information
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Flight Route")
                            .font(.headline)
                        
                        HStack {
                            // Departure
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Departure")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(flightDetails.departureAirportName)
                                        .font(.title3)
                                        .bold()
                                    
                                    Text(flightDetails.details.departure.airportCode)
                                        .font(.title)
                                        .bold()
                                        .foregroundColor(.blue)
                                    
                                    if !flightDetails.details.departure.time.isEmpty {
                                        Text(flightDetails.details.departure.time)
                                            .font(.subheadline)
                                    }
                                    
                                    if !flightDetails.details.departure.date.isEmpty {
                                        Text(flightDetails.details.departure.date)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            // Arrow
                            VStack {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.blue)
                                Text(option.duration)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Arrival
                            VStack(alignment: .trailing, spacing: 8) {
                                Text("Arrival")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(flightDetails.arrivalAirportName)
                                        .font(.title3)
                                        .bold()
                                        .multilineTextAlignment(.trailing)
                                    
                                    Text(flightDetails.details.arrival.airportCode)
                                        .font(.title)
                                        .bold()
                                        .foregroundColor(.blue)
                                    
                                    if !flightDetails.details.arrival.time.isEmpty {
                                        Text(flightDetails.details.arrival.time)
                                            .font(.subheadline)
                                    }
                                    
                                    if !flightDetails.details.arrival.date.isEmpty {
                                        Text(flightDetails.details.arrival.date)
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Cost Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Cost Breakdown")
                            .font(.headline)
                        
                        VStack(spacing: 8) {
                            if option.cost.cashAmount > 0 {
                                HStack {
                                    Text("Cash Price")
                                    Spacer()
                                    Text("$\(Int(option.cost.cashAmount))")
                                        .bold()
                                }
                            }
                            
                            if let points = option.cost.pointsAmount, points > 0,
                               let program = option.cost.pointsProgram {
                                HStack {
                                    Text("\(program) Points")
                                    Spacer()
                                    Text("\(points) pts")
                                        .bold()
                                        .foregroundColor(.blue)
                                }
                            }
                            
                            if option.cost.totalCashValue > 0 && option.cost.totalCashValue != option.cost.cashAmount {
                                HStack {
                                    Text("Total Value")
                                    Spacer()
                                    Text("$\(Int(option.cost.totalCashValue))")
                                        .bold()
                                        .foregroundColor(.green)
                                }
                            }
                            
                            HStack {
                                Text("Payment Type")
                                Spacer()
                                Text(option.cost.displayPaymentType)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.green.opacity(0.05))
                    .cornerRadius(12)
                    
                    // Additional Information
                    if !option.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Additional Notes")
                                .font(.headline)
                            
                            Text(option.notes)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.05))
                        .cornerRadius(12)
                    }
                    
                    // Booking Section
                    if !option.bookingUrl.isEmpty {
                        VStack(spacing: 12) {
                            Button(action: {
                                if let url = URL(string: option.bookingUrl.hasPrefix("http") ? option.bookingUrl : "https://\(option.bookingUrl)") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "globe")
                                    Text("Book This Flight")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(12)
                            }
                            
                            Text("Priority: \(option.priority)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Flight Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}