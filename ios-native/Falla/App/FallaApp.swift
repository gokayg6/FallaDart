// FallaApp.swift
// Falla - iOS 26 Fortune Telling App
// Main application entry point with Liquid Glass container

import SwiftUI
import FirebaseCore

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Initialize Firebase
        FirebaseApp.configure()
        
        // Enable high refresh rate
        configureHighRefreshRate()
        
        return true
    }
    
    private func configureHighRefreshRate() {
        // Enable ProMotion 120Hz display for smooth animations
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            for window in scene.windows {
                // Request maximum frame rate for smooth glass animations
                window.windowScene?.sizeRestrictions?.minimumSize = CGSize(width: 320, height: 480)
            }
        }
    }
}

// MARK: - Main App
@available(iOS 26.0, *)
@main
struct FallaApp: App {
    // MARK: - App Delegate
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // MARK: - State Objects
    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var userManager = UserManager()
    @StateObject private var fortuneManager = FortuneManager()
    @StateObject private var purchaseManager = PurchaseManager()
    
    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            // iOS 26 Glass Effect Container - enables Liquid Glass for entire app
            GlassEffectContainer {
                RootView()
            }
            .environmentObject(coordinator)
            .environmentObject(AuthManager.shared)
            .environmentObject(userManager)
            .environmentObject(fortuneManager)
            .environmentObject(purchaseManager)
            .preferredColorScheme(.dark)
            .tint(FallaColors.champagneGold)
        }
    }
}

// MARK: - Root View
/// Handles the main navigation flow between app states
@available(iOS 26.0, *)
struct RootView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var authManager: AuthManager
    
    var body: some View {
        ZStack {
            // Main content based on current flow
            switch coordinator.currentFlow {
            case .splash:
                SplashView()
                    .transition(.opacity)
                
            case .onboarding:
                OnboardingView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                
            case .authentication:
                AuthenticationFlowView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
                
            case .main:
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .scale(scale: 1.05).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: coordinator.currentFlow)
    }
}

// MARK: - Splash View
/// Initial splash screen with animated logo
@available(iOS 26.0, *)
struct SplashView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var authManager: AuthManager
    
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var ringRotation: Double = 0
    @State private var glowIntensity: Double = 0
    
    var body: some View {
        ZStack {
            // Animated background
            AnimatedBackground(style: .mystical, enableParticles: true)
            
            VStack(spacing: 24) {
                Spacer()
                
                // Animated logo
                logoView
                
                // App name with fade in
                VStack(spacing: 8) {
                    Text("Falla")
                        .font(.system(size: 48, weight: .light, design: .serif))
                        .foregroundColor(.white)
                    
                    Text("Geleceğinizi keşfedin")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .opacity(textOpacity)
                
                Spacer()
                
                // Loading indicator
                ProgressView()
                    .tint(FallaColors.champagneGold)
                    .scaleEffect(1.2)
                    .opacity(textOpacity)
                
                Spacer()
                    .frame(height: 80)
            }
        }
        .onAppear {
            startAnimations()
            checkAuthAndNavigate()
        }
    }
    
    private var logoView: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            FallaColors.champagneGold.opacity(0.4 * glowIntensity),
                            FallaColors.champagneGold.opacity(0.15 * glowIntensity),
                            .clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 120
                    )
                )
                .frame(width: 220, height: 220)
            
            // Rotating ring
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            FallaColors.champagneGold.opacity(0.8),
                            FallaColors.champagneGold.opacity(0.2),
                            .clear,
                            FallaColors.champagneGold.opacity(0.2),
                            FallaColors.champagneGold.opacity(0.8)
                        ],
                        center: .center
                    ),
                    lineWidth: 2
                )
                .frame(width: 150, height: 150)
                .rotationEffect(.degrees(ringRotation))
            
            // Glass circle
            Circle()
                .fill(.ultraThinMaterial)
                .glassEffect(.regular, in: Circle())
                .overlay {
                    Circle()
                        .fill(FallaColors.champagneGold.opacity(0.1))
                }
                .overlay {
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    FallaColors.champagneGold.opacity(0.5),
                                    FallaColors.champagneGold.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
                .frame(width: 120, height: 120)
            
            // Logo icon
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 50))
                .foregroundColor(FallaColors.champagneGold)
                .shadow(color: FallaColors.champagneGold.opacity(0.5), radius: 10, x: 0, y: 0)
        }
        .scaleEffect(logoScale)
        .opacity(logoOpacity)
    }
    
    private func startAnimations() {
        // Logo fade in and scale
        withAnimation(.easeOut(duration: 0.8)) {
            logoOpacity = 1
            logoScale = 1.0
        }
        
        // Glow pulse
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            glowIntensity = 1
        }
        
        // Ring rotation
        withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
            ringRotation = 360
        }
        
        // Text fade in
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.6)) {
                textOpacity = 1
            }
        }
    }
    
    private func checkAuthAndNavigate() {
        // Delay for splash animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Check if user has seen onboarding
            let hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
            
            // Check authentication state
            let isAuthenticated = authManager.isAuthenticated
            
            coordinator.splashCompleted(
                isAuthenticated: isAuthenticated,
                hasSeenOnboarding: hasSeenOnboarding
            )
        }
    }
}

