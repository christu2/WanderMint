import SwiftUI
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

// MARK: - Points Value & CPP Calculator

struct PointsSavingsSummary: Equatable {
    struct ProgramItem: Identifiable, Equatable {
        var id: String { program }
        let program: String
        let points: Int
        let estimatedValue: Double
    }
    
    let totalPointsUsed: Int
    let estimatedCashValueSaved: Double
    let centsPerPoint: Double
    let programBreakdown: [ProgramItem]
    
    var valueRating: String {
        if centsPerPoint >= 2.0 {
            return "Outstanding Value"
        } else if centsPerPoint >= 1.5 {
            return "Great Value"
        } else if centsPerPoint >= 1.0 {
            return "Solid Value"
        } else {
            return "Points Redemption"
        }
    }
    
    var formattedCPP: String {
        String(format: "%.1f¢/pt", centsPerPoint)
    }
    
    var formattedSavings: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: estimatedCashValueSaved)) ?? "$\(Int(estimatedCashValueSaved))"
    }
}

enum PointsValueCalculator {
    /// Returns an industry-standard baseline cents-per-point valuation for a loyalty program.
    static func baselineCentsPerPoint(for program: String) -> Double {
        let p = program.lowercased()
        if p.contains("hyatt") { return 2.0 }
        if p.contains("chase") || p.contains("amex") || p.contains("american express") ||
            p.contains("capital one") || p.contains("bilt") || p.contains("citi") {
            return 1.8
        }
        if p.contains("flying blue") || p.contains("air france") || p.contains("klm") ||
            p.contains("aeroplan") || p.contains("united") || p.contains("alaska") ||
            p.contains("american airlines") || p.contains("avios") || p.contains("virgin") ||
            p.contains("delta") || p.contains("southwest") {
            return 1.5
        }
        if p.contains("marriott") || p.contains("ihg") { return 0.7 }
        if p.contains("hilton") { return 0.5 }
        return AppConfig.PointsValues.defaultCreditCardValue
    }
    
    /// Summarizes total points redeemed, estimated cash value saved, and cents-per-point (CPP).
    static func summarize(recommendation: AdminDestinationBasedRecommendation) -> PointsSavingsSummary? {
        var pointsMap: [String: Int] = [:]
        
        if let explicit = recommendation.totalCost.pointsUsed {
            for (program, pts) in explicit where pts > 0 {
                pointsMap[program, default: 0] += pts
            }
        }
        
        // Fallback: derive from top-priority hotel & transport options if totalCost.pointsUsed wasn't populated
        if pointsMap.isEmpty {
            for dest in recommendation.destinations {
                if let topHotel = dest.accommodationOptions.sorted(by: { $0.priority < $1.priority }).first,
                   let ptsPerNight = topHotel.hotel.pointsPerNight, ptsPerNight > 0 {
                    let program = (topHotel.hotel.loyaltyProgram?.isEmpty == false)
                        ? topHotel.hotel.loyaltyProgram!
                        : "Hotel Points"
                    pointsMap[program, default: 0] += ptsPerNight * max(1, dest.numberOfNights)
                }
            }
            for seg in recommendation.logistics.transportSegments {
                if let topOpt = seg.transportOptions.sorted(by: { $0.priority < $1.priority }).first,
                   let pts = topOpt.cost.pointsAmount, pts > 0 {
                    let program = (topOpt.cost.pointsProgram?.isEmpty == false)
                        ? topOpt.cost.pointsProgram!
                        : "Airline Miles"
                    pointsMap[program, default: 0] += pts
                }
            }
        }
        
        let totalPoints = pointsMap.values.reduce(0, +)
        guard totalPoints > 0 else { return nil }
        
        let breakdown: [PointsSavingsSummary.ProgramItem] = pointsMap
            .sorted { $0.value > $1.value }
            .map { program, pts in
                let cpp = baselineCentsPerPoint(for: program)
                let val = (Double(pts) * cpp) / 100.0
                return PointsSavingsSummary.ProgramItem(program: program, points: pts, estimatedValue: val)
            }
        
        let totalValue = breakdown.reduce(0.0) { $0 + $1.estimatedValue }
        let blendedCPP = (totalValue / Double(totalPoints)) * 100.0
        
        return PointsSavingsSummary(
            totalPointsUsed: totalPoints,
            estimatedCashValueSaved: totalValue,
            centsPerPoint: blendedCPP,
            programBreakdown: breakdown
        )
    }
}

// MARK: - Interactive Trip Booking & Transfer Checklist Builder

