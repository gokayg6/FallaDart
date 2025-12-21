// GlassEffectNavigationBar.swift
// Falla - iOS 26 Fortune Telling App
// Floating Liquid Glass navigation bar with animated blob indicator

import SwiftUI

// MARK: - Glass Navigation Bar
/// iOS 26 Liquid Glass floating navigation bar with morphing blob indicator
/// Uses native .glassEffect() and .glassEffectID() for coordinated transitions
@available(iOS 26.0, *)
struct GlassEffectNavigationBar: View {
    // MARK: - Properties
    @Binding var selectedTab: MainTab
    let tabs: [MainTab]
    let onTabSelected: (MainTab) -> Void
    
    // MARK: - Environment
    @Environment(\.glassNamespace) private var glassNamespace
    
    // MARK: - Animation State
    @State private var blobOffset: CGFloat = 0
    @State private var blobScale: CGFloat = 1.0
    @State private var stretchFactor: CGFloat = 1.0
    @State private var isAnimating = false
    @State private var glowIntensity: CGFloat = 0
    @State private var elasticOffset: CGFloat = 0
    
    // MARK: - Gesture State
    @GestureState private var dragOffset: CGFloat = 0
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            let navbarWidth = geometry.size.width - (TabBarConfiguration.horizontalPadding * 2)
            let itemWidth = navbarWidth / CGFloat(tabs.count)
            
            ZStack {
                // Layer 1: Base Glass Surface with iOS 26 glass effect
                baseGlassLayer
                
                // Layer 2: Animated glow during transitions
                glowOverlay
                
                // Layer 3: Active Liquid Blob with glass effect
                blobLayer(itemWidth: itemWidth)
                
                // Layer 4: Tab Icons and Labels
                iconLayer(itemWidth: itemWidth)
            }
            .frame(height: TabBarConfiguration.height)
            .padding(.horizontal, TabBarConfiguration.horizontalPadding)
            // Elastic gesture response
            .offset(y: elasticOffset)
            .gesture(dragGesture)
            .onAppear {
                calculateBlobPosition(for: selectedTab, itemWidth: itemWidth, animated: false)
            }
            .onChange(of: selectedTab) { oldValue, newValue in
                animateBlobToTab(newValue, from: oldValue, itemWidth: itemWidth)
            }
        }
        .frame(height: TabBarConfiguration.height)
    }
    
    // MARK: - Base Glass Layer
    /// The main glass surface using iOS 26 native Liquid Glass
    private var baseGlassLayer: some View {
        RoundedRectangle(cornerRadius: TabBarConfiguration.cornerRadius)
            .fill(.ultraThinMaterial)
            // iOS 26 Native Glass Effect
            .glassEffect(
                .regular,
                in: RoundedRectangle(cornerRadius: TabBarConfiguration.cornerRadius)
            )
            .overlay {
                // Subtle dark tint for depth
                RoundedRectangle(cornerRadius: TabBarConfiguration.cornerRadius)
                    .fill(Color.black.opacity(0.05))
            }
            .overlay {
                // Glass edge highlight
                RoundedRectangle(cornerRadius: TabBarConfiguration.cornerRadius)
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
            // Floating shadow
            .shadow(color: .black.opacity(0.2), radius: 25, x: 0, y: 12)
            // Glass effect ID for coordinated transitions
            .if(glassNamespace != nil) { view in
                view.glassEffectID(GlassEffectGroup.tabBar, in: glassNamespace!)
            }
    }
    
    // MARK: - Glow Overlay
    /// Animated glow effect during tab transitions
    private var glowOverlay: some View {
        RoundedRectangle(cornerRadius: TabBarConfiguration.cornerRadius)
            .fill(
                LinearGradient(
                    colors: [
                        selectedTab.accentColor.opacity(0.3 * glowIntensity),
                        selectedTab.accentColor.opacity(0.15 * glowIntensity),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .blur(radius: 10)
            .allowsHitTesting(false)
    }
    
    // MARK: - Blob Layer
    /// The floating active indicator blob with glass morphing
    private func blobLayer(itemWidth: CGFloat) -> some View {
        let blobWidth = TabBarConfiguration.blobWidth * stretchFactor
        let blobHeight = TabBarConfiguration.blobHeight / sqrt(stretchFactor)
        let blobCornerRadius = blobHeight * 0.45
        
        return ZStack {
            // Outer glow during animation
            if isAnimating || glowIntensity > 0 {
                RoundedRectangle(cornerRadius: blobCornerRadius)
                    .fill(selectedTab.accentColor.opacity(0.25 * glowIntensity))
                    .blur(radius: 15)
                    .frame(width: blobWidth * 1.3, height: blobHeight * 1.3)
                    .offset(x: blobOffset)
            }
            
            // Main blob with glass effect
            RoundedRectangle(cornerRadius: blobCornerRadius)
                .fill(.ultraThinMaterial)
                // iOS 26 Native Glass Effect on blob
                .glassEffect(
                    .regular,
                    in: RoundedRectangle(cornerRadius: blobCornerRadius)
                )
                .overlay {
                    // Accent tint
                    RoundedRectangle(cornerRadius: blobCornerRadius)
                        .fill(selectedTab.accentColor.opacity(0.15))
                }
                .overlay {
                    // Blob border highlight
                    RoundedRectangle(cornerRadius: blobCornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    selectedTab.accentColor.opacity(0.4),
                                    selectedTab.accentColor.opacity(0.2),
                                    .white.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.5
                        )
                }
                .frame(width: blobWidth, height: blobHeight)
                .scaleEffect(blobScale)
                .offset(x: blobOffset + dragOffset * 0.3) // Elastic drag response
                // Glass effect ID for blob transition coordination
                .if(glassNamespace != nil) { view in
                    view.glassEffectID(GlassEffectGroup.tabBlob, in: glassNamespace!)
                }
        }
    }
    
    // MARK: - Icon Layer
    /// Tab icons with animated transitions
    private func iconLayer(itemWidth: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                TabItemView(
                    tab: tab,
                    isSelected: tab == selectedTab,
                    onTap: {
                        // Haptic feedback
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        onTabSelected(tab)
                    }
                )
                .frame(width: itemWidth)
            }
        }
    }
    
    // MARK: - Drag Gesture
    /// Elastic drag response gesture
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($dragOffset) { value, state, _ in
                // Elastic resistance - harder to drag as you go further
                let resistance: CGFloat = 0.4
                state = value.translation.height * resistance
            }
            .onEnded { value in
                // Spring back animation
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    elasticOffset = 0
                }
            }
    }
    
    // MARK: - Animation Methods
    
    /// Calculate blob position for a tab
    private func calculateBlobPosition(for tab: MainTab, itemWidth: CGFloat, animated: Bool) {
        let index = tabs.firstIndex(of: tab) ?? 0
        let centerOffset = (CGFloat(tabs.count - 1) / 2)
        let targetOffset = (CGFloat(index) - centerOffset) * itemWidth
        
        if animated {
            blobOffset = targetOffset
        } else {
            blobOffset = targetOffset
        }
    }
    
    /// Animate blob to new tab with morphing effect
    private func animateBlobToTab(_ newTab: MainTab, from oldTab: MainTab, itemWidth: CGFloat) {
        let newIndex = tabs.firstIndex(of: newTab) ?? 0
        let oldIndex = tabs.firstIndex(of: oldTab) ?? 0
        let centerOffset = (CGFloat(tabs.count - 1) / 2)
        let targetOffset = (CGFloat(newIndex) - centerOffset) * itemWidth
        
        // Calculate stretch based on distance
        let distance = abs(newIndex - oldIndex)
        let stretchAmount = 1.0 + (CGFloat(distance) * 0.08)
        
        isAnimating = true
        
        // Phase 1: Start glow and begin stretch
        withAnimation(.easeOut(duration: 0.12)) {
            glowIntensity = 1.0
            stretchFactor = stretchAmount
            blobScale = 1.08
        }
        
        // Phase 2: Move blob with spring
        withAnimation(TabBarConfiguration.blobAnimation) {
            blobOffset = targetOffset
        }
        
        // Phase 3: Return to normal shape
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                stretchFactor = 1.0
                blobScale = 1.0
            }
            
            // Fade glow
            withAnimation(.easeOut(duration: 0.2)) {
                glowIntensity = 0
            }
        }
        
        // Reset animation flag
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isAnimating = false
        }
    }
}

