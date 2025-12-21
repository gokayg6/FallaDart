// AppCoordinator.swift
// Falla - iOS 26 Fortune Telling App
// Navigation flow coordinator using MVVM + Coordinator pattern

import SwiftUI
import Combine

// MARK: - App Flow
/// Represents the main navigation flows in the app
enum AppFlow: Hashable {
    case splash
    case onboarding
    case authentication
    case main
}

// MARK: - Main Tab
/// Tab bar structure matching design: Ana Sayfa, Geçmiş, Testler, Sosyal, Profil
@available(iOS 26.0, *)
enum MainTab: Int, CaseIterable, Hashable, Identifiable {
    case home = 0       // Ana Sayfa
    case history = 1    // Geçmiş
    case tests = 2      // Testler
    case social = 3     // Sosyal
    case profile = 4    // Profil
    
    var id: Int { rawValue }
    
    var title: String {
        switch self {
        case .home: return "Ana Sayfa"
        case .history: return "Geçmiş"
        case .tests: return "Testler"
        case .social: return "Sosyal"
        case .profile: return "Profil"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house"
        case .history: return "clock"
        case .tests: return "square.grid.2x2"
        case .social: return "bubble.left.and.bubble.right"
        case .profile: return "person.circle"
        }
    }
    
    var activeIcon: String {
        switch self {
        case .home: return "house.fill"
        case .history: return "clock.fill"
        case .tests: return "square.grid.2x2.fill"
        case .social: return "bubble.left.and.bubble.right.fill"
        case .profile: return "person.circle.fill"
        }
    }
    
    /// Accent color for each tab's active state
    var accentColor: Color {
        switch self {
        case .home: return FallaColors.champagneGold
        case .history: return FallaColors.tarotPurple
        case .tests: return FallaColors.physicalBlue
        case .social: return FallaColors.emotionalRed
        case .profile: return FallaColors.champagneGold
        }
    }
}

// MARK: - App Coordinator
/// Main coordinator managing app-wide navigation state
@available(iOS 26.0, *)
@MainActor
final class AppCoordinator: ObservableObject {
    // MARK: - Published Properties
    @Published var currentFlow: AppFlow = .splash
    @Published var selectedTab: MainTab = .home
    @Published var previousTab: MainTab = .home
    @Published var navigationPath = NavigationPath()
    
    // MARK: - Glass Namespace
    /// Shared namespace for coordinated glass transitions
    @Published var tabTransitionDirection: TabTransitionDirection = .none
    
    enum TabTransitionDirection {
        case none
        case left
        case right
    }
    
    // MARK: - Sheet Presentation
    @Published var presentedSheet: SheetDestination?
    @Published var presentedFullScreen: FullScreenDestination?
    
    // MARK: - Alert State
    @Published var alertState: AlertState?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupAuthStateObserver()
    }
    
    // MARK: - Navigation Methods
    
    /// Navigate to a specific flow with glass transition
    func navigate(to flow: AppFlow) {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            currentFlow = flow
        }
    }
    
    /// Handle splash completion
    func splashCompleted(isAuthenticated: Bool, hasSeenOnboarding: Bool) {
        if isAuthenticated {
            navigate(to: .main)
        } else if !hasSeenOnboarding {
            navigate(to: .onboarding)
        } else {
            navigate(to: .authentication)
        }
    }
    
    /// Handle successful login
    func handleLoginSuccess() {
        navigate(to: .main)
    }
    
    /// Handle logout
    func handleLogout() {
        selectedTab = .home
        navigationPath = NavigationPath()
        navigate(to: .authentication)
    }
    
    /// Switch to specific tab with direction tracking for animations
    func switchTab(to tab: MainTab) {
        guard tab != selectedTab else { return }
        
        // Determine transition direction
        tabTransitionDirection = tab.rawValue > selectedTab.rawValue ? .right : .left
        previousTab = selectedTab
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        // Animate tab change
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedTab = tab
        }
        
        // Reset direction after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.tabTransitionDirection = .none
        }
    }
    
    // MARK: - Sheet Presentation
    
    func presentSheet(_ destination: SheetDestination) {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        presentedSheet = destination
    }
    
    func dismissSheet() {
        presentedSheet = nil
    }
    
    func presentFullScreen(_ destination: FullScreenDestination) {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
        presentedFullScreen = destination
    }
    
    func dismissFullScreen() {
        presentedFullScreen = nil
    }
    
    // MARK: - Alert Presentation
    
    func showAlert(_ state: AlertState) {
        alertState = state
    }
    
    func dismissAlert() {
        alertState = nil
    }
    
    // MARK: - Private Methods
    
    private func setupAuthStateObserver() {
        // Observe auth state changes from AuthManager
        AuthManager.shared.$isAuthenticated
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthenticated in
                guard let self = self else { return }
                if !isAuthenticated && self.currentFlow == .main {
                    self.handleLogout()
                }
            }
            .store(in: &cancellables)
    }
}

