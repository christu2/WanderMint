import SwiftUI
import UIKit

/// Device testing utilities for ensuring compatibility across different screen sizes and orientations
struct DeviceTestingUtils {
    
    // MARK: - Device Size Categories
    
    enum DeviceSize {
        case compact // iPhone SE, iPhone 12 mini
        case regular // iPhone 12, iPhone 13
        case large   // iPhone 12 Pro Max, iPhone 13 Pro Max
        case tablet  // iPad
        
        var screenSize: CGSize {
            switch self {
            case .compact:
                return CGSize(width: 375, height: 667) // iPhone SE
            case .regular:
                return CGSize(width: 390, height: 844) // iPhone 12
            case .large:
                return CGSize(width: 428, height: 926) // iPhone 12 Pro Max
            case .tablet:
                return CGSize(width: 820, height: 1180) // iPad
            }
        }
        
        var name: String {
            switch self {
            case .compact:
                return "iPhone SE"
            case .regular:
                return "iPhone 12"
            case .large:
                return "iPhone 12 Pro Max"
            case .tablet:
                return "iPad"
            }
        }
    }
    
    // MARK: - Orientation Testing
    
    enum TestOrientation {
        case portrait
        case landscape
        
        var name: String {
            switch self {
            case .portrait:
                return "Portrait"
            case .landscape:
                return "Landscape"
            }
        }
    }
    
    // MARK: - Current Device Info
    
    static var currentDevice: DeviceSize {
        let width = UIScreen.main.bounds.width
        let height = UIScreen.main.bounds.height
        let screenSize = max(width, height)
        
        switch screenSize {
        case 0..<700:
            return .compact
        case 700..<900:
            return .regular
        case 900..<1000:
            return .large
        default:
            return .tablet
        }
    }
    
    static var currentOrientation: TestOrientation {
        let width = UIScreen.main.bounds.width
        let height = UIScreen.main.bounds.height
        return width > height ? .landscape : .portrait
    }
    
    // MARK: - Dynamic Type Testing
    
    static let dynamicTypeSizes: [ContentSizeCategory] = [
        .extraSmall,
        .small,
        .medium,
        .large,
        .extraLarge,
        .extraExtraLarge,
        .extraExtraExtraLarge,
        .accessibilityMedium,
        .accessibilityLarge,
        .accessibilityExtraLarge,
        .accessibilityExtraExtraLarge,
        .accessibilityExtraExtraExtraLarge
    ]
    
    // MARK: - Safe Area Testing
    
    static func safeAreaInsets(for device: DeviceSize) -> EdgeInsets {
        switch device {
        case .compact:
            return EdgeInsets(top: 20, leading: 0, bottom: 0, trailing: 0)
        case .regular:
            return EdgeInsets(top: 47, leading: 0, bottom: 34, trailing: 0)
        case .large:
            return EdgeInsets(top: 47, leading: 0, bottom: 34, trailing: 0)
        case .tablet:
            return EdgeInsets(top: 24, leading: 0, bottom: 20, trailing: 0)
        }
    }
    
    // MARK: - Layout Testing Helpers
    
    static func isCompactWidth(_ size: CGSize) -> Bool {
        return size.width < 400
    }
    
    static func isCompactHeight(_ size: CGSize) -> Bool {
        return size.height < 600
    }
    
    static func shouldUseCompactLayout(_ size: CGSize) -> Bool {
        return isCompactWidth(size) || isCompactHeight(size)
    }
}

// MARK: - Device Preview Helper

struct DevicePreview<Content: View>: View {
    let content: Content
    let devices: [DeviceTestingUtils.DeviceSize]
    let orientations: [DeviceTestingUtils.TestOrientation]
    
    init(
        devices: [DeviceTestingUtils.DeviceSize] = [.compact, .regular, .large],
        orientations: [DeviceTestingUtils.TestOrientation] = [.portrait],
        @ViewBuilder content: () -> Content
    ) {
        self.devices = devices
        self.orientations = orientations
        self.content = content()
    }
    
    var body: some View {
        ForEach(devices, id: \.name) { device in
            ForEach(orientations, id: \.name) { orientation in
                content
                    .previewDevice(PreviewDevice(rawValue: device.name))
                    .previewDisplayName("\(device.name) - \(orientation.name)")
                    .previewInterfaceOrientation(
                        orientation == .portrait ? .portrait : .landscapeLeft
                    )
            }
        }
    }
}

