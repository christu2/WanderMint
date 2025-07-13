import SwiftUI

// MARK: - App Theme System
struct AppTheme {
    
    // MARK: - Colors
    struct Colors {
        // Primary Brand Colors
        static let primary = Color(red: 0.14, green: 0.47, blue: 0.85)  // Professional blue
        static let primaryDark = Color(red: 0.09, green: 0.31, blue: 0.57)
        static let primaryLight = Color(red: 0.85, green: 0.93, blue: 1.0)
        
        // Secondary Colors
        static let secondary = Color(red: 0.95, green: 0.61, blue: 0.07)  // Warm orange
        static let secondaryDark = Color(red: 0.80, green: 0.45, blue: 0.05)
        static let secondaryLight = Color(red: 1.0, green: 0.95, blue: 0.85)
        
        // Accent Colors
        static let accent = Color(red: 0.20, green: 0.78, blue: 0.35)  // Success green
        static let accentDark = Color(red: 0.15, green: 0.60, blue: 0.25)
        
        // Semantic Colors
        static let success = Color(red: 0.20, green: 0.78, blue: 0.35)
        static let warning = Color(red: 0.95, green: 0.61, blue: 0.07)
        static let error = Color(red: 0.91, green: 0.30, blue: 0.24)
        static let info = primary
        
        // Neutral Colors
        static let textPrimary = Color(red: 0.11, green: 0.11, blue: 0.11)
        static let textSecondary = Color(red: 0.42, green: 0.42, blue: 0.42)
        static let textTertiary = Color(red: 0.66, green: 0.66, blue: 0.66)
        
        // Background Colors
        static let backgroundPrimary = Color(red: 0.98, green: 0.98, blue: 0.98)
        static let backgroundSecondary = Color(red: 0.95, green: 0.95, blue: 0.95)
        static let backgroundTertiary = Color.white
        
        // Surface Colors
        static let surfaceElevated = Color.white
        static let surfaceCard = Color.white
        static let surfaceBorder = Color(red: 0.90, green: 0.90, blue: 0.90)
        
        // Gradient Colors
        static let gradientPrimary = LinearGradient(
            colors: [primary, primaryDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let gradientSecondary = LinearGradient(
            colors: [secondary, secondaryDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        static let gradientHero = LinearGradient(
            colors: [primary, Color(red: 0.20, green: 0.78, blue: 0.35)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Typography
    struct Typography {
        // Heading Styles
        static let hero = Font.custom("SF Pro Display", size: 34, relativeTo: .largeTitle)
            .weight(.bold)
        
        static let h1 = Font.custom("SF Pro Display", size: 28, relativeTo: .title)
            .weight(.bold)
        
        static let h2 = Font.custom("SF Pro Display", size: 22, relativeTo: .title2)
            .weight(.semibold)
        
        static let h3 = Font.custom("SF Pro Display", size: 20, relativeTo: .title3)
            .weight(.semibold)
        
        static let h4 = Font.custom("SF Pro Text", size: 18, relativeTo: .headline)
            .weight(.semibold)
        
        // Body Styles
        static let bodyLarge = Font.custom("SF Pro Text", size: 17, relativeTo: .body)
            .weight(.regular)
        
        static let body = Font.custom("SF Pro Text", size: 15, relativeTo: .body)
            .weight(.regular)
        
        static let bodySmall = Font.custom("SF Pro Text", size: 13, relativeTo: .footnote)
            .weight(.regular)
        
        // Utility Styles
        static let caption = Font.custom("SF Pro Text", size: 12, relativeTo: .caption)
            .weight(.regular)
        
        static let captionBold = Font.custom("SF Pro Text", size: 12, relativeTo: .caption)
            .weight(.semibold)
        
        static let button = Font.custom("SF Pro Text", size: 16, relativeTo: .body)
            .weight(.semibold)
        
        static let buttonSmall = Font.custom("SF Pro Text", size: 14, relativeTo: .footnote)
            .weight(.semibold)
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
        static let xxxl: CGFloat = 64
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let circle: CGFloat = 50
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let light = Color.black.opacity(0.08)
        static let medium = Color.black.opacity(0.16)
        static let heavy = Color.black.opacity(0.24)
        
        static let cardShadow = Shadow(
            color: light,
            radius: 8,
            x: 0,
            y: 2
        )
        
        static let buttonShadow = Shadow(
            color: medium,
            radius: 4,
            x: 0,
            y: 2
        )
    }
    
    // MARK: - Animation
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let medium = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7)
    }
}

// MARK: - Shadow Helper
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - View Extensions
extension View {
    func applyShadow(_ shadow: Shadow) -> some View {
        self.shadow(color: shadow.color, radius: shadow.radius, x: shadow.x, y: shadow.y)
    }
    
    func cardStyle() -> some View {
        self
            .background(AppTheme.Colors.surfaceCard)
            .cornerRadius(AppTheme.CornerRadius.md)
            .applyShadow(AppTheme.Shadows.cardShadow)
    }
    
    func elevatedCardStyle() -> some View {
        self
            .background(AppTheme.Colors.surfaceElevated)
            .cornerRadius(AppTheme.CornerRadius.lg)
            .applyShadow(AppTheme.Shadows.cardShadow)
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    let isEnabled: Bool
    let isLoading: Bool
    
    init(isEnabled: Bool = true, isLoading: Bool = false) {
        self.isEnabled = isEnabled
        self.isLoading = isLoading
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Typography.button)
            .foregroundColor(.white)
            .frame(minHeight: 44)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                    .fill(
                        isEnabled && !isLoading ? 
                        AppTheme.Colors.gradientPrimary : 
                        LinearGradient(colors: [Color.gray], startPoint: .top, endPoint: .bottom)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(AppTheme.Animation.quick, value: configuration.isPressed)
            .applyShadow(AppTheme.Shadows.buttonShadow)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    let isEnabled: Bool
    
    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppTheme.Typography.button)
            .foregroundColor(isEnabled ? AppTheme.Colors.primary : AppTheme.Colors.textTertiary)
            .frame(minHeight: 44)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                    .stroke(
                        isEnabled ? AppTheme.Colors.primary : AppTheme.Colors.textTertiary,
                        lineWidth: 1.5
                    )
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.md)
                            .fill(Color.clear)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(AppTheme.Animation.quick, value: configuration.isPressed)
    }
}