struct TripChecklistItem: Identifiable, Equatable {
    enum Category: String, Equatable {
        case pointsTransfer
        case flight
        case hotel
        case deadline
        
        var icon: String {
            switch self {
            case .pointsTransfer: return "arrow.left.arrow.right.circle.fill"
            case .flight: return "airplane.circle.fill"
            case .hotel: return "building.2.crop.circle.fill"
            case .deadline: return "calendar.badge.exclamationmark"
            }
        }
        
        var accentColor: Color {
            switch self {
            case .pointsTransfer: return .purple
            case .flight: return .blue
            case .hotel: return .teal
            case .deadline: return .orange
            }
        }
    }
    
    let id: String
    let stepNumber: Int
    let category: Category
    let title: String
    let subtitle: String
    let pointsAmount: Int?
    let pointsProgram: String?
    let actionURL: URL?
}

enum TripChecklistBuilder {
    static func buildItems(from recommendation: AdminDestinationBasedRecommendation) -> [TripChecklistItem] {
        var items: [TripChecklistItem] = []
        var step = 1
        
        // 1. Points transfer / redemption prep steps
        if let summary = PointsValueCalculator.summarize(recommendation: recommendation) {
            for item in summary.programBreakdown {
                let formattedPts = NumberFormatter.localizedString(from: NSNumber(value: item.points), number: .decimal)
                let note = recommendation.costNotes?.trimmingCharacters(in: .whitespacesAndNewlines)
                items.append(TripChecklistItem(
                    id: "transfer_\(item.program.lowercased().replacingOccurrences(of: " ", with: "_"))",
                    stepNumber: step,
                    category: .pointsTransfer,
                    title: "Prepare \(formattedPts) \(item.program) pts",
                    subtitle: (note?.isEmpty == false) ? note! : "Confirm balance or transfer points before booking award space.",
                    pointsAmount: item.points,
                    pointsProgram: item.program,
                    actionURL: nil
                ))
                step += 1
            }
        }
        
        // 2. Top transport / flight booking per segment
        for segment in recommendation.logistics.transportSegments {
            if let topOption = segment.transportOptions.sorted(by: { $0.priority < $1.priority }).first {
                let airline = topOption.details.airline.isEmpty ? topOption.transportType.capitalized : topOption.details.airline
                let flightNum = topOption.details.flightNumber.isEmpty ? "" : " \(topOption.details.flightNumber)"
                let subtitle = "\(segment.fromCity) → \(segment.toCity) · \(segment.departureDate)"
                items.append(TripChecklistItem(
                    id: "transport_\(segment.id)_\(topOption.id)",
                    stepNumber: step,
                    category: .flight,
                    title: "Book \(airline)\(flightNum)",
                    subtitle: subtitle,
                    pointsAmount: topOption.cost.pointsAmount,
                    pointsProgram: topOption.cost.pointsProgram,
                    actionURL: AppConfig.safeExternalURL(from: topOption.bookingUrl)
                ))
                step += 1
            }
        }
        
        // 3. Top hotel booking per destination
        for dest in recommendation.destinations {
            if let topAcc = dest.accommodationOptions.sorted(by: { $0.priority < $1.priority }).first {
                let hotel = topAcc.hotel
                let rateDetail: String
                if let pts = hotel.pointsPerNight, pts > 0 {
                    let totalPts = pts * max(1, dest.numberOfNights)
                    let fmt = NumberFormatter.localizedString(from: NSNumber(value: totalPts), number: .decimal)
                    rateDetail = "\(dest.numberOfNights) nights · \(fmt) \(hotel.loyaltyProgram ?? "pts")"
                } else if hotel.pricePerNight > 0 {
                    rateDetail = "\(dest.numberOfNights) nights · $\(Int(hotel.pricePerNight))/night"
                } else {
                    rateDetail = "\(dest.numberOfNights) nights · \(dest.arrivalDate) – \(dest.departureDate)"
                }
                items.append(TripChecklistItem(
                    id: "hotel_\(dest.id)_\(topAcc.id)",
                    stepNumber: step,
                    category: .hotel,
                    title: "Book \(hotel.name)",
                    subtitle: rateDetail,
                    pointsAmount: (hotel.pointsPerNight ?? 0) > 0 ? (hotel.pointsPerNight! * max(1, dest.numberOfNights)) : nil,
                    pointsProgram: hotel.loyaltyProgram,
                    actionURL: AppConfig.safeExternalURL(from: hotel.bookingUrl)
                ))
                step += 1
            }
        }
        
        // 4. Booking deadlines
        for deadline in recommendation.logistics.bookingDeadlines {
            guard !deadline.item.isEmpty else { continue }
            items.append(TripChecklistItem(
                id: "deadline_\(deadline.id)",
                stepNumber: step,
                category: .deadline,
                title: deadline.item,
                subtitle: "Target deadline: \(deadline.deadline)",
                pointsAmount: nil,
                pointsProgram: nil,
                actionURL: nil
            ))
            step += 1
        }
        
        return items
    }
}

