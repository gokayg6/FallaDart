// GlassComponents.swift
// Falla - iOS 26 Fortune Telling App
// Reusable Liquid Glass UI components

import SwiftUI

// MARK: - Glass Card
/// A versatile glass card container with iOS 26 Liquid Glass effect
/// Supports custom content, tint colors, and coordinated transitions
@available(iOS 26.0, *)
struct GlassCard<Content: View>: View {
    // MARK: - Properties
    let cornerRadius: CGFloat
    let padding: CGFloat
    let tintColor: Color
    let glassID: String?
    let content: Content
    
    // MARK: - Initialization
    init(
        cornerRadius: CGFloat = 24,
        padding: CGFloat = 16,
        tintColor: Color = .white,
        glassID: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.tintColor = tintColor
        self.glassID = glassID
        self.content = content()
    }
    
    // MARK: - Body
    var body: some View {
        content
            .padding(padding)
            .background {
                // iOS 26 Native Liquid Glass
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .glassEffect(
                        .regular,
                        in: RoundedRectangle(cornerRadius: cornerRadius)
                    )
                    .overlay {
                        // Subtle tint for branding
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(tintColor.opacity(0.08))
                    }
                    .overlay {
                        // Glass edge highlight
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(0.25),
                                        .white.opacity(0.1),
                                        .white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
            }
            // Subtle floating shadow for depth
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
            // Apply glass effect ID if provided
            .modifier(OptionalGlassID(id: glassID))
    }
}

// MARK: - Glass Icon Button
/// Circular glass button with icon and animation states
@available(iOS 26.0, *)
struct GlassIconButton: View {
    // MARK: - Properties
    let icon: String
    let activeIcon: String?
    let isActive: Bool
    let size: CGFloat
    let activeColor: Color
    let action: () -> Void
    
    // MARK: - State
    @State private var isPressed = false
    
    // MARK: - Initialization
    init(
        icon: String,
        activeIcon: String? = nil,
        isActive: Bool = false,
        size: CGFloat = 44,
        activeColor: Color = FallaColors.champagneGold,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.activeIcon = activeIcon
        self.isActive = isActive
        self.size = size
        self.activeColor = activeColor
        self.action = action
    }
    
    // MARK: - Body
    var body: some View {
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            ZStack {
                // Glass background
                Circle()
                    .fill(.ultraThinMaterial)
                    .glassEffect(.regular, in: Circle())
                    .overlay {
                        Circle()
                            .fill(isActive ? activeColor.opacity(0.2) : Color.clear)
                    }
                    .overlay {
                        Circle()
                            .strokeBorder(
                                isActive
                                    ? activeColor.opacity(0.5)
                                    : Color.white.opacity(0.2),
                                lineWidth: 0.5
                            )
                    }
                
                // Icon with symbol effect transition
                Image(systemName: isActive ? (activeIcon ?? icon) : icon)
                    .font(.system(size: size * 0.45, weight: .medium))
                    .foregroundColor(isActive ? activeColor : .white.opacity(0.8))
                    .contentTransition(.symbolEffect(.replace.downUp.byLayer))
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(ElasticButtonStyle())
    }
}

// MARK: - Glass Progress Ring
/// Circular progress indicator with glass effect fill
/// Used for biorhythm display and loading states
@available(iOS 26.0, *)
struct GlassProgressRing: View {
    // MARK: - Properties
    let progress: Double // 0.0 to 1.0
    let lineWidth: CGFloat
    let size: CGFloat
    let color: Color
    let showValue: Bool
    let label: String?
    
    // MARK: - Animation
    @State private var animatedProgress: Double = 0
    
    // MARK: - Initialization
    init(
        progress: Double,
        lineWidth: CGFloat = 12,
        size: CGFloat = 120,
        color: Color = FallaColors.champagneGold,
        showValue: Bool = true,
        label: String? = nil
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
        self.color = color
        self.showValue = showValue
        self.label = label
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background ring with glass effect
            Circle()
                .stroke(
                    Color.white.opacity(0.1),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .glassEffect(.thin, in: Circle())
            
            // Progress arc with gradient
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    AngularGradient(
                        colors: [
                            color.opacity(0.3),
                            color,
                            color.opacity(0.8)
                        ],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: color.opacity(0.5), radius: 8, x: 0, y: 0)
            
            // Center content
            VStack(spacing: 4) {
                if showValue {
                    Text("\(Int(animatedProgress * 100))")
                        .font(.system(size: size * 0.25, weight: .light, design: .rounded))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                }
                
                if let label = label {
                    Text(label)
                        .font(.system(size: size * 0.1, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            // Animate to target progress on appear
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            // Animate progress changes smoothly
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animatedProgress = newValue
            }
        }
    }
}

// MARK: - Glass Grid Item
/// Grid cell for fortune type selection with glass effect
@available(iOS 26.0, *)
struct GlassGridItem: View {
    // MARK: - Properties
    let icon: String
    let title: String
    let subtitle: String?
    let accentColor: Color
    let karmaCost: Int?
    let action: () -> Void
    
    // MARK: - Body
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // Icon with accent background
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.2))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: icon)
                            .font(.system(size: 20))
                            .foregroundColor(accentColor)
                    }
                    
