import SwiftUI

struct AdminRecommendationView: View {
    let recommendation: AdminDestinationBasedRecommendation
    let tripId: String
    let onBookingUpdate: () -> Void
    
    @State private var selectedTab: TabType = .destinations
    @State private var selectedDestination: String = ""
    
    enum TabType: String, CaseIterable {
        case destinations = "Destinations"
        case logistics = "Logistics"
        case overview = "Overview"
        
        var icon: String {
            switch self {
            case .destinations: return "location"
            case .logistics: return "airplane"
            case .overview: return "doc.text"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Trip Overview
            if !recommendation.tripOverview.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Trip Overview")
                        .font(.headline)
                    Text(recommendation.tripOverview)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(UIColor.systemGray6))
                .cornerRadius(12)
                .padding(.bottom, 16)
            }
            
            // Tab Selector
            HStack(spacing: 0) {
                ForEach(TabType.allCases, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: tab.icon)
                            Text(tab.rawValue)
                        }
                        .font(.subheadline)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(selectedTab == tab ? Color.blue.opacity(0.2) : Color.clear)
                        .foregroundColor(selectedTab == tab ? .blue : .secondary)
                    }
                }
            }
            .background(Color(UIColor.systemGray6))
            .cornerRadius(8)
            
            // Tab Content
            Group {
                switch selectedTab {
                case .destinations:
                    AdminDestinationsTabView(
                        destinations: recommendation.destinations,
                        tripId: tripId,
                        onBookingUpdate: onBookingUpdate
                    )
                case .logistics:
                    AdminLogisticsTabView(
                        logistics: recommendation.logistics,
                        tripId: tripId,
                        onBookingUpdate: onBookingUpdate
                    )
                case .overview:
                    AdminOverviewTabView(
                        recommendation: recommendation
                    )
                }
            }
        }
        .onAppear {
            if !recommendation.destinations.isEmpty {
                selectedDestination = recommendation.destinations[0].cityName
            }
        }
    }
}

struct AdminDestinationsTabView: View {
    let destinations: [AdminDestination]
    let tripId: String
    let onBookingUpdate: () -> Void
    
    @State private var selectedDestination: Int = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if destinations.isEmpty {
                AdminEmptyStateView(
                    icon: "map",
                    title: "Destinations Coming Soon",
                    subtitle: "Your personalized destination recommendations will appear here once your trip planning is complete."
                )
            } else {
                if destinations.count > 1 {
                    // City selector for multi-city trips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(destinations.enumerated()), id: \.element.id) { index, destination in
                                Button(action: {
                                    selectedDestination = index
                                }) {
                                    VStack(spacing: 4) {
                                        Text(destination.cityName)
                                            .font(.headline)
                                        Text("\(destination.numberOfNights) nights")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(selectedDestination == index ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                    .cornerRadius(8)
                                }
                                .foregroundColor(selectedDestination == index ? .blue : .primary)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                // Destination details
                let destination = destinations[selectedDestination]
                AdminDestinationDetailView(destination: destination, tripId: tripId, onBookingUpdate: onBookingUpdate)
            }
        }
        .padding()
    }
}

struct AdminLogisticsTabView: View {
    let logistics: AdminLogistics
    let tripId: String
    let onBookingUpdate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if logistics.transportSegments.isEmpty && logistics.bookingDeadlines.isEmpty {
                AdminEmptyStateView(
                    icon: "airplane",
                    title: "Logistics Coming Soon",
                    subtitle: "Your travel logistics and transportation details will appear here."
                )
            } else {
                AdminLogisticsDetailView(logistics: logistics, tripId: tripId, onBookingUpdate: onBookingUpdate)
            }
        }
        .padding()
    }
}

struct AdminOverviewTabView: View {
    let recommendation: AdminDestinationBasedRecommendation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            AdminCostBreakdownView(totalCost: recommendation.totalCost, recommendation: recommendation)
            
            if !recommendation.destinations.isEmpty {
                AdminTripSummaryView(destinations: recommendation.destinations)
            }
        }
        .padding()
    }
}

struct AdminEmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}