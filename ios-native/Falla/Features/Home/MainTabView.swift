// MainTabView.swift
// Falla - iOS 26 Fortune Telling App
// Main tab container with Liquid Glass navigation bar and animated backgrounds

import SwiftUI

// MARK: - Main Tab View
/// Root view for the main app experience with floating glass navigation
@available(iOS 26.0, *)
struct MainTabView: View {
    // MARK: - Environment
    @EnvironmentObject private var coordinator: AppCoordinator
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var userManager: UserManager
    
    // MARK: - Namespace for transitions
    @Namespace private var tabNamespace
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Animated Background - persistent across tab switches
            AnimatedBackground(style: .mystical)
            
            // Tab Content with matched geometry transitions
            tabContent
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            
            // Floating Glass Navigation Bar
            VStack {
                Spacer()
                
                GlassEffectNavigationBar(
                    selectedTab: $coordinator.selectedTab,
                    tabs: MainTab.allCases,
                    onTabSelected: { tab in
                        coordinator.switchTab(to: tab)
                    }
                )
                .padding(.bottom, TabBarConfiguration.bottomPadding)
            }
        }
        .environment(\.glassNamespace, tabNamespace)
        .sheet(item: $coordinator.presentedSheet) { destination in
            sheetContent(for: destination)
                .environment(\.glassNamespace, tabNamespace)
        }
        .fullScreenCover(item: $coordinator.presentedFullScreen) { destination in
            fullScreenContent(for: destination)
                .environment(\.glassNamespace, tabNamespace)
        }
        .alert(item: $coordinator.alertState) { alertState in
            Alert(
                title: Text(alertState.title),
                message: Text(alertState.message),
                primaryButton: .default(
                    Text(alertState.primaryButton.title),
                    action: alertState.primaryButton.action
                ),
                secondaryButton: alertState.secondaryButton.map { button in
                    .cancel(Text(button.title), action: button.action)
                } ?? .cancel()
            )
        }
    }
    
    // MARK: - Tab Content
    @ViewBuilder
    private var tabContent: some View {
        switch coordinator.selectedTab {
        case .home:
            HomeView()
                .id(MainTab.home)
            
        case .history:
            HistoryView()
                .id(MainTab.history)
            
        case .tests:
            TestsView()
                .id(MainTab.tests)
            
        case .social:
            SocialView()
                .id(MainTab.social)
            
        case .profile:
            ProfileView()
                .id(MainTab.profile)
        }
    }
    
    // MARK: - Sheet Content
    @ViewBuilder
    private func sheetContent(for destination: SheetDestination) -> some View {
        NavigationStack {
            Group {
                switch destination {
                case .fortuneSelection:
                    FortuneSelectionView()
                case .premiumUpgrade:
                    PremiumView()
                case .settings:
                    SettingsView()
                case .editProfile:
                    EditProfileView()
                case .karmaStore:
                    KarmaStoreView()
                case .spinWheel:
                    SpinWheelView()
                case .fortuneDetail(let fortuneId):
                    FortuneDetailView(fortuneId: fortuneId)
                case .chatDetail(let matchId):
                    ChatDetailView(matchId: matchId)
                case .biorhythm:
                    BiorhythmView()
                case .dailyFortune:
                    DailyFortuneView()
                }
            }
            .background {
                AnimatedBackground(style: .mystical, enableParticles: false)
            }
        }
        .presentationBackground(.clear)
        .presentationDragIndicator(.visible)
    }
    
    // MARK: - Full Screen Content
    @ViewBuilder
    private func fullScreenContent(for destination: FullScreenDestination) -> some View {
        Group {
            switch destination {
            case .coffeeFortune:
                CoffeeFortuneView()
            case .tarotFortune:
                TarotFortuneView()
            case .palmFortune:
                PalmFortuneView()
            case .katinaFortune:
                KatinaFortuneView()
            case .faceFortune:
                FaceFortuneView()
            case .astrologyFortune:
                AstrologyFortuneView()
            case .dreamInterpretation:
                DreamFortuneView()
            case .soulmateAnalysis:
                SoulmateAnalysisView()
            case .loveCompatibility:
                LoveCompatibilityView()
            case .generalTest(let testType):
                GeneralTestView(testType: testType)
            case .fortuneResult(let fortuneId):
                FortuneResultView(fortuneId: fortuneId)
            }
        }
        .background {
            AnimatedBackground(style: .mystical)
        }
    }
}

