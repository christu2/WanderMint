import SwiftUI
import UIKit

// MARK: - Map Launcher Utility
enum MapLauncher {
    /// Opens the specified location in Apple Maps or Google Maps
    static func openMap(for location: String, name: String? = nil) {
        let queryText = [name, location].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
        guard let encodedQuery = queryText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        
        // Try Apple Maps universal link first (native on iOS)
        if let appleMapsURL = URL(string: "https://maps.apple.com/?q=\(encodedQuery)") {
            UIApplication.shared.open(appleMapsURL, options: [:], completionHandler: nil)
        }
    }
    
    /// Opens location directly in Google Maps (app or web)
    static func openGoogleMaps(for location: String, name: String? = nil) {
        let queryText = [name, location].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
        guard let encodedQuery = queryText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        
        // Google Maps App Scheme
        if let appURL = URL(string: "comgooglemaps://?q=\(encodedQuery)"),
           UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL, options: [:], completionHandler: nil)
            return
        }
        
        // Google Maps Web URL
        if let webURL = URL(string: "https://www.google.com/maps/search/?api=1&query=\(encodedQuery)") {
            UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
        }
    }
    
    /// Opens Yelp search or direct Yelp URL
    static func openYelp(for businessName: String, location: String? = nil, directUrl: String? = nil) {
        if let directUrl = directUrl, let url = URL(string: directUrl), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return
        }
        
        guard let encodedName = businessName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        let locParam = (location ?? "").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let yelpSearchString = "https://www.yelp.com/search?find_desc=\(encodedName)&find_loc=\(locParam)"
        
        if let url = URL(string: yelpSearchString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    /// Opens TripAdvisor search or direct TripAdvisor URL
    static func openTripAdvisor(for name: String, location: String? = nil, directUrl: String? = nil) {
        if let directUrl = directUrl, let url = URL(string: directUrl), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            return
        }
        
        let query = [name, location].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        let tripAdvisorSearch = "https://www.tripadvisor.com/Search?q=\(encodedQuery)"
        
        if let url = URL(string: tripAdvisorSearch) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

// MARK: - Location Map Pill Button
struct LocationMapButton: View {
    let location: String
    var name: String? = nil
    var showDialog: Bool = false
    
    @State private var showingOptions = false
    
    var body: some View {
        Button(action: {
            showingOptions = true
        }) {
            HStack(spacing: 4) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.caption2)
                Text(location)
                    .font(.caption)
                    .lineLimit(1)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 8, weight: .bold))
            }
            .foregroundColor(.blue)
        }
        .confirmationDialog("Open in Maps", isPresented: $showingOptions, titleVisibility: .visible) {
            Button("Apple Maps") {
                MapLauncher.openMap(for: location, name: name)
            }
            Button("Google Maps") {
                MapLauncher.openGoogleMaps(for: location, name: name)
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Action Link Button
struct ActionLinkButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(title)
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12))
            .foregroundColor(color)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}
