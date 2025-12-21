// SplashView.swift
// Falla - iOS 26 Fortune Telling App
// Animated splash screen with Liquid Glass effects

import SwiftUI

// MARK: - Splash View
struct SplashView: View {
    // MARK: - Environment
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var authManager: AuthManager
    
    // MARK: - State
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var isLoading = true
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
            
            // Animated background particles
            particleOverlay
            
            // Content
            VStack(spacing: 40) {
                Spacer()
                
                // Logo with glow
                logoView
                
                // App title
                titleView
                
                Spacer()
                
                // Loading indicator
                if isLoading {
                    loadingIndicator
                }
                
                Spacer()
                    .frame(height: 100)
            }
        }
        .onAppear {
            startAnimations()
            checkAuthState()
        }
    }
    
    // MARK: - Background Gradient
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.08, green: 0.04, blue: 0.12),
                Color(red: 0.12, green: 0.06, blue: 0.18),
                Color(red: 0.06, green: 0.02, blue: 0.10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Particle Overlay
    private var particleOverlay: some View {
        GeometryReader { geometry in
            ForEach(0..<20, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.white.opacity(0.1),
                                Color.white.opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: CGFloat.random(in: 2...6))
                    .position(
                        x: CGFloat.random(in: 0...geometry.size.width),
                        y: CGFloat.random(in: 0...geometry.size.height)
                    )
                    .opacity(glowOpacity * 0.5)
                    .blur(radius: 1)
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Logo View
    private var logoView: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.4),
                            Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0)
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 120
                    )
                )
                .frame(width: 240, height: 240)
                .opacity(glowOpacity)
            
            // Logo container with glass effect
            GlassCard(cornerRadius: 40, padding: 0) {
                ZStack {
                    // Background gradient
                    LinearGradient(
                        colors: [
                            Color(red: 0.82, green: 0.71, blue: 0.55).opacity(0.3),
                            Color(red: 0.6, green: 0.4, blue: 0.3).opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // Crystal ball icon
                    Image(systemName: "sparkles")
                        .font(.system(size: 60, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    .white,
                                    Color(red: 0.82, green: 0.71, blue: 0.55)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            }
            .frame(width: 120, height: 120)
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
        }
    }
    
    // MARK: - Title View
    private var titleView: some View {
        VStack(spacing: 8) {
            Text("Falla")
                .font(.system(size: 48, weight: .light, design: .serif))
                .foregroundColor(.white)
            
            Text("Geleceğini Keşfet")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .tracking(4)
        }
        .opacity(titleOpacity)
    }
    
    // MARK: - Loading Indicator
    private var loadingIndicator: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.82, green: 0.71, blue: 0.55)))
                .scaleEffect(1.2)
            
            Text("Yükleniyor...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .opacity(titleOpacity)
    }
    
    // MARK: - Animations
    private func startAnimations() {
        // Logo appear
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Glow appear
        withAnimation(.easeOut(duration: 1.5).delay(0.4)) {
            glowOpacity = 1.0
        }
        
        // Title appear
        withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
            titleOpacity = 1.0
        }
    }
    
    // MARK: - Auth Check
    private func checkAuthState() {
        // Simulate minimum splash display time
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            await MainActor.run {
                isLoading = false
                
                // Check if user has seen onboarding
                let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
                
                // Navigate based on auth state
                coordinator.splashCompleted(
                    isAuthenticated: authManager.isAuthenticated,
                    hasSeenOnboarding: hasSeenOnboarding
                )
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SplashView()
        .environmentObject(AppCoordinator())
        .environmentObject(AuthManager.shared)
}
