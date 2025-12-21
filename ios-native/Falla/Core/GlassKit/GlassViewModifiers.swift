// GlassViewModifiers.swift
// Falla - iOS 26 Fortune Telling App
// Reusable view modifiers for Liquid Glass styling

import SwiftUI

// MARK: - Glass Card Style Modifier
/// Applies consistent glass card styling with iOS 26 Liquid Glass
@available(iOS 26.0, *)
struct GlassCardStyleModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tintColor: Color
    let intensity: GlassStyle
    let shadowRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius))
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(tintColor.opacity(intensity.tintOpacity))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        .white.opacity(intensity.borderOpacity),
                                        .white.opacity(intensity.borderOpacity * 0.4),
                                        .white.opacity(intensity.borderOpacity * 0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
            }
            .shadow(color: .black.opacity(0.12), radius: shadowRadius, x: 0, y: shadowRadius / 2)
    }
}

// MARK: - Glass Circle Button Modifier
/// Applies circular glass button styling
@available(iOS 26.0, *)
struct GlassCircleButtonModifier: ViewModifier {
    let size: CGFloat
    let isActive: Bool
    let activeColor: Color
    
    func body(content: Content) -> some View {
        content
            .frame(width: size, height: size)
            .background {
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
            }
    }
}

// MARK: - Action Icon Modifier
/// Styles icons with active/inactive states and animations
@available(iOS 26.0, *)
struct ActionIconModifier: ViewModifier {
    let isActive: Bool
    let activeColor: Color
    let inactiveColor: Color
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(isActive ? activeColor : inactiveColor)
            .contentTransition(.symbolEffect(.replace.downUp.byLayer))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isActive)
    }
}

// MARK: - Floating Shadow Modifier
/// Adds a subtle floating shadow effect for depth
struct FloatingShadowModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let offset: CGPoint
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color, radius: radius, x: offset.x, y: offset.y)
    }
}

// MARK: - Depth Hover Effect Modifier
/// Adds 3D parallax effect on press/hover for depth perception
@available(iOS 26.0, *)
struct DepthHoverEffectModifier: ViewModifier {
    @State private var isHovered = false
    
    let depth: CGFloat
    
    func body(content: Content) -> some View {
        content
            .rotation3DEffect(
                .degrees(isHovered ? 2 : 0),
                axis: (x: -1, y: 1, z: 0),
                perspective: 0.5
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .shadow(
                color: .black.opacity(isHovered ? 0.2 : 0.1),
                radius: isHovered ? 20 : 10,
                x: 0,
                y: isHovered ? 15 : 5
            )
            .onHover { hovering in
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isHovered = hovering
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                            isHovered = true
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isHovered = false
                        }
                    }
            )
    }
}

// MARK: - Elastic Scale Modifier
/// Spring-based press feedback for interactive elements
struct ElasticScaleModifier: ViewModifier {
    let scale: CGFloat
    let response: Double
    let dampingFraction: Double
    
    @State private var isPressed = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(.spring(response: response, dampingFraction: dampingFraction), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

// MARK: - Shimmer Effect Modifier
/// Adds a shimmering highlight animation
struct ShimmerEffectModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    let duration: Double
    let delay: Double
    
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width / 2)
                    .offset(x: -geometry.size.width / 2 + (geometry.size.width * 1.5 * phase))
                    .clipped()
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
            }
    }
}

// MARK: - Glow Effect Modifier
/// Adds a colored glow around elements
struct GlowEffectModifier: ViewModifier {
    let color: Color
    let radius: CGFloat
    let opacity: Double
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(opacity), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(opacity * 0.5), radius: radius * 2, x: 0, y: 0)
    }
}

// MARK: - Staggered Animation Modifier
/// Applies staggered animation delay based on index
struct StaggeredAnimationModifier: ViewModifier {
    let index: Int
    let baseDelay: Double
    let animation: Animation
    
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .scaleEffect(isVisible ? 1 : 0.95)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * baseDelay) {
                    withAnimation(animation) {
                        isVisible = true
                    }
                }
            }
    }
}