// MARK: - Responsive Layout Modifier

struct ResponsiveLayoutModifier: ViewModifier {
    let geometry: GeometryProxy
    
    func body(content: Content) -> some View {
        let isCompact = DeviceTestingUtils.shouldUseCompactLayout(geometry.size)
        
        content
            .padding(.horizontal, isCompact ? 16 : 24)
            .padding(.vertical, isCompact ? 12 : 16)
    }
}

extension View {
    func responsiveLayout(_ geometry: GeometryProxy) -> some View {
        self.modifier(ResponsiveLayoutModifier(geometry: geometry))
    }
}

// MARK: - Adaptive Stack

struct AdaptiveStack<Content: View>: View {
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment
    let spacing: CGFloat?
    let content: Content
    
    init(
        horizontalAlignment: HorizontalAlignment = .center,
        verticalAlignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.horizontalAlignment = horizontalAlignment
        self.verticalAlignment = verticalAlignment
        self.spacing = spacing
        self.content = content()
    }
    
    var body: some View {
        GeometryReader { geometry in
            if DeviceTestingUtils.shouldUseCompactLayout(geometry.size) {
                VStack(alignment: horizontalAlignment, spacing: spacing) {
                    content
                }
            } else {
                HStack(alignment: verticalAlignment, spacing: spacing) {
                    content
                }
            }
        }
    }
}

// MARK: - Orientation-Aware View

struct OrientationAwareView<PortraitContent: View, LandscapeContent: View>: View {
    let portraitContent: PortraitContent
    let landscapeContent: LandscapeContent
    
    @State private var orientation = UIDeviceOrientation.unknown
    
    init(
        @ViewBuilder portrait: () -> PortraitContent,
        @ViewBuilder landscape: () -> LandscapeContent
    ) {
        self.portraitContent = portrait()
        self.landscapeContent = landscape()
    }
    
    var body: some View {
        Group {
            if orientation.isLandscape {
                landscapeContent
            } else {
                portraitContent
            }
        }
        .onAppear {
            self.orientation = UIDevice.current.orientation
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            self.orientation = UIDevice.current.orientation
        }
    }
}

// MARK: - Accessibility Testing

struct AccessibilityTestingView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack {
            ForEach(Array(DeviceTestingUtils.dynamicTypeSizes.enumerated()), id: \.offset) { index, sizeCategory in
                content
                    .environment(\.sizeCategory, sizeCategory)
                    .border(Color.gray.opacity(0.3))
                    .overlay(
                        Text(String(describing: sizeCategory))
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .padding(4)
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(4),
                        alignment: .topTrailing
                    )
            }
        }
        .padding()
    }
}

// MARK: - Layout Testing Views

struct LayoutTestingView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Layout Testing")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            GeometryReader { geometry in
                VStack(alignment: .leading, spacing: 16) {
                    Text("Device: \(DeviceTestingUtils.currentDevice.name)")
                    Text("Orientation: \(DeviceTestingUtils.currentOrientation.name)")
                    Text("Size: \(Int(geometry.size.width)) × \(Int(geometry.size.height))")
                    Text("Compact Width: \(DeviceTestingUtils.isCompactWidth(geometry.size) ? "Yes" : "No")")
                    Text("Compact Height: \(DeviceTestingUtils.isCompactHeight(geometry.size) ? "Yes" : "No")")
                    Text("Use Compact Layout: \(DeviceTestingUtils.shouldUseCompactLayout(geometry.size) ? "Yes" : "No")")
                }
                .font(.body)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
            .frame(height: 200)
            
            AdaptiveStack(spacing: 16) {
                Button("Button 1") {}
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                
                Button("Button 2") {}
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                
                Button("Button 3") {}
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .frame(height: 100)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview Helpers

#if DEBUG
struct DeviceTestingUtils_Previews: PreviewProvider {
    static var previews: some View {
        DevicePreview(
            devices: [.compact, .regular, .large],
            orientations: [.portrait, .landscape]
        ) {
            LayoutTestingView()
        }
    }
}
#endif