// MARK: - Sheet Destinations
@available(iOS 26.0, *)
enum SheetDestination: Identifiable {
    case fortuneSelection
    case premiumUpgrade
    case settings
    case editProfile
    case karmaStore
    case spinWheel
    case fortuneDetail(fortuneId: String)
    case chatDetail(matchId: String)
    case biorhythm
    case dailyFortune
    
    var id: String {
        switch self {
        case .fortuneSelection: return "fortuneSelection"
        case .premiumUpgrade: return "premiumUpgrade"
        case .settings: return "settings"
        case .editProfile: return "editProfile"
        case .karmaStore: return "karmaStore"
        case .spinWheel: return "spinWheel"
        case .fortuneDetail(let id): return "fortuneDetail-\(id)"
        case .chatDetail(let id): return "chatDetail-\(id)"
        case .biorhythm: return "biorhythm"
        case .dailyFortune: return "dailyFortune"
        }
    }
}

// MARK: - Full Screen Destinations
@available(iOS 26.0, *)
enum FullScreenDestination: Identifiable {
    case coffeeFortune
    case tarotFortune
    case palmFortune
    case katinaFortune
    case faceFortune
    case astrologyFortune
    case dreamInterpretation
    case soulmateAnalysis
    case loveCompatibility
    case generalTest(testType: String)
    case fortuneResult(fortuneId: String)
    
    var id: String {
        switch self {
        case .coffeeFortune: return "coffeeFortune"
        case .tarotFortune: return "tarotFortune"
        case .palmFortune: return "palmFortune"
        case .katinaFortune: return "katinaFortune"
        case .faceFortune: return "faceFortune"
        case .astrologyFortune: return "astrologyFortune"
        case .dreamInterpretation: return "dreamInterpretation"
        case .soulmateAnalysis: return "soulmateAnalysis"
        case .loveCompatibility: return "loveCompatibility"
        case .generalTest(let type): return "generalTest-\(type)"
        case .fortuneResult(let id): return "fortuneResult-\(id)"
        }
    }
}

// MARK: - Alert State
struct AlertState: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let primaryButton: AlertButton
    var secondaryButton: AlertButton?
    
    struct AlertButton {
        let title: String
        let role: ButtonRole?
        let action: () -> Void
        
        init(title: String, role: ButtonRole? = nil, action: @escaping () -> Void = {}) {
            self.title = title
            self.role = role
            self.action = action
        }
    }
}

// MARK: - Tab Bar Configuration
/// Configuration for the floating glass navigation bar
@available(iOS 26.0, *)
struct TabBarConfiguration {
    static let height: CGFloat = 60
    static let horizontalPadding: CGFloat = 24
    static let bottomPadding: CGFloat = 28
    static let cornerRadius: CGFloat = 30
    static let blobWidth: CGFloat = 72
    static let blobHeight: CGFloat = 46
    static let iconSize: CGFloat = 24
    static let labelSize: CGFloat = 10
    
    /// Spring animation for tab switches
    static var tabSwitchAnimation: Animation {
        .spring(response: 0.4, dampingFraction: 0.75)
    }
    
    /// Spring animation for blob movement
    static var blobAnimation: Animation {
        .spring(response: 0.45, dampingFraction: 0.7)
    }
}
