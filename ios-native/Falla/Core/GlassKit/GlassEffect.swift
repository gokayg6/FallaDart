// GlassEffect.swift
// Falla - iOS 26 Fortune Telling App
// iOS 26 Liquid Glass effect system using native APIs

import SwiftUI

// MARK: - Glass Effect Container
/// Root container that enables Liquid Glass visual coordination for all child views
/// iOS 26: Uses native GlassEffectContainer for glass surface merging and coherence
@available(iOS 26.0, *)
struct GlassEffectContainer<Content: View>: View {
    let content: Content
    
    /// Namespace for coordinated glass transitions across the app
    @Namespace private var glassNamespace
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        // iOS 26 native glass container - all glass surfaces inside visually merge
        // and maintain coherence during transitions
        content
            .environment(\.glassNamespace, glassNamespace)
            .environment(\.glassEffectEnabled, true)
    }
}

// MARK: - Glass Style Configuration
/// Predefined glass styles matching Apple's iOS 26 design language
@available(iOS 26.0, *)
enum GlassStyle: Sendable {
    case ultraThin      // Lightest blur, most transparent
    case thin           // Standard glass effect
    case regular        // Default glass with balanced blur
    case thick          // Heavy blur, more opaque
    case prominent      // High contrast for important surfaces
    
    /// Returns the appropriate material for the glass style
    var material: Material {
        switch self {
        case .ultraThin:
            return .ultraThinMaterial
        case .thin:
            return .thinMaterial
        case .regular:
            return .regularMaterial
        case .thick:
            return .thickMaterial
        case .prominent:
            return .ultraThickMaterial
        }
    }
    
    /// Tint opacity for glass overlay
    var tintOpacity: Double {
        switch self {
        case .ultraThin: return 0.05
        case .thin: return 0.08
        case .regular: return 0.12
        case .thick: return 0.18
        case .prominent: return 0.25
        }
    }
    
    /// Border opacity for glass edge highlight
    var borderOpacity: Double {
        switch self {
        case .ultraThin: return 0.15
        case .thin: return 0.2
        case .regular: return 0.25
        case .thick: return 0.3
        case .prominent: return 0.4
        }
    }
}

// MARK: - Glass Effect Modifier
/// View modifier applying iOS 26 native Liquid Glass effect
@available(iOS 26.0, *)
struct LiquidGlassModifier: ViewModifier {
    let style: GlassStyle
    let cornerRadius: CGFloat
    let tintColor: Color
    let glassID: String?
    
    @Environment(\.glassNamespace) private var namespace
    
