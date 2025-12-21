// BlobInteractionModifier.swift
// Falla - iOS 26 Fortune Telling App
// Gesture handler for elastic blob interactions

import SwiftUI

// MARK: - Blob Interaction Modifier
/// View modifier that adds elastic blob interaction behavior
struct BlobInteractionModifier: ViewModifier {
    // MARK: - Configuration
    let stretchSensitivity: CGFloat
    let springResponse: CGFloat
    let springDamping: CGFloat
    let enableHaptics: Bool
    
    // MARK: - State
    @State private var stretchFactor: CGFloat = 1.0
    @State private var dragOffset: CGPoint = .zero
    @State private var isPressed: Bool = false
    @State private var pressScale: CGFloat = 1.0
    
    // MARK: - Initialization
    init(
        stretchSensitivity: CGFloat = 0.015,
        springResponse: CGFloat = 0.4,
        springDamping: CGFloat = 0.65,
        enableHaptics: Bool = true
    ) {
        self.stretchSensitivity = stretchSensitivity
        self.springResponse = springResponse
        self.springDamping = springDamping
        self.enableHaptics = enableHaptics
    }
    
    // MARK: - Body
    func body(content: Content) -> some View {
        content
            .scaleEffect(pressScale)
            .offset(x: dragOffset.x * 0.1, y: dragOffset.y * 0.1)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDragChanged(value)
                    }
                    .onEnded { _ in
                        handleDragEnded()
                    }
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.1)
                    .onChanged { _ in
                        handlePressStarted()
                    }
                    .onEnded { _ in
                        handlePressEnded()
                    }
            )
    }
    
    // MARK: - Gesture Handlers
    
    private func handleDragChanged(_ value: DragGesture.Value) {
        let translation = value.translation
        let velocity = sqrt(pow(translation.width, 2) + pow(translation.height, 2))
        
        // Update drag offset with dampening
        withAnimation(.interactiveSpring(response: 0.1)) {
            dragOffset = CGPoint(x: translation.width, y: translation.height)
            stretchFactor = 1.0 + min(velocity * stretchSensitivity, 0.2)
        }
    }
    
    private func handleDragEnded() {
        // Spring back to original position
        withAnimation(.spring(response: springResponse, dampingFraction: springDamping)) {
            dragOffset = .zero
            stretchFactor = 1.0
        }
        
        if enableHaptics {
            let generator = UIImpactFeedbackGenerator(style: .soft)
            generator.impactOccurred(intensity: 0.5)
        }
    }
    
    private func handlePressStarted() {
        if !isPressed {
            isPressed = true
            
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                pressScale = 0.96
            }
            
            if enableHaptics {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }
    }
    
    private func handlePressEnded() {
        isPressed = false
        
        withAnimation(.spring(response: springResponse, dampingFraction: springDamping)) {
            pressScale = 1.0
        }
    }
}

// MARK: - View Extension
extension View {
    /// Apply elastic blob interaction behavior
    func elasticInteraction(
        stretchSensitivity: CGFloat = 0.015,
        springResponse: CGFloat = 0.4,
        springDamping: CGFloat = 0.65,
        enableHaptics: Bool = true
    ) -> some View {
        self.modifier(BlobInteractionModifier(
            stretchSensitivity: stretchSensitivity,
            springResponse: springResponse,
            springDamping: springDamping,
            enableHaptics: enableHaptics
        ))
    }
}

// MARK: - Elastic Scale Modifier
/// Simple scale-based elastic interaction
struct ElasticScaleModifier: ViewModifier {
    let pressScale: CGFloat
    let releaseScale: CGFloat
    let springResponse: CGFloat
    let springDamping: CGFloat
    
    @State private var scale: CGFloat = 1.0
    
    init(
        pressScale: CGFloat = 0.95,
        releaseScale: CGFloat = 1.02,
        springResponse: CGFloat = 0.3,
        springDamping: CGFloat = 0.6
    ) {
        self.pressScale = pressScale
        self.releaseScale = releaseScale
        self.springResponse = springResponse
        self.springDamping = springDamping
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        withAnimation(.spring(response: 0.15, dampingFraction: 0.8)) {
                            scale = pressScale
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: springResponse, dampingFraction: springDamping)) {
                            scale = releaseScale
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.spring(response: springResponse, dampingFraction: springDamping)) {
                                scale = 1.0
                            }
                        }
                    }
            )
    }
}

extension View {
    /// Apply elastic scale effect on press
    func elasticScale(
        pressScale: CGFloat = 0.95,
        releaseScale: CGFloat = 1.02,
        springResponse: CGFloat = 0.3,
        springDamping: CGFloat = 0.6
    ) -> some View {
        self.modifier(ElasticScaleModifier(
            pressScale: pressScale,
            releaseScale: releaseScale,
            springResponse: springResponse,
            springDamping: springDamping
        ))
    }
}

// MARK: - Stretchy Press Modifier
/// Modifier that stretches content toward press location
struct StretchyPressModifier: ViewModifier {
    @State private var pressLocation: CGPoint?
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let location = value.location
                            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            
                            let dx = (location.x - center.x) * 0.05
                            let dy = (location.y - center.y) * 0.05
                            
                            withAnimation(.interactiveSpring(response: 0.1)) {
                                scale = 0.97
                                offset = CGSize(width: dx, height: dy)
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                                scale = 1.0
                                offset = .zero
                            }
                        }
                )
        }
    }
}

extension View {
    /// Apply stretchy press effect toward touch location
    func stretchyPress() -> some View {
        self.modifier(StretchyPressModifier())
    }
}