// MARK: - User Manager
/// Observable object for user state management
@available(iOS 26.0, *)
@MainActor
final class UserManager: ObservableObject {
    @Published var currentUser: UserModel?
    @Published var karma: Int = 0
    @Published var isPremium: Bool = false
    
    func refreshUser() async {
        guard let userId = AuthManager.shared.currentUser?.uid else { return }
        
        do {
            if let user = try await FirebaseService.shared.getUserProfile(userId) {
                currentUser = user
                karma = user.karma
                isPremium = user.isPremium
            }
        } catch {
            print("❌ Failed to refresh user: \(error)")
        }
    }
    
    func updateKarma(_ amount: Int) async {
        guard let userId = AuthManager.shared.currentUser?.uid else { return }
        
        do {
            try await FirebaseService.shared.updateKarma(userId, amount: amount, reason: "manual_update")
            karma += amount
        } catch {
            print("❌ Failed to update karma: \(error)")
        }
    }
}

// MARK: - Fortune Manager
/// Observable object for fortune state management
@available(iOS 26.0, *)
@MainActor
final class FortuneManager: ObservableObject {
    @Published var fortunes: [FortuneModel] = []
    @Published var isLoading = false
    
    func loadFortunes() async {
        guard let userId = AuthManager.shared.currentUser?.uid else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            fortunes = try await FirebaseService.shared.getUserFortunes(userId)
        } catch {
            print("❌ Failed to load fortunes: \(error)")
        }
    }
    
    func saveFortune(_ fortune: FortuneModel) async -> String? {
        guard let userId = AuthManager.shared.currentUser?.uid else { return nil }
        
        do {
            let fortuneId = try await FirebaseService.shared.saveFortune(userId, fortuneData: fortune.toFirestore())
            await loadFortunes()
            return fortuneId
        } catch {
            print("❌ Failed to save fortune: \(error)")
            return nil
        }
    }
}

// MARK: - Purchase Manager
/// Observable object for in-app purchase management
@available(iOS 26.0, *)
@MainActor
final class PurchaseManager: ObservableObject {
    @Published var products: [String: String] = [:] // productId: price
    @Published var isPurchasing = false
    
    func loadProducts() async {
        // StoreKit 2 implementation
    }
    
    func purchase(productId: String) async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }
        
        // TODO: Implement StoreKit 2 purchase
        return false
    }
    
    func restorePurchases() async {
        // TODO: Implement restore
    }
}

// MARK: - Placeholder Views
// These are placeholder implementations - full versions in separate files

@available(iOS 26.0, *)
struct TestsView: View {
    @EnvironmentObject private var coordinator: AppCoordinator
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                headerView
                
                // Tests Grid
                testsGrid
                
                Spacer().frame(height: 120)
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
    }
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Testler")
                .font(.system(size: 28, weight: .light, design: .serif))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 60)
    }
    
    private var testsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            GlassGridItem(
                icon: "heart.circle",
                title: "Ruh Eşi Analizi",
                subtitle: "Kim seninle uyumlu?",
                accentColor: FallaColors.emotionalRed,
                karmaCost: 5
            ) {
                coordinator.presentFullScreen(.soulmateAnalysis)
            }
            
            GlassGridItem(
                icon: "heart.text.square",
                title: "Aşk Uyumu",
                subtitle: "İlişki analizi",
                accentColor: FallaColors.palmPink,
                karmaCost: 5
            ) {
                coordinator.presentFullScreen(.loveCompatibility)
            }
        }
    }
}

@available(iOS 26.0, *)
struct SocialView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sosyal")
                        .font(.system(size: 28, weight: .light, design: .serif))
                        .foregroundColor(.white)
                    
                    Text("Eşleşmeler ve sohbetler")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 60)
                
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.3))
                    
                    Text("Henüz eşleşme yok")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                
                Spacer().frame(height: 120)
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
    }
}