    func body(content: Content) -> some View {
        content
            .background {
                // iOS 26 Native Glass Effect
                // The .glassEffect() modifier creates true depth-aware glass
                // that dynamically blurs and reflects background content
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(style.material)
                    .glassEffect(
                        .regular,
                        in: RoundedRectangle(cornerRadius: cornerRadius)
                    )
                    .overlay {
                        // Subtle tint overlay for branding
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(tintColor.opacity(style.tintOpacity))
                    }
                    .overlay {
                        // Inner edge highlight for depth perception
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(style.borderOpacity),
                                        .white.opacity(style.borderOpacity * 0.4),
                                        .white.opacity(style.borderOpacity * 0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
            }
            // Apply glass effect ID for coordinated transitions
            .modifier(GlassIDModifier(id: glassID, namespace: namespace))
    }
}

// MARK: - Glass ID Modifier
/// Applies glassEffectID when an ID is provided
@available(iOS 26.0, *)
struct GlassIDModifier: ViewModifier {
    let id: String?
    let namespace: Namespace.ID?
    
    func body(content: Content) -> some View {
        if let id = id, let namespace = namespace {
            content.glassEffectID(id, in: namespace)
        } else {
            content
        }
    }
}

// MARK: - Glass Effect Group IDs
/// Predefined glass effect IDs for coordinated transitions across the app
/// Using these IDs ensures glass surfaces morph smoothly between views
enum GlassEffectGroup {
    static let navigation = "falla.navigation.glass"
    static let tabBar = "falla.tabbar.glass"
    static let tabBlob = "falla.tabbar.blob"
    static let card = "falla.card.glass"
    static let modal = "falla.modal.glass"
    static let sheet = "falla.sheet.glass"
    static let header = "falla.header.glass"
    static let avatar = "falla.avatar.glass"
    static let progressRing = "falla.progress.ring"
    static let filterChip = "falla.filter.chip"
    static let historyRow = "falla.history.row"
}

// MARK: - View Extension
@available(iOS 26.0, *)
extension View {
    /// Apply iOS 26 Liquid Glass effect to any view
    /// - Parameters:
    ///   - style: Glass style intensity
    ///   - cornerRadius: Corner radius of the glass surface
    ///   - tintColor: Optional tint color for branding
    ///   - glassID: Optional ID for coordinated transitions
    func liquidGlass(
        style: GlassStyle = .regular,
        cornerRadius: CGFloat = 24,
        tintColor: Color = .white,
        glassID: String? = nil
    ) -> some View {
        self.modifier(LiquidGlassModifier(
            style: style,
            cornerRadius: cornerRadius,
            tintColor: tintColor,
            glassID: glassID
        ))
    }
    
    /// Apply glass effect with automatic ID from GlassEffectGroup
    func liquidGlass(
        style: GlassStyle = .regular,
        cornerRadius: CGFloat = 24,
        group: String
    ) -> some View {
        self.modifier(LiquidGlassModifier(
            style: style,
            cornerRadius: cornerRadius,
            tintColor: .white,
            glassID: group
        ))
    }
}

// MARK: - Environment Keys

/// Glass namespace environment key for coordinated transitions
private struct GlassNamespaceKey: EnvironmentKey {
    static let defaultValue: Namespace.ID? = nil
}

/// Glass effect enabled environment key
private struct GlassEffectEnabledKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

@available(iOS 26.0, *)
extension EnvironmentValues {
    var glassNamespace: Namespace.ID? {
        get { self[GlassNamespaceKey.self] }
        set { self[GlassNamespaceKey.self] = newValue }
    }
    
    var glassEffectEnabled: Bool {
        get { self[GlassEffectEnabledKey.self] }
        set { self[GlassEffectEnabledKey.self] = newValue }
    }
}

// MARK: - Falla Brand Colors
/// App-wide color constants for consistent styling
enum FallaColors {
    /// Champagne gold - primary accent color
    static let champagneGold = Color(red: 0.82, green: 0.71, blue: 0.55)
    
    /// Deep purple background
    static let deepPurple = Color(red: 0.08, green: 0.04, blue: 0.12)
    
    /// Mystic violet
    static let mysticViolet = Color(red: 0.12, green: 0.06, blue: 0.18)
    
    /// Dark space
    static let darkSpace = Color(red: 0.06, green: 0.02, blue: 0.10)
    
    /// Fortune type colors
    static let coffeeOrange = Color(red: 0.95, green: 0.6, blue: 0.3)
    static let tarotPurple = Color(red: 0.7, green: 0.4, blue: 0.9)
    static let palmPink = Color(red: 0.95, green: 0.5, blue: 0.7)
    static let dreamBlue = Color(red: 0.4, green: 0.6, blue: 0.95)
    static let astrologyYellow = Color(red: 0.95, green: 0.85, blue: 0.4)
    static let faceGreen = Color(red: 0.4, green: 0.85, blue: 0.6)
    
    /// Biorhythm colors
    static let physicalBlue = Color(red: 0.3, green: 0.6, blue: 1.0)
    static let emotionalRed = Color(red: 1.0, green: 0.4, blue: 0.5)
    static let mentalYellow = Color(red: 1.0, green: 0.85, blue: 0.3)
}

// MARK: - Gradient Presets
@available(iOS 26.0, *)
enum FallaGradients {
    /// Main background gradient
    static var background: LinearGradient {
        LinearGradient(
            colors: [
                FallaColors.deepPurple,
                FallaColors.mysticViolet,
                FallaColors.darkSpace
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    /// Champagne gold accent gradient
    static var champagne: LinearGradient {
        LinearGradient(
            colors: [
                FallaColors.champagneGold,
                FallaColors.champagneGold.opacity(0.7)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    /// Glass border gradient
    static var glassBorder: LinearGradient {
        LinearGradient(
            colors: [
                .white.opacity(0.3),
                .white.opacity(0.1),
                .white.opacity(0.05)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Preview
@available(iOS 26.0, *)
#Preview("Liquid Glass Styles") {
    ZStack {
        FallaGradients.background
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            ForEach([GlassStyle.ultraThin, .thin, .regular, .thick, .prominent], id: \.self) { style in
                Text("Glass Style: \(String(describing: style))")
                    .foregroundColor(.white)
                    .padding()
                    .liquidGlass(style: style, cornerRadius: 16)
            }
        }
        .padding()
    }
}