// MARK: - Points Savings Banner Card

struct PointsSavingsBannerCard: View {
    let recommendation: AdminDestinationBasedRecommendation
    
    var body: some View {
        if let summary = PointsValueCalculator.summarize(recommendation: recommendation) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Points Value Unlocked")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.9))
                        Text("Est. \(summary.formattedSavings) Saved")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(summary.formattedCPP)
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.22))
                            .foregroundColor(.white)
                            .cornerRadius(999)
                        
                        Text(summary.valueRating)
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                
                HStack(spacing: 8) {
                    ForEach(summary.programBreakdown) { item in
                        let pts = NumberFormatter.localizedString(from: NSNumber(value: item.points), number: .decimal)
                        Text("\(pts) \(item.program)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.16))
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                }
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.04, green: 0.56, blue: 0.45), Color(red: 0.06, green: 0.46, blue: 0.72)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
        }
    }
}

// MARK: - Interactive Booking & Transfer Checklist Card

struct InteractiveBookingChecklistCard: View {
    let tripId: String
    let recommendation: AdminDestinationBasedRecommendation
    
    @State private var completedIds: Set<String> = []
    @State private var walletMessage: String?
    
    private var items: [TripChecklistItem] {
        TripChecklistBuilder.buildItems(from: recommendation)
    }
    
    private var storageKey: String {
        "wandermint_checklist_\(tripId)"
    }
    
    private var completedCount: Int {
        items.filter { completedIds.contains($0.id) }.count
    }
    
    var body: some View {
        if !items.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: "checklist")
                        .foregroundColor(AppTheme.Colors.primary)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Booking & Points Checklist")
                            .font(.headline)
                        Text("\(completedCount) of \(items.count) steps completed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                
                ProgressView(value: Double(completedCount), total: Double(max(1, items.count)))
                    .tint(AppTheme.Colors.primary)
                
                VStack(spacing: 10) {
                    ForEach(items) { item in
                        let isDone = completedIds.contains(item.id)
                        HStack(alignment: .top, spacing: 12) {
                            Button(action: { toggle(item) }) {
                                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundColor(isDone ? .green : .secondary)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .accessibilityLabel("\(isDone ? "Uncheck" : "Complete") step \(item.stepNumber): \(item.title)")
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 6) {
                                    Image(systemName: item.category.icon)
                                        .font(.caption)
                                        .foregroundColor(item.category.accentColor)
                                    Text("Step \(item.stepNumber): \(item.title)")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .strikethrough(isDone)
                                        .foregroundColor(isDone ? .secondary : .primary)
                                }
                                
                                Text(item.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if let url = item.actionURL, !isDone {
                                    Link(destination: url) {
                                        HStack(spacing: 4) {
                                            Text("Open Booking Page")
                                            Image(systemName: "arrow.up.right.square")
                                        }
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(AppTheme.Colors.primary)
                                    }
                                    .padding(.top, 2)
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(12)
                        .background(isDone ? Color.green.opacity(0.06) : Color.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isDone ? Color.green.opacity(0.25) : Color.gray.opacity(0.18), lineWidth: 1)
                        )
                    }
                }
                
                if let walletMessage = walletMessage {
                    Text(walletMessage)
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(UIColor.systemGray6))
            .cornerRadius(12)
            .onAppear(perform: loadChecklistState)
        }
    }
    
    private func loadChecklistState() {
        let saved = UserDefaults.standard.stringArray(forKey: storageKey) ?? []
        completedIds = Set(saved)
    }
    
    private func toggle(_ item: TripChecklistItem) {
        if completedIds.contains(item.id) {
            completedIds.remove(item.id)
        } else {
            completedIds.insert(item.id)
        }
        let sortedIds = Array(completedIds).sorted()
        UserDefaults.standard.set(sortedIds, forKey: storageKey)
        
        // Best-effort sync to Firestore (does not touch status/userId, complies with security rules)
        #if canImport(FirebaseFirestore)
        guard !tripId.isEmpty else { return }
        Task {
            try? await Firestore.firestore().collection("trips").document(tripId).updateData([
                "checklistCompletedIds": sortedIds,
                "updatedAt": FieldValue.serverTimestamp()
            ])
        }
        #endif
    }
}