@available(iOS 26.0, *)
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Ayarlar")
                    .font(.system(size: 28, weight: .light, design: .serif))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)
                
                // Settings sections would go here
                GlassCard {
                    VStack(spacing: 0) {
                        settingsRow(icon: "bell", title: "Bildirimler")
                        Divider().background(.white.opacity(0.1))
                        settingsRow(icon: "globe", title: "Dil")
                        Divider().background(.white.opacity(0.1))
                        settingsRow(icon: "paintbrush", title: "Tema")
                    }
                }
                
                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Kapat") { dismiss() }
                    .foregroundColor(FallaColors.champagneGold)
            }
        }
    }
    
    private func settingsRow(icon: String, title: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(FallaColors.champagneGold)
                .frame(width: 24)
            
            Text(title)
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(.vertical, 14)
    }
}

// Fortune view placeholders
@available(iOS 26.0, *)
struct FortuneSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Text("Fal Seçimi")
            .foregroundColor(.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Kapat") { dismiss() }
                }
            }
    }
}

@available(iOS 26.0, *)
struct PremiumView: View {
    var body: some View {
        Text("Premium").foregroundColor(.white)
    }
}

@available(iOS 26.0, *)
struct EditProfileView: View {
    var body: some View {
        Text("Profil Düzenle").foregroundColor(.white)
    }
}

@available(iOS 26.0, *)
struct KarmaStoreView: View {
    var body: some View {
        Text("Karma Mağazası").foregroundColor(.white)
    }
}

@available(iOS 26.0, *)
struct SpinWheelView: View {
    var body: some View {
        Text("Şans Çarkı").foregroundColor(.white)
    }
}

@available(iOS 26.0, *)
struct FortuneDetailView: View {
    let fortuneId: String
    var body: some View {
        Text("Fal Detayı: \(fortuneId)").foregroundColor(.white)
    }
}

@available(iOS 26.0, *)
struct ChatDetailView: View {
    let matchId: String
    var body: some View {
        Text("Sohbet: \(matchId)").foregroundColor(.white)
    }
}

@available(iOS 26.0, *)
struct DailyFortuneView: View {
    var body: some View {
        Text("Günlük Burç Yorumu").foregroundColor(.white)
    }
}

@available(iOS 26.0, *)
struct CoffeeFortuneView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button("Kapat") { dismiss() }
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()
                Spacer()
                Text("Kahve Falı").font(.title).foregroundColor(.white)
                Spacer()
            }
        }
    }
}

@available(iOS 26.0, *)
struct TarotFortuneView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Button("Kapat") { dismiss() }.foregroundColor(.white)
                    Spacer()
                }
                .padding()
                Spacer()
                Text("Tarot Falı").font(.title).foregroundColor(.white)
                Spacer()
            }
        }
    }
}

@available(iOS 26.0, *)
struct PalmFortuneView: View {
    var body: some View {
        Text("El Falı").foregroundColor(.white)
    }
}

@available(iOS 26.0, *)
struct KatinaFortuneView: View {
    var body: some View {
        Text("Katina Falı").foregroundColor(.white)
    }
}

@available(iOS 26.0, *)
struct FaceFortuneView: View {
    var body: some View {
        Text("Yüz Falı").foregroundColor(.white)
    }
}

@available(iOS 26.0, *)
struct AstrologyFortuneView: View {
    var body: some View {
        Text("Astroloji").foregroundColor(.white)
    }
}

@available(iOS 26.0, *)
struct DreamFortuneView: View {
    var body: some View {
        Text("Rüya Yorumu").foregroundColor(.white)
    }
}

@available(iOS 26.0, *)
struct SoulmateAnalysisView: View {
    var body: some View {
        Text("Ruh Eşi Analizi").foregroundColor(.white)
    }
}

@available(iOS 26.0, *)
struct LoveCompatibilityView: View {
    var body: some View {
        Text("Aşk Uyumu").foregroundColor(.white)
    }
}

@available(iOS 26.0, *)
struct GeneralTestView: View {
    let testType: String
    var body: some View {
        Text("Test: \(testType)").foregroundColor(.white)
    }
}

@available(iOS 26.0, *)
struct FortuneResultView: View {
    let fortuneId: String
    var body: some View {
        Text("Sonuç: \(fortuneId)").foregroundColor(.white)
    }
}

// MARK: - Preview
@available(iOS 26.0, *)
#Preview("Main Tab View") {
    MainTabView()
        .environmentObject(AppCoordinator())
        .environmentObject(AuthManager.shared)
        .environmentObject(UserManager())
        .environmentObject(FortuneManager())
        .environmentObject(PurchaseManager())
}