// MARK: - Tab Item View
/// Individual tab item with icon and label
@available(iOS 26.0, *)
private struct TabItemView: View {
    let tab: MainTab
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var bounceScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            // Bounce animation on tap
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                bounceScale = 0.85
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                    bounceScale = 1.0
                }
            }
            
            onTap()
        }) {
            VStack(spacing: 3) {
                // Icon with symbol effect transition
                Image(systemName: isSelected ? tab.activeIcon : tab.icon)
                    .font(.system(size: TabBarConfiguration.iconSize, weight: .medium))
                    .foregroundColor(isSelected ? tab.accentColor : .white.opacity(0.5))
                    .contentTransition(.symbolEffect(.replace.downUp.byLayer))
                
                // Label
                Text(tab.title)
                    .font(.system(size: TabBarConfiguration.labelSize, weight: .medium))
                    .foregroundColor(isSelected ? tab.accentColor : .white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .frame(height: TabBarConfiguration.height)
            .contentShape(Rectangle())
            .scaleEffect(bounceScale)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Conditional Modifier Extension
@available(iOS 26.0, *)
private extension View {
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
}

// MARK: - Preview
@available(iOS 26.0, *)
#Preview("Glass Navigation Bar") {
    ZStack {
        // Background
        AnimatedBackground(style: .mystical)
        
        VStack {
            Spacer()
            
            GlassEffectNavigationBar(
                selectedTab: .constant(.home),
                tabs: MainTab.allCases,
                onTabSelected: { _ in }
            )
            .padding(.bottom, TabBarConfiguration.bottomPadding)
        }
    }
}

@available(iOS 26.0, *)
#Preview("Glass Navigation Bar Interactive") {
    struct InteractivePreview: View {
        @State private var selectedTab: MainTab = .home
        
        var body: some View {
            ZStack {
                AnimatedBackground(style: .mystical)
                
                VStack {
                    Text("Selected: \(selectedTab.title)")
                        .foregroundColor(.white)
                        .font(.title2)
                    
                    Spacer()
                    
                    GlassEffectNavigationBar(
                        selectedTab: $selectedTab,
                        tabs: MainTab.allCases,
                        onTabSelected: { tab in
                            selectedTab = tab
                        }
                    )
                    .padding(.bottom, TabBarConfiguration.bottomPadding)
                }
            }
        }
    }
    
    return InteractivePreview()
}