                    Spacer()
                    
                    // Karma cost badge
                    if let cost = karmaCost, cost > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10))
                            Text("\(cost)")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(FallaColors.champagneGold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background {
                            Capsule()
                                .fill(FallaColors.champagneGold.opacity(0.15))
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                            .lineLimit(1)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(accentColor.opacity(0.05))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        accentColor.opacity(0.3),
                                        accentColor.opacity(0.1),
                                        .white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
            }
            .shadow(color: accentColor.opacity(0.2), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(ElasticButtonStyle())
    }
}

// MARK: - Glass History Row
/// List row for fortune history with glass effect and color coding
@available(iOS 26.0, *)
struct GlassHistoryRow: View {
    // MARK: - Properties
    let icon: String
    let title: String
    let subtitle: String
    let timestamp: String
    let accentColor: Color
    let isFavorite: Bool
    let action: () -> Void
    
    // MARK: - Body
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 14) {
                // Icon with colored glass background
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                        .glassEffect(.thin, in: RoundedRectangle(cornerRadius: 14))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            accentColor.opacity(0.4),
                                            accentColor.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }
                .frame(width: 50, height: 50)
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        if isFavorite {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 12))
                                .foregroundColor(FallaColors.emotionalRed)
                        }
                    }
                    
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Timestamp and chevron
                VStack(alignment: .trailing, spacing: 4) {
                    Text(timestamp)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
                    .glassEffect(.thin, in: RoundedRectangle(cornerRadius: 18))
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        accentColor.opacity(0.2),
                                        .white.opacity(0.1)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 0.5
                            )
                    }
            }
        }
        .buttonStyle(ElasticButtonStyle())
    }
}

// MARK: - Glass Filter Chip
/// Selectable filter chip with glass effect for list filtering
@available(iOS 26.0, *)
struct GlassFilterChip: View {
    // MARK: - Properties
    let title: String
    let icon: String?
    let isSelected: Bool
    let accentColor: Color
    let action: () -> Void
    
    // MARK: - Body
    var body: some View {
        Button(action: {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            action()
        }) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                }
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.7))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .glassEffect(.thin, in: Capsule())
                    .overlay {
                        Capsule()
                            .fill(isSelected ? accentColor.opacity(0.3) : Color.clear)
                    }
                    .overlay {
                        Capsule()
                            .strokeBorder(
                                isSelected
                                    ? accentColor.opacity(0.5)
                                    : Color.white.opacity(0.15),
                                lineWidth: isSelected ? 1 : 0.5
                            )
                    }
            }
            .shadow(
                color: isSelected ? accentColor.opacity(0.3) : .clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(ElasticButtonStyle(scale: 0.97))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Glass Action Cluster
/// Grouped action buttons with glass effect container
@available(iOS 26.0, *)
struct GlassActionCluster: View {
    // MARK: - Properties
    let actions: [ClusterAction]
    let orientation: Axis
    
    struct ClusterAction: Identifiable {
        let id = UUID()
        let icon: String
        let label: String?
        let color: Color
        let action: () -> Void
    }
    
    // MARK: - Initialization
    init(
        orientation: Axis = .horizontal,
        actions: [ClusterAction]
    ) {
        self.orientation = orientation
        self.actions = actions
    }
    
    // MARK: - Body
    var body: some View {
        Group {
            if orientation == .horizontal {
                HStack(spacing: 12) {
                    actionButtons
                }
            } else {
                VStack(spacing: 12) {
                    actionButtons
                }
            }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            Color.white.opacity(0.15),
                            lineWidth: 0.5
                        )
                }
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        ForEach(actions) { action in
            Button {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                action.action()
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: action.icon)
                        .font(.system(size: 20))
                        .foregroundColor(action.color)
                    
                    if let label = action.label {
                        Text(label)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .frame(minWidth: 50)
            }
            .buttonStyle(ElasticButtonStyle())
        }
    }
}