// MARK: - Onboarding View
/// Welcome onboarding screens for new users
@available(iOS 26.0, *)
struct OnboardingView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    
    @State private var currentPage = 0
    
    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "sparkles",
            title: "Hoş Geldiniz",
            description: "Falla ile geleceğinizi keşfedin, mistik dünyanın kapılarını aralayın.",
            accentColor: FallaColors.champagneGold
        ),
        OnboardingPage(
            icon: "cup.and.saucer.fill",
            title: "Fal Türleri",
            description: "Kahve falı, tarot, el falı ve daha fazlası. Hangi yöntemle başlamak istersiniz?",
            accentColor: FallaColors.coffeeOrange
        ),
        OnboardingPage(
            icon: "heart.circle.fill",
            title: "Kişisel Deneyim",
            description: "Size özel yorumlar, kişiselleştirilmiş içerikler ve günlük burç yorumları.",
            accentColor: FallaColors.emotionalRed
        ),
        OnboardingPage(
            icon: "star.fill",
            title: "Hazır mısınız?",
            description: "Geleceğe doğru ilk adımı atmanın zamanı geldi.",
            accentColor: FallaColors.astrologyYellow
        )
    ]
    
    var body: some View {
        ZStack {
            AnimatedBackground(style: .mystical)
            
            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        pageView(for: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Bottom section
                VStack(spacing: 24) {
                    // Page indicator
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage 
                                      ? FallaColors.champagneGold 
                                      : Color.white.opacity(0.3))
                                .frame(width: index == currentPage ? 10 : 8, 
                                       height: index == currentPage ? 10 : 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        }
                    }
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        if currentPage > 0 {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    currentPage -= 1
                                }
                            } label: {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(width: 50, height: 50)
                                    .background {
                                        Circle()
                                            .fill(.ultraThinMaterial)
                                            .glassEffect(.thin, in: Circle())
                                    }
                            }
                            .buttonStyle(ElasticButtonStyle())
                        }
                        
                        Button {
                            if currentPage < pages.count - 1 {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    currentPage += 1
                                }
                            } else {
                                completeOnboarding()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Text(currentPage < pages.count - 1 ? "Devam" : "Başla")
                                Image(systemName: "arrow.right")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(FallaColors.champagneGold)
                            }
                            .shadow(color: FallaColors.champagneGold.opacity(0.4), radius: 12, x: 0, y: 6)
                        }
                        .buttonStyle(ElasticButtonStyle())
                    }
                    .padding(.horizontal, 24)
                    
                    // Skip button
                    if currentPage < pages.count - 1 {
                        Button {
                            completeOnboarding()
                        } label: {
                            Text("Atla")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                .padding(.bottom, 50)
            }
        }
    }
    
    private func pageView(for page: OnboardingPage) -> some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon with glass effect
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                page.accentColor.opacity(0.3),
                                page.accentColor.opacity(0.1),
                                .clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 100
                        )
                    )
                    .frame(width: 180, height: 180)
                
                Circle()
                    .fill(.ultraThinMaterial)
                    .glassEffect(.regular, in: Circle())
                    .overlay {
                        Circle()
                            .fill(page.accentColor.opacity(0.15))
                    }
                    .frame(width: 120, height: 120)
                
                Image(systemName: page.icon)
                    .font(.system(size: 50))
                    .foregroundColor(page.accentColor)
            }
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundColor(.white)
                
                Text(page.description)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            Spacer()
        }
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        coordinator.navigate(to: .authentication)
    }
}

// MARK: - Onboarding Page Model
struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let accentColor: Color
}

// MARK: - Preview
@available(iOS 26.0, *)
#Preview("Splash Screen") {
    SplashView()
        .environmentObject(AppCoordinator())
        .environmentObject(AuthManager.shared)
}

@available(iOS 26.0, *)
#Preview("Onboarding") {
    OnboardingView()
        .environmentObject(AppCoordinator())
}