// MARK: - Pulsing Glow Modifier
/// Creates a pulsing glow animation
struct PulsingGlowModifier: ViewModifier {
    let color: Color
    let minOpacity: Double
    let maxOpacity: Double
    let duration: Double
    
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .shadow(
                color: color.opacity(isPulsing ? maxOpacity : minOpacity),
                radius: isPulsing ? 20 : 10,
                x: 0,
                y: 0
            )
            .onAppear {
                withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

// MARK: - View Extensions
@available(iOS 26.0, *)
extension View {
    /// Apply glass card styling
    func glassCardStyle(
        cornerRadius: CGFloat = 24,
        tintColor: Color = .white,
        intensity: GlassStyle = .regular,
        shadowRadius: CGFloat = 20
    ) -> some View {
        self.modifier(GlassCardStyleModifier(
            cornerRadius: cornerRadius,
            tintColor: tintColor,
            intensity: intensity,
            shadowRadius: shadowRadius
        ))
    }
    
    /// Apply circular glass button styling
    func glassCircleButton(
        size: CGFloat = 44,
        isActive: Bool = false,
        activeColor: Color = FallaColors.champagneGold
    ) -> some View {
        self.modifier(GlassCircleButtonModifier(
            size: size,
            isActive: isActive,
            activeColor: activeColor
        ))
    }
    
    /// Apply action icon styling with state
    func actionIcon(
        isActive: Bool,
        activeColor: Color = FallaColors.champagneGold,
        inactiveColor: Color = .white.opacity(0.6)
    ) -> some View {
        self.modifier(ActionIconModifier(
            isActive: isActive,
            activeColor: activeColor,
            inactiveColor: inactiveColor
        ))
    }
    
    /// Apply floating shadow effect
    func floatingShadow(
        color: Color = .black.opacity(0.15),
        radius: CGFloat = 20,
        offset: CGPoint = CGPoint(x: 0, y: 10)
    ) -> some View {
        self.modifier(FloatingShadowModifier(
            color: color,
            radius: radius,
            offset: offset
        ))
    }
    
    /// Apply depth hover effect
    func depthHoverEffect(depth: CGFloat = 5) -> some View {
        self.modifier(DepthHoverEffectModifier(depth: depth))
    }
    
    /// Apply elastic scale on press
    func elasticScale(
        scale: CGFloat = 0.96,
        response: Double = 0.25,
        dampingFraction: Double = 0.7
    ) -> some View {
        self.modifier(ElasticScaleModifier(
            scale: scale,
            response: response,
            dampingFraction: dampingFraction
        ))
    }
    
    /// Apply shimmer effect
    func shimmer(duration: Double = 2.0, delay: Double = 0) -> some View {
        self.modifier(ShimmerEffectModifier(duration: duration, delay: delay))
    }
    
    /// Apply glow effect
    func glow(
        color: Color = .white,
        radius: CGFloat = 10,
        opacity: Double = 0.5
    ) -> some View {
        self.modifier(GlowEffectModifier(
            color: color,
            radius: radius,
            opacity: opacity
        ))
    }
    
    /// Apply staggered animation
    func staggeredAnimation(
        index: Int,
        baseDelay: Double = 0.05,
        animation: Animation = .spring(response: 0.4, dampingFraction: 0.8)
    ) -> some View {
        self.modifier(StaggeredAnimationModifier(
            index: index,
            baseDelay: baseDelay,
            animation: animation
        ))
    }
    
    /// Apply pulsing glow animation
    func pulsingGlow(
        color: Color = FallaColors.champagneGold,
        minOpacity: Double = 0.2,
        maxOpacity: Double = 0.5,
        duration: Double = 1.5
    ) -> some View {
        self.modifier(PulsingGlowModifier(
            color: color,
            minOpacity: minOpacity,
            maxOpacity: maxOpacity,
            duration: duration
        ))
    }
}

// MARK: - Conditional Modifier
extension View {
    /// Apply modifier conditionally
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Apply modifier conditionally with else clause
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
}

// MARK: - Previews
@available(iOS 26.0, *)
#Preview("Glass Modifiers") {
    ZStack {
        FallaGradients.background
            .ignoresSafeArea()
        
        VStack(spacing: 24) {
            // Glass card style
            Text("Glass Card Style")
                .foregroundColor(.white)
                .padding()
                .glassCardStyle()
            
            // Depth hover effect
            Text("Depth Hover Effect")
                .foregroundColor(.white)
                .padding()
                .glassCardStyle()
                .depthHoverEffect()
            
            // Glow effect
            Circle()
                .fill(FallaColors.champagneGold)
                .frame(width: 60, height: 60)
                .pulsingGlow()
            
            // Shimmer effect
            Text("Shimmer Effect")
                .foregroundColor(.white)
                .padding()
                .glassCardStyle()
                .shimmer()
        }
        .padding()
    }
}
