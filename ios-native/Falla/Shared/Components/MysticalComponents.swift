// MysticalComponents.swift
// Falla - iOS 26 Fortune Telling App
// Reusable mystical UI components matching Flutter widgets

import SwiftUI

// MARK: - Mystical Button
/// Mystical-themed button with gradient and glow effects
struct MysticalButton: View {
    let title: String
    let icon: String?
    let style: MysticalButtonStyle
    let isLoading: Bool
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        style: MysticalButtonStyle = .primary,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.textColor))
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                    }
                    
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(style.background)
            .foregroundColor(style.textColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(style.borderGradient, lineWidth: style.borderWidth)
            }
            .shadow(color: style.shadowColor, radius: 10, x: 0, y: 5)
        }
        .disabled(isLoading)
        .elasticScale()
    }
}

// MARK: - Mystical Button Styles
enum MysticalButtonStyle {
    case primary
    case secondary
    case glass
    case danger
    
    var background: some ShapeStyle {
        switch self {
        case .primary:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 0.82, green: 0.71, blue: 0.55),
                        Color(red: 0.7, green: 0.55, blue: 0.4)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        case .secondary:
            return AnyShapeStyle(Color.white.opacity(0.1))
        case .glass:
            return AnyShapeStyle(Color.white.opacity(0.05))
        case .danger:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.red.opacity(0.8), .red.opacity(0.6)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
    }
    
    var textColor: Color {
        switch self {
        case .primary: return .white
        case .secondary: return .white
        case .glass: return .white
        case .danger: return .white
        }
    }
    
    var borderGradient: LinearGradient {
        switch self {
        case .primary:
            return LinearGradient(
                colors: [
                    Color(red: 0.9, green: 0.8, blue: 0.65).opacity(0.5),
                    Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .secondary, .glass:
            return LinearGradient(
                colors: [.white.opacity(0.2), .white.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .danger:
            return LinearGradient(
                colors: [.red.opacity(0.5), .red.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .primary: return 0
        case .secondary, .glass: return 1
        case .danger: return 0
        }
    }
    
    var shadowColor: Color {
        switch self {
        case .primary: return Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.3)
        case .secondary, .glass: return .clear
        case .danger: return .red.opacity(0.3)
        }
    }
}

// MARK: - Mystical Card
/// Mystical-themed card with glass effect
struct MysticalCard<Content: View>: View {
    let cornerRadius: CGFloat
    let padding: CGFloat
    let hasBorder: Bool
    let content: Content
    
    init(
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 20,
        hasBorder: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.hasBorder = hasBorder
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.1),
                                        Color.white.opacity(0.02)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
            }
            .if(hasBorder) { view in
                view.overlay {
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
            .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
    }
}

// MARK: - Mystical Loading
/// Mystical-themed loading indicator
struct MysticalLoading: View {
    let message: String?
    
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.5
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // Outer ring
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            colors: [
                                Color(red: 0.82, green: 0.71, blue: 0.55),
                                Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.3),
                                Color(red: 0.82, green: 0.71, blue: 0.55)
                            ],
                            center: .center
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(rotation))
                
                // Inner sparkle
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
                    .scaleEffect(scale)
                    .opacity(opacity)
            }
            
            if let message = message {
                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
                scale = 1.1
                opacity = 1.0
            }
        }
    }
}

// MARK: - Mystical Dialog
/// Mystical-themed dialog/alert
struct MysticalDialog<Content: View>: View {
    @Binding var isPresented: Bool
    let title: String
    let content: Content
    
    init(
        isPresented: Binding<Bool>,
        title: String,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // Backdrop
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3)) {
                        isPresented = false
                    }
                }
            
            // Dialog
            VStack(spacing: 20) {
                // Title
                Text(title)
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundColor(.white)
                
                // Content
                content
            }
            .padding(24)
            .background {
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(red: 0.1, green: 0.05, blue: 0.15).opacity(0.8))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.4),
                                        Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
            }
            .shadow(color: .black.opacity(0.4), radius: 30, x: 0, y: 15)
            .padding(.horizontal, 40)
            .scaleEffect(isPresented ? 1 : 0.8)
            .opacity(isPresented ? 1 : 0)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isPresented)
    }
}

// MARK: - Karma Badge
/// Badge showing karma cost
struct KarmaBadge: View {
    let cost: Int
    let size: KarmaBadgeSize
    
    enum KarmaBadgeSize {
        case small, medium, large
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            case .large: return 14
            }
        }
        
        var textSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            case .large: return 14
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .medium: return EdgeInsets(top: 6, leading: 10, bottom: 6, trailing: 10)
            case .large: return EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
            }
        }
    }
    
    init(_ cost: Int, size: KarmaBadgeSize = .medium) {
        self.cost = cost
        self.size = size
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "sparkles")
                .font(.system(size: size.iconSize))
            
            Text("\(cost)")
                .font(.system(size: size.textSize, weight: .semibold))
        }
        .foregroundColor(Color(red: 0.82, green: 0.71, blue: 0.55))
        .padding(size.padding)
        .background(
            Capsule()
                .fill(Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.15))
        )
        .overlay {
            Capsule()
                .strokeBorder(
                    Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.3),
                    lineWidth: 0.5
                )
        }
    }
}

// MARK: - Snowfall Overlay
/// Animated snowfall effect overlay
struct SnowfallOverlay: View {
    @State private var flakes: [Snowflake] = []
    
    private struct Snowflake: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var speed: CGFloat
        var opacity: Double
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(flakes) { flake in
                    Circle()
                        .fill(Color.white.opacity(flake.opacity))
                        .frame(width: flake.size, height: flake.size)
                        .position(x: flake.x, y: flake.y)
                        .blur(radius: flake.size > 3 ? 0.5 : 0)
                }
            }
            .onAppear {
                initializeFlakes(in: geometry.size)
                startAnimation(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }
    
    private func initializeFlakes(in size: CGSize) {
        flakes = (0..<30).map { _ in
            Snowflake(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 2...4),
                speed: CGFloat.random(in: 20...50),
                opacity: Double.random(in: 0.3...0.7)
            )
        }
    }
    
    private func startAnimation(in size: CGSize) {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            for i in flakes.indices {
                flakes[i].y += flakes[i].speed * 0.05
                flakes[i].x += sin(flakes[i].y * 0.02) * 0.5
                
                if flakes[i].y > size.height {
                    flakes[i].y = -10
                    flakes[i].x = CGFloat.random(in: 0...size.width)
                }
            }
        }
    }
}

// MARK: - Previews
#Preview("Mystical Button") {
    ZStack {
        Color(red: 0.08, green: 0.04, blue: 0.12)
            .ignoresSafeArea()
        
        VStack(spacing: 16) {
            MysticalButton("Primary Button", icon: "sparkles", style: .primary) {}
            MysticalButton("Secondary Button", style: .secondary) {}
            MysticalButton("Glass Button", style: .glass) {}
            MysticalButton("Loading...", style: .primary, isLoading: true) {}
        }
        .padding()
    }
}

#Preview("Mystical Loading") {
    ZStack {
        Color(red: 0.08, green: 0.04, blue: 0.12)
            .ignoresSafeArea()
        
        MysticalLoading(message: "Falınız hazırlanıyor...")
    }
}

#Preview("Karma Badge") {
    ZStack {
        Color(red: 0.08, green: 0.04, blue: 0.12)
            .ignoresSafeArea()
        
        VStack(spacing: 20) {
            KarmaBadge(5, size: .small)
            KarmaBadge(10, size: .medium)
            KarmaBadge(25, size: .large)
        }
    }
}
