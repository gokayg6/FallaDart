// SpringAnimation.swift
// Falla - iOS 26 Fortune Telling App
// Apple-standard spring animations and motion utilities

import SwiftUI

// MARK: - Falla Animations
/// Predefined animations for consistent motion language
enum FallaAnimation {
    // MARK: - Spring Animations
    
    /// Standard spring for most interactions
    static let standard = Animation.spring(response: 0.4, dampingFraction: 0.75)
    
    /// Quick spring for small interactions
    static let quick = Animation.spring(response: 0.25, dampingFraction: 0.8)
    
    /// Bouncy spring for playful elements
    static let bouncy = Animation.spring(response: 0.35, dampingFraction: 0.5)
    
    /// Slow spring for large transitions
    static let slow = Animation.spring(response: 0.6, dampingFraction: 0.8)
    
    /// Elastic spring with overshoot
    static let elastic = Animation.spring(response: 0.5, dampingFraction: 0.4)
    
    /// Snappy spring for immediate feedback
    static let snappy = Animation.spring(response: 0.2, dampingFraction: 0.9)
    
    // MARK: - Ease Animations
    
    /// Smooth ease for opacity changes
    static let fadeIn = Animation.easeOut(duration: 0.25)
    static let fadeOut = Animation.easeIn(duration: 0.2)
    
    /// Slide transitions
    static let slideIn = Animation.easeOut(duration: 0.35)
    static let slideOut = Animation.easeIn(duration: 0.25)
    
    // MARK: - Special Animations
    
    /// Blob stretch and return
    static let blobStretch = Animation.spring(response: 0.4, dampingFraction: 0.65)
    
    /// Glass morph transition
    static let glassMorph = Animation.spring(response: 0.5, dampingFraction: 0.7)
    
    /// Icon symbol replacement
    static let symbolReplace = Animation.spring(response: 0.3, dampingFraction: 0.7)
    
    /// Navigation tab switch
    static let tabSwitch = Animation.spring(response: 0.35, dampingFraction: 0.75)
    
    /// Card flip animation
    static let cardFlip = Animation.spring(response: 0.6, dampingFraction: 0.7)
}

// MARK: - Animation Durations
enum FallaDuration {
    static let instant: Double = 0.1
    static let fast: Double = 0.2
    static let normal: Double = 0.35
    static let slow: Double = 0.5
    static let extraSlow: Double = 0.8
}

// MARK: - Timing Curves
enum FallaCurve {
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.75)
    static let easeOut = Animation.easeOut(duration: 0.35)
    static let easeIn = Animation.easeIn(duration: 0.25)
    static let easeInOut = Animation.easeInOut(duration: 0.35)
}

// MARK: - Animated Value Wrapper
/// Property wrapper for automatically animated state changes
@propertyWrapper
struct Animated<Value: Equatable>: DynamicProperty {
    @State private var value: Value
    private let animation: Animation
    
    var wrappedValue: Value {
        get { value }
        nonmutating set {
            withAnimation(animation) {
                value = newValue
            }
        }
    }
    
    var projectedValue: Binding<Value> {
        Binding(
            get: { value },
            set: { newValue in
                withAnimation(animation) {
                    value = newValue
                }
            }
        )
    }
    
    init(wrappedValue: Value, animation: Animation = FallaAnimation.standard) {
        self._value = State(initialValue: wrappedValue)
        self.animation = animation
    }
}

// MARK: - Reduce Motion Support
/// Environment key for reduce motion preference
private struct ReduceMotionKey: EnvironmentKey {
    static let defaultValue: Bool = UIAccessibility.isReduceMotionEnabled
}

extension EnvironmentValues {
    var reduceMotion: Bool {
        get { self[ReduceMotionKey.self] }
        set { self[ReduceMotionKey.self] = newValue }
    }
}

// MARK: - Reduce Motion Modifier
/// View modifier that respects reduce motion preference
struct ReduceMotionModifier: ViewModifier {
    @Environment(\.reduceMotion) private var reduceMotion
    
    let fullAnimation: Animation
    let reducedAnimation: Animation
    
    init(
        fullAnimation: Animation = FallaAnimation.standard,
        reducedAnimation: Animation = .linear(duration: 0.1)
    ) {
        self.fullAnimation = fullAnimation
        self.reducedAnimation = reducedAnimation
    }
    
    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? reducedAnimation : fullAnimation, value: UUID())
    }
}

extension View {
    /// Apply animation that respects reduce motion
    func fallaAnimation(_ animation: Animation = FallaAnimation.standard) -> some View {
        self.modifier(ReduceMotionModifier(fullAnimation: animation))
    }
    
    /// Conditionally apply animation based on reduce motion
    func accessibleAnimation<V: Equatable>(_ animation: Animation, value: V) -> some View {
        self.modifier(AccessibleAnimationModifier(animation: animation, value: value))
    }
}

private struct AccessibleAnimationModifier<V: Equatable>: ViewModifier {
    @Environment(\.reduceMotion) private var reduceMotion
    let animation: Animation
    let value: V
    
    func body(content: Content) -> some View {
        content
            .animation(reduceMotion ? .none : animation, value: value)
    }
}

// MARK: - Matched Geometry Animation
/// Helper for matched geometry transitions
struct MatchedGeometryNamespace {
    static let card = "card"
    static let icon = "icon"
    static let title = "title"
    static let image = "image"
    static let background = "background"
}

// MARK: - Staggered Animation
/// Utility for staggered list animations
struct StaggeredAnimation {
    /// Calculate delay for item at index
    static func delay(for index: Int, baseDelay: Double = 0.05, maxDelay: Double = 0.5) -> Double {
        min(Double(index) * baseDelay, maxDelay)
    }
    
    /// Apply staggered animation to a list of items
    static func stagger<T>(items: [T], baseDelay: Double = 0.05) -> [(T, Double)] {
        items.enumerated().map { index, item in
            (item, delay(for: index, baseDelay: baseDelay))
        }
    }
}

// MARK: - View Extension for Staggered Animation
extension View {
    /// Apply staggered appear animation
    func staggeredAppear(index: Int, baseDelay: Double = 0.05) -> some View {
        self
            .opacity(0)
            .offset(y: 20)
            .onAppear {
                withAnimation(FallaAnimation.standard.delay(StaggeredAnimation.delay(for: index, baseDelay: baseDelay))) {
                    // Animation will be applied by the wrapper
                }
            }
    }
}

// MARK: - Shake Animation
/// Shake animation for error states
extension View {
    func shake(trigger: Bool) -> some View {
        self.modifier(ShakeModifier(trigger: trigger))
    }
}

private struct ShakeModifier: ViewModifier {
    let trigger: Bool
    @State private var shakeOffset: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(x: shakeOffset)
            .onChange(of: trigger) { oldValue, newValue in
                if newValue {
                    withAnimation(.linear(duration: 0.06).repeatCount(5, autoreverses: true)) {
                        shakeOffset = 8
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        shakeOffset = 0
                    }
                }
            }
    }
}

// MARK: - Pulse Animation
/// Pulsing animation for loading/attention states
extension View {
    func pulse(isActive: Bool, scale: CGFloat = 1.05, duration: Double = 1.0) -> some View {
        self.modifier(PulseModifier(isActive: isActive, scale: scale, duration: duration))
    }
}

private struct PulseModifier: ViewModifier {
    let isActive: Bool
    let scale: CGFloat
    let duration: Double
    
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? scale : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .onAppear {
                if isActive {
                    withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                }
            }
            .onChange(of: isActive) { oldValue, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPulsing = false
                    }
                }
            }
    }
}