// MARK: - Stateful Action Button
/// Button with animated state changes (like, save, favorite)
@available(iOS 26.0, *)
struct GlassStatefulButton: View {
    // MARK: - Properties
    let icon: String
    let activeIcon: String
    @Binding var isActive: Bool
    let activeColor: Color
    let label: String?
    
    // MARK: - State
    @State private var animationTrigger = false
    
    // MARK: - Body
    var body: some View {
        Button {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: isActive ? .light : .medium)
            generator.impactOccurred()
            
            // Toggle state with animation
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isActive.toggle()
                animationTrigger.toggle()
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    // Glow effect when active
                    if isActive {
                        Circle()
                            .fill(activeColor.opacity(0.3))
                            .blur(radius: 10)
                            .frame(width: 50, height: 50)
                    }
                    
                    Image(systemName: isActive ? activeIcon : icon)
                        .font(.system(size: 24))
                        .foregroundColor(isActive ? activeColor : .white.opacity(0.6))
                        .contentTransition(.symbolEffect(.replace.downUp.byLayer))
                        .scaleEffect(animationTrigger ? 1.2 : 1.0)
                        .animation(.spring(response: 0.25, dampingFraction: 0.5), value: animationTrigger)
                }
                .frame(width: 44, height: 44)
                
                if let label = label {
                    Text(label)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(isActive ? activeColor : .white.opacity(0.6))
                }
            }
        }
        .buttonStyle(ElasticButtonStyle())
    }
}

// MARK: - Helper Modifiers

/// Optional glass ID modifier
@available(iOS 26.0, *)
private struct OptionalGlassID: ViewModifier {
    let id: String?
    @Environment(\.glassNamespace) private var namespace
    
    func body(content: Content) -> some View {
        if let id = id, let namespace = namespace {
            content.glassEffectID(id, in: namespace)
        } else {
            content
        }
    }
}

/// Elastic scale button style for press feedback
struct ElasticButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.96
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Previews
@available(iOS 26.0, *)
#Preview("Glass Components") {
    ZStack {
        FallaGradients.background
            .ignoresSafeArea()
        
        ScrollView {
            VStack(spacing: 24) {
                // Glass Card
                GlassCard {
                    Text("Glass Card Example")
                        .foregroundColor(.white)
                }
                
                // Glass Icon Buttons
                HStack(spacing: 16) {
                    GlassIconButton(icon: "heart", activeIcon: "heart.fill", isActive: false) {}
                    GlassIconButton(icon: "heart", activeIcon: "heart.fill", isActive: true) {}
                    GlassIconButton(icon: "bookmark", isActive: false) {}
                }
                
                // Glass Progress Ring
                GlassProgressRing(
                    progress: 0.72,
                    color: FallaColors.physicalBlue,
                    label: "Fiziksel"
                )
                
                // Glass Grid Items
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    GlassGridItem(
                        icon: "cup.and.saucer.fill",
                        title: "Kahve Falı",
                        subtitle: nil,
                        accentColor: FallaColors.coffeeOrange,
                        karmaCost: 5
                    ) {}
                    
                    GlassGridItem(
                        icon: "rectangle.stack.fill",
                        title: "Tarot",
                        subtitle: nil,
                        accentColor: FallaColors.tarotPurple,
                        karmaCost: 8
                    ) {}
                }
                
                // Glass Filter Chips
                HStack(spacing: 8) {
                    GlassFilterChip(title: "Tümü", icon: "checkmark", isSelected: true, accentColor: FallaColors.champagneGold) {}
                    GlassFilterChip(title: "Tarot", icon: nil, isSelected: false, accentColor: FallaColors.tarotPurple) {}
                    GlassFilterChip(title: "Kahve", icon: nil, isSelected: false, accentColor: FallaColors.coffeeOrange) {}
                }
                
                // Glass History Row
                GlassHistoryRow(
                    icon: "cup.and.saucer.fill",
                    title: "Kahve Falı",
                    subtitle: "Genel yorum",
                    timestamp: "Dün",
                    accentColor: FallaColors.coffeeOrange,
                    isFavorite: true
                ) {}
            }
            .padding()
        }
    }
}
